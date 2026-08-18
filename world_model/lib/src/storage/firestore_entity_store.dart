import 'dart:convert';

// The constructor intentionally maps public parameter names to private fields.
// ignore_for_file: prefer_initializing_formals

import 'package:http/http.dart' as http;
import 'package:thicket/thicket.dart';

/// Persists and retrieves world model entities using the Google Cloud Firestore REST API.
///
/// This store provides the same CRUD contract as [EntityStore] but operates against a remote Firestore database instead
/// of the local filesystem. This allows the agent and dashboard to share a single source of truth regardless of which
/// machine they run on.
///
/// Firestore document structure:
/// ```dart
/// // projects/{gcpProjectId}/databases/(default)/documents/
/// //   thicket_projects/{thicketProjectId}/{collection}/{entityId}
/// ```
///
/// Each entity is stored as a single Firestore document. The entity's flexible JSON payload is flattened into Firestore
/// fields using Firestore's native value encoding.
class FirestoreEntityStore {
  /// Creates a store targeting the given GCP project and Thicket project.
  ///
  /// The [gcpProjectId] identifies the Google Cloud project that owns the Firestore database. The [thicketProjectId]
  /// scopes storage to a particular Thicket project (the value from `.thicket/project.json`).
  ///
  /// The [apiKey] is used for authenticating requests. When running on Google Cloud infrastructure (Cloud Run, GCE),
  /// prefer passing a service account access token via [accessToken] instead.
  FirestoreEntityStore({
    required String gcpProjectId,
    required String thicketProjectId,
    String? apiKey,
    String? accessToken,
    String databaseId = '(default)',
    http.Client? httpClient,
  }) : _gcpProjectId = gcpProjectId,
       _thicketProjectId = thicketProjectId,
       _apiKey = apiKey,
       _accessToken = accessToken,
       _databaseId = databaseId,
       _client = httpClient ?? http.Client();

  /// The Google Cloud project ID that owns the Firestore database.
  final String _gcpProjectId;

  /// The Thicket project ID used to scope documents within Firestore.
  final String _thicketProjectId;

  /// Optional API key for unauthenticated or key-authenticated REST calls.
  final String? _apiKey;

  /// Optional OAuth2 access token for authenticated requests from service accounts or user credentials.
  final String? _accessToken;

  /// The Firestore database ID. Defaults to `(default)` but can be set to a named database.
  final String _databaseId;

  /// HTTP client used for all Firestore REST API calls.
  final http.Client _client;

  /// Base URL for the Firestore REST API targeting this project's database.
  String get _baseUrl => 'https://firestore.googleapis.com/v1/projects/$_gcpProjectId/databases/$_databaseId/documents';

  /// The document path prefix for this Thicket project's entities.
  String get _projectPrefix => 'thicket_projects/$_thicketProjectId';

