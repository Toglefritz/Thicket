import 'dart:io';

import 'package:thicket/thicket.dart';

import '../mcp_tool.dart';
import 'embedding_service.dart';
import 'project_resolver.dart';

/// Creates the `search` tool which finds world model entities across all collections by matching against their summary
/// fields.
///
/// This tool combines results from two search strategies:
/// 1. Text search: case-insensitive token matching against entity summaries.
/// 2. Embedding search: semantic similarity using Gemini embedding vectors and cosine distance.
///
/// Results from both strategies are merged, deduplicated, and ranked by a combined score. If the embedding API is
/// unavailable (no API key configured or request failure), the tool falls back to text-only results.
///
/// Results are returned as lightweight references containing the collection name, entity ID, summary, and a relevance
/// score. The agent can then use the `recall` tool with a specific collection and ID to retrieve full entity details.
///
/// Required arguments:
/// - `projectPath`: absolute path to the project root
/// - `query`: natural-language search query
///
/// Optional arguments:
/// - `maxResults`: maximum number of results to return (defaults to 10)
McpTool searchTool() {
  return McpTool(
    name: 'search',
    description:
        'Searches the project world model for entities relevant to the given query. '
        'Uses both text matching and semantic similarity (embeddings) to find results across all collections. '
        'Returns lightweight references (collection, id, summary, score) rather than full entities. '
        'Use the recall tool with a specific collection and id to retrieve full details of a result.',
    inputSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, Map<String, String>>{
        'projectPath': <String, String>{
          'type': 'string',
          'description': 'Absolute path to the root directory of the project.',
        },
        'query': <String, String>{
          'type': 'string',
          'description':
              'Natural-language search query to match against entity summaries.',
        },
        'maxResults': <String, String>{
          'type': 'integer',
          'description': 'Maximum number of results to return. Defaults to 10.',
        },
      },
      'required': <String>['projectPath', 'query'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String projectPath = arguments['projectPath'] as String;
      final String query = arguments['query'] as String;
      final int maxResults = (arguments['maxResults'] as int?) ?? 10;

      if (query.trim().isEmpty) {
        throw ArgumentError('The "query" argument must not be empty.');
      }

      final ProjectIdentity identity = ProjectResolver.readIdentity(
        projectPath,
      );

      // Collect all entities across all collections.
      final List<_SearchCandidate> candidates = await _loadAllEntities(
        identity,
        projectPath,
      );

      if (candidates.isEmpty) {
        return <String, dynamic>{
          'count': 0,
          'results': <Map<String, dynamic>>[],
        };
      }

      // Phase 1: text-based search.
      final List<_ScoredResult> textResults = _textSearch(
        candidates: candidates,
        query: query,
      );

      // Phase 2: embedding-based search.
      final List<_ScoredResult> embeddingResults = await _embeddingSearch(
        candidates: candidates,
        query: query,
      );

      // Merge results from both strategies.
      final List<_ScoredResult> merged = _mergeResults(
        textResults: textResults,
        embeddingResults: embeddingResults,
      );

      // Sort by combined score descending, take top N.
      merged.sort(
        (_ScoredResult a, _ScoredResult b) => b.score.compareTo(a.score),
      );

      final List<_ScoredResult> topResults = merged.length > maxResults
          ? merged.sublist(0, maxResults)
          : merged;

      return <String, dynamic>{
        'count': topResults.length,
        'results': topResults
            .map(
              (_ScoredResult r) => <String, dynamic>{
                'collection': r.collection,
                'id': r.id,
                'summary': r.summary,
                'score': r.score,
              },
            )
            .toList(),
      };
    },
  );
}

/// The standard knowledge collections that the search tool iterates over.
///
/// These match the categories recommended in the `remember` tool description. Using a fixed set avoids the need for
/// `listCollectionIds` permissions, which are not available with standard user credentials.
const List<String> _knownCollections = <String>[
  'architecture',
  'conventions',
  'decisions',
  'gotchas',
  'dependencies',
  'workflows',
  '_meta',
];

