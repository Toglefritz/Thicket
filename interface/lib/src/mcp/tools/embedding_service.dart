import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Generates text embeddings using the Gemini embedding API.
///
/// This service calls the `batchEmbedContents` endpoint to embed multiple texts in a single request, reducing latency
/// when scoring many candidates during search. The resulting vectors are used for cosine similarity comparisons.
///
/// Requires the `GEMINI_API_KEY` environment variable to be set. If the key is absent, embedding operations fail
/// gracefully by returning empty results rather than throwing, allowing text search to still function.
class EmbeddingService {
  /// Creates an embedding service using the given API key.
  ///
  /// If [apiKey] is null or empty, all operations return empty results.
  EmbeddingService({String? apiKey, http.Client? httpClient})
    : _apiKey = apiKey ?? Platform.environment['GEMINI_API_KEY'] ?? '',
      _client = httpClient ?? http.Client();

  /// The Gemini embedding model to use.
  static const String _model = 'gemini-embedding-001';

  /// The batch endpoint URL template.
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:batchEmbedContents';

  /// The API key for authenticating with the Gemini API.
  final String _apiKey;

  /// HTTP client for making API requests.
  final http.Client _client;

  /// Whether this service is configured with a valid API key.
  bool get isAvailable => _apiKey.isNotEmpty;

  /// Generates embedding vectors for a list of texts.
  ///
  /// Returns a list of vectors (each a `List<double>`) in the same order as the input texts. If the API key is not
  /// configured or the request fails, returns an empty list.
  ///
  /// The [texts] list is batched into groups of 100 (the API limit per request) and processed sequentially.
  Future<List<List<double>>> embed(List<String> texts) async {
    if (!isAvailable || texts.isEmpty) {
      return <List<double>>[];
    }

    final List<List<double>> allEmbeddings = <List<double>>[];

    // The Gemini batch endpoint supports up to 100 texts per request.
    const int batchSize = 100;
    for (int i = 0; i < texts.length; i += batchSize) {
      final List<String> batch = texts.sublist(
        i,
        i + batchSize > texts.length ? texts.length : i + batchSize,
      );
      final List<List<double>> batchResult = await _embedBatch(batch);
      if (batchResult.isEmpty) {
        // API failure; return empty to signal that embedding search is unavailable for this request.
        return <List<double>>[];
      }
      allEmbeddings.addAll(batchResult);
    }

    return allEmbeddings;
  }

  /// Generates an embedding vector for a single text.
  ///
  /// Convenience wrapper around [embed] for single-text use cases like embedding the search query.
  Future<List<double>?> embedSingle(String text) async {
    final List<List<double>> results = await embed(<String>[text]);
    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }

  /// Calls the batchEmbedContents endpoint for a group of texts.
  Future<List<List<double>>> _embedBatch(List<String> texts) async {
    final Uri uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final List<Map<String, dynamic>> requests = texts
        .map(
          (String text) => <String, dynamic>{
            'model': 'models/$_model',
            'content': <String, dynamic>{
              'parts': <Map<String, String>>[
                <String, String>{'text': text},
              ],
            },
          },
        )
        .toList();

    final Map<String, dynamic> body = <String, dynamic>{
      'requests': requests,
    };

    try {
      final http.Response response = await _client.post(
        uri,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        // Log the failure but don't throw; embedding search degrades gracefully.
        return <List<double>>[];
      }

      final Map<String, dynamic> responseBody =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> embeddings =
          responseBody['embeddings'] as List<dynamic>;

      return embeddings.map((dynamic embedding) {
        final Map<String, dynamic> embeddingMap =
            embedding as Map<String, dynamic>;
        final List<dynamic> values = embeddingMap['values'] as List<dynamic>;
        return values.map((dynamic v) => (v as num).toDouble()).toList();
      }).toList();
    } on Object {
      // Network errors, JSON parse errors, etc. Degrade gracefully.
      return <List<double>>[];
    }
  }

  /// Computes cosine similarity between two vectors.
  ///
  /// Returns a value between -1 and 1, where 1 indicates identical direction, 0 indicates orthogonality, and -1
  /// indicates opposite direction. For text embeddings, values typically range from 0 to 1.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) {
      return 0;
    }

    double dotProduct = 0;
    double magnitudeA = 0;
    double magnitudeB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      magnitudeA += a[i] * a[i];
      magnitudeB += b[i] * b[i];
    }

    final double magnitude = sqrt(magnitudeA) * sqrt(magnitudeB);
    if (magnitude == 0) {
      return 0;
    }

    return dotProduct / magnitude;
  }
}