  /// Saves a new entity to Firestore.
  ///
  /// Creates a document at the path `thicket_projects/{projectId}/{collection}/{entityId}`. If a document already
  /// exists at that path, a [StateError] is thrown to preserve create-only semantics consistent with [EntityStore].
  Future<void> save({
    required String collection,
    required WorldModelEntity entity,
  }) async {
    final String documentPath = '$_projectPrefix/$collection/${entity.id}';
    final Uri uri = _documentUri(documentPath);

    // Check if document already exists.
    final http.Response existing = await _client.get(uri, headers: _headers());
    if (existing.statusCode == 200) {
      throw StateError(
        'Entity "${entity.id}" already exists in "$collection".',
      );
    }

    // Create the document using the patch method with the document ID in the URL. Firestore REST API uses PATCH to
    // create or update documents at a specific path.
    final Map<String, dynamic> firestoreDoc = _entityToFirestoreDocument(
      entity,
    );
    final http.Response response = await _client.patch(
      uri,
      headers: _headers(contentType: 'application/json'),
      body: jsonEncode(firestoreDoc),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to save entity "${entity.id}" in "$collection": ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Updates an existing entity in Firestore.
  ///
  /// Overwrites the document at the entity's path. Throws a [StateError] if the document does not already exist,
  /// preserving update-only semantics consistent with [EntityStore].
  Future<void> update({
    required String collection,
    required WorldModelEntity entity,
  }) async {
    final String documentPath = '$_projectPrefix/$collection/${entity.id}';
    final Uri uri = _documentUri(documentPath);

    // Verify document exists before updating.
    final http.Response existing = await _client.get(uri, headers: _headers());
    if (existing.statusCode == 404) {
      throw StateError(
        'Cannot update entity "${entity.id}" in "$collection": document does not exist',
      );
    }

    final Map<String, dynamic> firestoreDoc = _entityToFirestoreDocument(
      entity,
    );
    final http.Response response = await _client.patch(
      uri,
      headers: _headers(contentType: 'application/json'),
      body: jsonEncode(firestoreDoc),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to update entity "${entity.id}" in "$collection": ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Loads a single entity by ID from the given collection.
  ///
  /// Returns null if no document exists for the given ID.
  Future<Map<String, dynamic>?> load({
    required String collection,
    required String id,
  }) async {
    final String documentPath = '$_projectPrefix/$collection/$id';
    final Uri uri = _documentUri(documentPath);

    final http.Response response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to load entity "$id" from "$collection": ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> doc = jsonDecode(response.body) as Map<String, dynamic>;
    return _firestoreDocumentToEntity(doc);
  }

  /// Lists all entities in the given collection.
  ///
  /// Returns a list of deserialized JSON maps, one per document in the collection. Returns an empty list if the
  /// collection contains no documents.
  Future<List<Map<String, dynamic>>> listAll({
    required String collection,
  }) async {
    final String collectionPath = '$_projectPrefix/$collection';
    final Uri uri = _collectionUri(collectionPath);

    final List<Map<String, dynamic>> results = <Map<String, dynamic>>[];
    String? nextPageToken;

    // Paginate through all documents in the collection.
    do {
      final Uri pageUri = nextPageToken != null
          ? uri.replace(
              queryParameters: <String, String>{
                ...uri.queryParameters,
                'pageToken': nextPageToken,
              },
            )
          : uri;

      final http.Response response = await _client.get(
        pageUri,
        headers: _headers(),
      );

      if (response.statusCode == 404) {
        return results;
      }

      if (response.statusCode != 200) {
        throw StateError(
          'Failed to list entities in "$collection": ${response.statusCode} ${response.body}',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic>? documents = body['documents'] as List<dynamic>?;

      if (documents != null) {
        for (final dynamic doc in documents) {
          final Map<String, dynamic> entityJson = _firestoreDocumentToEntity(
            doc as Map<String, dynamic>,
          );
          results.add(entityJson);
        }
      }

      nextPageToken = body['nextPageToken'] as String?;
    } while (nextPageToken != null);

    return results;
  }

  /// Lists all collection names that contain at least one document for this project.
  ///
  /// This replaces the filesystem directory listing used by the dashboard to discover collections. Uses the Firestore
  /// REST API's listCollectionIds endpoint.
  Future<List<String>> listCollections() async {
    final Uri uri = Uri.parse('$_baseUrl/$_projectPrefix:listCollectionIds');

    final http.Response response = await _client.post(
      uri,
      headers: _headers(contentType: 'application/json'),
      body: jsonEncode(<String, dynamic>{}),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to list collections: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic>? collectionIds = body['collectionIds'] as List<dynamic>?;

    if (collectionIds == null) {
      return <String>[];
    }

    final List<String> collections = collectionIds.map((dynamic id) => id as String).toList()..sort();
    return collections;
  }

  /// Deletes an entity document from Firestore.
  ///
  /// Returns true if the document existed and was deleted, false if it did not exist.
  Future<bool> delete({
    required String collection,
    required String id,
  }) async {
    final String documentPath = '$_projectPrefix/$collection/$id';
    final Uri uri = _documentUri(documentPath);

    // Check existence first to return the correct boolean.
    final http.Response existing = await _client.get(uri, headers: _headers());
    if (existing.statusCode == 404) {
      return false;
    }

    final http.Response response = await _client.delete(
      uri,
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to delete entity "$id" from "$collection": ${response.statusCode} ${response.body}',
      );
    }

    return true;
  }

  /// Builds the URI for a specific document path.
  Uri _documentUri(String documentPath) {
    final Uri base = Uri.parse('$_baseUrl/$documentPath');
    if (_apiKey != null) {
      return base.replace(
        queryParameters: <String, String>{
          ...base.queryParameters,
          'key': _apiKey,
        },
      );
    }
    return base;
  }

  /// Builds the URI for listing documents in a collection.
  Uri _collectionUri(String collectionPath) {
    final Uri base = Uri.parse('$_baseUrl/$collectionPath');
    if (_apiKey != null) {
      return base.replace(
        queryParameters: <String, String>{
          ...base.queryParameters,
          'key': _apiKey,
        },
      );
    }
    return base;
  }

  /// Builds HTTP headers for Firestore REST API requests.
  Map<String, String> _headers({String? contentType}) {
    final Map<String, String> headers = <String, String>{};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    return headers;
  }

  /// Converts a [WorldModelEntity] into a Firestore REST API document body.
  ///
  /// Firestore documents use a typed value format where each field is wrapped in a type descriptor (e.g.
  /// `{"stringValue": "hello"}`, `{"integerValue": "42"}`).
  Map<String, dynamic> _entityToFirestoreDocument(WorldModelEntity entity) {
    final Map<String, dynamic> json = entity.toJson();
    final Map<String, dynamic> fields = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in json.entries) {
      fields[entry.key] = _toFirestoreValue(entry.value);
    }

    return <String, dynamic>{'fields': fields};
  }

  /// Reconstructs an entity JSON map from a Firestore REST API document response.
  Map<String, dynamic> _firestoreDocumentToEntity(
    Map<String, dynamic> document,
  ) {
    final Map<String, dynamic> fields = document['fields'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> result = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in fields.entries) {
      result[entry.key] = _fromFirestoreValue(
        entry.value as Map<String, dynamic>,
      );
    }

    return result;
  }

  /// Encodes a Dart value into the Firestore typed value format.
  Map<String, dynamic> _toFirestoreValue(dynamic value) {
    if (value == null) {
      return <String, dynamic>{'nullValue': null};
    }
    if (value is String) {
      return <String, dynamic>{'stringValue': value};
    }
    if (value is int) {
      return <String, dynamic>{'integerValue': value.toString()};
    }
    if (value is double) {
      return <String, dynamic>{'doubleValue': value};
    }
    if (value is bool) {
      return <String, dynamic>{'booleanValue': value};
    }
    if (value is List) {
      return <String, dynamic>{
        'arrayValue': <String, dynamic>{
          'values': value.map(_toFirestoreValue).toList(),
        },
      };
    }
    if (value is Map) {
      final Map<String, dynamic> mapFields = <String, dynamic>{};
      for (final MapEntry<dynamic, dynamic> entry in value.entries) {
        mapFields[entry.key.toString()] = _toFirestoreValue(entry.value);
      }
      return <String, dynamic>{
        'mapValue': <String, dynamic>{'fields': mapFields},
      };
    }

    // Fallback: treat as string.
    return <String, dynamic>{'stringValue': value.toString()};
  }

  /// Decodes a Firestore typed value back into a plain Dart value.
  dynamic _fromFirestoreValue(Map<String, dynamic> firestoreValue) {
    if (firestoreValue.containsKey('nullValue')) {
      return null;
    }
    if (firestoreValue.containsKey('stringValue')) {
      return firestoreValue['stringValue'] as String;
    }
    if (firestoreValue.containsKey('integerValue')) {
      return int.parse(firestoreValue['integerValue'] as String);
    }
    if (firestoreValue.containsKey('doubleValue')) {
      final dynamic raw = firestoreValue['doubleValue'];
      if (raw is double) return raw;
      return double.parse(raw.toString());
    }
    if (firestoreValue.containsKey('booleanValue')) {
      return firestoreValue['booleanValue'] as bool;
    }
    if (firestoreValue.containsKey('arrayValue')) {
      final Map<String, dynamic> arrayValue = firestoreValue['arrayValue'] as Map<String, dynamic>;
      final List<dynamic> values = arrayValue['values'] as List<dynamic>? ?? <dynamic>[];
      return values.map((dynamic v) => _fromFirestoreValue(v as Map<String, dynamic>)).toList();
    }
    if (firestoreValue.containsKey('mapValue')) {
      final Map<String, dynamic> mapValue = firestoreValue['mapValue'] as Map<String, dynamic>;
      final Map<String, dynamic> fields = mapValue['fields'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> result = <String, dynamic>{};
      for (final MapEntry<String, dynamic> entry in fields.entries) {
        result[entry.key] = _fromFirestoreValue(
          entry.value as Map<String, dynamic>,
        );
      }
      return result;
    }

    // Fallback for unknown types (timestampValue, geoPointValue, referenceValue, etc.)
    return firestoreValue.values.first;
  }
}