/// Loads all entities from every collection in the project's world model.
///
/// For cloud storage, iterates over [_knownCollections] and loads entities from each. Collections that don't exist yet
/// simply return empty results. For local storage, lists subdirectories of the storage root.
Future<List<_SearchCandidate>> _loadAllEntities(
  ProjectIdentity identity,
  String projectPath,
) async {
  final List<_SearchCandidate> candidates = <_SearchCandidate>[];

  if (identity.storageMode == StorageMode.cloud) {
    final FirestoreEntityStore store = ProjectResolver.createFirestoreStore(
      identity,
    );

    for (final String collection in _knownCollections) {
      try {
        final List<Map<String, dynamic>> entities = await store.listAll(
          collection: collection,
        );
        for (final Map<String, dynamic> json in entities) {
          final WorldModelEntity entity = WorldModelEntity.fromJson(json);
          final String summary = (entity.data['summary'] as String?) ?? '';
          if (summary.isNotEmpty) {
            candidates.add(
              _SearchCandidate(
                collection: collection,
                id: entity.id,
                summary: summary,
              ),
            );
          }
        }
      } catch (_) {
        // Collection may not exist yet — skip it silently.
      }
    }
  } else {
    final String? storagePath = ProjectResolver.resolveLocalStoragePath(
      identity,
      projectPath,
    );
    if (storagePath == null) {
      throw StateError('Could not resolve local storage path for project.');
    }

    final Directory storageRoot = Directory(storagePath);
    if (!storageRoot.existsSync()) {
      return candidates;
    }

    final EntityStore store = EntityStore(storagePath: storagePath);

    // Each subdirectory of the storage root is a collection.
    final List<Directory> collectionDirs = storageRoot
        .listSync()
        .whereType<Directory>()
        .toList();

    for (final Directory dir in collectionDirs) {
      final String collection = dir.path.split(Platform.pathSeparator).last;
      final List<Map<String, dynamic>> entities = await store.listAll(
        collection: collection,
      );
      for (final Map<String, dynamic> json in entities) {
        final WorldModelEntity entity = WorldModelEntity.fromJson(json);
        final String summary = (entity.data['summary'] as String?) ?? '';
        if (summary.isNotEmpty) {
          candidates.add(
            _SearchCandidate(
              collection: collection,
              id: entity.id,
              summary: summary,
            ),
          );
        }
      }
    }
  }

  return candidates;
}

/// Performs case-insensitive token matching on entity summaries.
///
/// The query is split into individual tokens. Each entity receives a score based on how many query tokens appear in its
/// summary. Entities that match no tokens are excluded from results.
List<_ScoredResult> _textSearch({
  required List<_SearchCandidate> candidates,
  required String query,
}) {
  final List<String> queryTokens = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((String token) => token.isNotEmpty)
      .toList();

  if (queryTokens.isEmpty) {
    return <_ScoredResult>[];
  }

  final List<_ScoredResult> results = <_ScoredResult>[];

  for (final _SearchCandidate candidate in candidates) {
    final String summaryLower = candidate.summary.toLowerCase();
    int matchedTokens = 0;

    for (final String token in queryTokens) {
      if (summaryLower.contains(token)) {
        matchedTokens++;
      }
    }

    if (matchedTokens == 0) {
      continue;
    }

    // Score is the fraction of query tokens that matched, giving a value between 0 and 1.
    final double score = matchedTokens / queryTokens.length;

    results.add(
      _ScoredResult(
        collection: candidate.collection,
        id: candidate.id,
        summary: candidate.summary,
        score: score,
      ),
    );
  }

  return results;
}

/// Performs semantic similarity search using Gemini text embeddings.
///
/// Embeds both the query and all candidate summaries, then computes cosine similarity between the query vector and each
/// candidate vector. Entities below a minimum similarity threshold are excluded.
///
/// Returns an empty list if the embedding service is unavailable or the API request fails. This allows the search tool
/// to degrade gracefully to text-only results.
Future<List<_ScoredResult>> _embeddingSearch({
  required List<_SearchCandidate> candidates,
  required String query,
}) async {
  final EmbeddingService service = EmbeddingService();

  if (!service.isAvailable) {
    return <_ScoredResult>[];
  }

  // Embed the query.
  final List<double>? queryEmbedding = await service.embedSingle(query);
  if (queryEmbedding == null) {
    return <_ScoredResult>[];
  }

  // Embed all candidate summaries in batch.
  final List<String> summaries = candidates
      .map((_SearchCandidate c) => c.summary)
      .toList();
  final List<List<double>> candidateEmbeddings = await service.embed(summaries);

  if (candidateEmbeddings.isEmpty ||
      candidateEmbeddings.length != candidates.length) {
    return <_ScoredResult>[];
  }

  // Minimum cosine similarity threshold. Candidates below this are not considered relevant.
  const double threshold = 0.3;

  final List<_ScoredResult> results = <_ScoredResult>[];

  for (int i = 0; i < candidates.length; i++) {
    final double similarity = EmbeddingService.cosineSimilarity(
      queryEmbedding,
      candidateEmbeddings[i],
    );

    if (similarity < threshold) {
      continue;
    }

    results.add(
      _ScoredResult(
        collection: candidates[i].collection,
        id: candidates[i].id,
        summary: candidates[i].summary,
        score: similarity,
      ),
    );
  }

  return results;
}

