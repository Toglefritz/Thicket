import 'dart:io';

import 'package:thicket/thicket.dart';

import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `search` tool which finds world model entities across all collections by matching against their summary
/// fields.
///
/// This tool combines results from two search strategies:
/// 1. Text search: case-insensitive token matching against entity summaries.
/// 2. Embedding search: semantic similarity using vector embeddings (not yet implemented).
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
        'Matches against entity summaries across all collections using text matching. '
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

      // Run text-based search.
      final List<_ScoredResult> textResults = _textSearch(
        candidates: candidates,
        query: query,
      );

      // Placeholder: embedding-based search would produce additional scored results here and be merged with text
      // results using a combined ranking strategy.
      // final List<_ScoredResult> embeddingResults = await _embeddingSearch(
      //   candidates: candidates,
      //   query: query,
      // );

      // Merge and deduplicate results. Currently only text results exist.
      final List<_ScoredResult> merged = textResults;

      // Sort by score descending, take top N.
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

/// Loads all entities from every collection in the project's world model.
///
/// For cloud storage, uses `listCollections` to discover collections, then `listAll` for each. For local storage, lists
/// subdirectories of the storage root.
Future<List<_SearchCandidate>> _loadAllEntities(
  ProjectIdentity identity,
  String projectPath,
) async {
  final List<_SearchCandidate> candidates = <_SearchCandidate>[];

  if (identity.storageMode == StorageMode.cloud) {
    final FirestoreEntityStore store = ProjectResolver.createFirestoreStore(
      identity,
    );

    final List<String> collections = await store.listCollections();
    for (final String collection in collections) {
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
              data: entity.data,
            ),
          );
        }
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
              data: entity.data,
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

/// Internal representation of a world model entity prepared for search scoring.
///
/// Each candidate is built from a [WorldModelEntity] during the loading phase
/// in [_loadAllEntities]. Only entities that have a non-empty summary are
/// promoted to candidates, since the summary is the field used for text
/// matching.
class _SearchCandidate {
  const _SearchCandidate({
    required this.collection,
    required this.id,
    required this.summary,
    required this.data,
  });

  /// The world model collection this entity belongs to (e.g. "characters",
  /// "locations"). Corresponds to a storage subdirectory or Firestore
  /// subcollection.
  final String collection;

  /// The stable identifier for this entity within its collection.
  final String id;

  /// A human-readable summary extracted from the entity's data map.
  ///
  /// This is the primary field used for text-based search scoring.
  final String summary;

  /// The full data payload of the entity, retained so that future scoring
  /// strategies (such as embedding search) can access additional fields
  /// without a second round-trip to storage.
  final Map<String, dynamic> data;
}

/// A search result paired with a relevance score.
///
/// Produced by scoring functions like `_textSearch` and intended for ranking,
/// deduplication, and final output formatting. The `data` map is intentionally
/// excluded here because results are returned as lightweight references; the
/// agent retrieves full details through the `recall` tool when needed.
class _ScoredResult {
  const _ScoredResult({
    required this.collection,
    required this.id,
    required this.summary,
    required this.score,
  });

  /// The world model collection this result originated from.
  final String collection;

  /// The entity identifier, usable with the `recall` tool to fetch full
  /// details.
  final String id;

  /// The entity summary, included in the response so the agent can decide
  /// which results are worth recalling in full.
  final String summary;

  /// Relevance score in the range 0.0 to 1.0.
  ///
  /// For text search, this represents the fraction of query tokens that
  /// appeared in the entity's summary.
  final double score;
}