/// Merges results from text search and embedding search into a single ranked list.
///
/// When the same entity appears in both result sets, the scores are combined using a weighted average (text search
/// weighted at 0.4, embedding search at 0.6) to produce a single score. Entities that appear in only one result set
/// keep their original score scaled by that strategy's weight.
List<_ScoredResult> _mergeResults({
  required List<_ScoredResult> textResults,
  required List<_ScoredResult> embeddingResults,
}) {
  // If either list is empty, return the other directly without weight scaling so scores remain meaningful.
  if (embeddingResults.isEmpty) {
    return textResults;
  }
  if (textResults.isEmpty) {
    return embeddingResults;
  }

  const double textWeight = 0.4;
  const double embeddingWeight = 0.6;

  // Index embedding results by a composite key for fast lookup.
  final Map<String, _ScoredResult> embeddingIndex = <String, _ScoredResult>{};
  for (final _ScoredResult r in embeddingResults) {
    embeddingIndex['${r.collection}/${r.id}'] = r;
  }

  final Map<String, _ScoredResult> merged = <String, _ScoredResult>{};

  // Process text results, merging with embedding results where both exist.
  for (final _ScoredResult textResult in textResults) {
    final String key = '${textResult.collection}/${textResult.id}';
    final _ScoredResult? embeddingResult = embeddingIndex.remove(key);

    if (embeddingResult != null) {
      // Both strategies found this entity; combine scores.
      final double combinedScore =
          (textResult.score * textWeight) +
          (embeddingResult.score * embeddingWeight);
      merged[key] = _ScoredResult(
        collection: textResult.collection,
        id: textResult.id,
        summary: textResult.summary,
        score: combinedScore,
      );
    } else {
      // Only text search found this entity.
      merged[key] = _ScoredResult(
        collection: textResult.collection,
        id: textResult.id,
        summary: textResult.summary,
        score: textResult.score * textWeight,
      );
    }
  }

  // Remaining embedding results that had no text match.
  for (final _ScoredResult embeddingResult in embeddingIndex.values) {
    final String key = '${embeddingResult.collection}/${embeddingResult.id}';
    merged[key] = _ScoredResult(
      collection: embeddingResult.collection,
      id: embeddingResult.id,
      summary: embeddingResult.summary,
      score: embeddingResult.score * embeddingWeight,
    );
  }

  return merged.values.toList();
}

/// Internal representation of a world model entity prepared for search scoring.
class _SearchCandidate {
  const _SearchCandidate({
    required this.collection,
    required this.id,
    required this.summary,
  });

  /// The world model collection this entity belongs to.
  final String collection;

  /// The stable identifier for this entity within its collection.
  final String id;

  /// A human-readable summary extracted from the entity's data map. This is the field used for both text matching and
  /// embedding generation.
  final String summary;
}

/// A search result paired with a relevance score.
///
/// Produced by scoring functions and the merge step. The score semantics depend on context: for text search it
/// represents token match fraction, for embedding search it represents cosine similarity, and after merging it
/// represents the weighted combination.
class _ScoredResult {
  const _ScoredResult({
    required this.collection,
    required this.id,
    required this.summary,
    required this.score,
  });

  /// The world model collection this result originated from.
  final String collection;

  /// The entity identifier, usable with the `recall` tool to fetch full details.
  final String id;

  /// The entity summary, included so the agent can decide which results are worth recalling in full.
  final String summary;

  /// Relevance score. Higher values indicate greater relevance to the query.
  final double score;
}
