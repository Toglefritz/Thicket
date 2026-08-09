import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:thicket/thicket.dart';

import '../../services/project_resolver.dart';
import 'home_route.dart';
import 'home_view.dart';

/// Controller for the home screen that manages the Thicket Agent dashboard state.
///
/// This controller handles loading and mutating entities in the world model database. When the project is configured
/// for cloud storage, all operations go through [FirestoreEntityStore]. For legacy local configurations on desktop,
/// it falls back to the filesystem-backed [EntityStore].
class HomeController extends State<HomeRoute> {
  /// The active view tab.
  String _activeTab = 'webhooks';

  /// Path to the local Thicket project directory.
  String _projectPath = '/Users/scotthatfield/Documents/Projects/thicket';

  /// The Thicket Agent webhook URL.
  String _agentUrl = 'http://localhost:8080/events';

  /// Connection status to the agent server.
  bool _isAgentOnline = false;

  /// Audit logs of actions and events.
  final List<Map<String, dynamic>> _auditLogs = <Map<String, dynamic>>[];

  /// Flag indicating if an event is currently being dispatched to the agent.
  bool _isSendingEvent = false;

  /// The raw webhook response from the last event.
  String? _lastWebhookResponse;

  /// List of collections detected in the world model database.
  List<String> _collections = <String>[];

  /// Currently selected collection.
  String? _selectedCollection;

  /// List of entities loaded for the selected collection.
  List<WorldModelEntity> _entities = <WorldModelEntity>[];

  /// Selected entity for details/editing view.
  WorldModelEntity? _selectedEntity;

  /// Validation status of the project path.
  bool _isProjectPathValid = false;

  /// The resolved project identity, if available.
  ProjectIdentity? _identity;

  /// Firestore store instance, created when cloud mode is active.
  FirestoreEntityStore? _firestoreStore;

  @override
  void initState() {
    super.initState();
    _resolveProjectConfiguration();
    unawaited(_pingAgent());
    unawaited(loadWorldModel());
  }

  /// Getter for the active tab.
  String get activeTab => _activeTab;

  /// Getter for the project path.
  String get projectPath => _projectPath;

  /// Getter for the agent URL.
  String get agentUrl => _agentUrl;

  /// Getter for the agent server online status.
  bool get isAgentOnline => _isAgentOnline;

  /// Getter for the audit logs.
  List<Map<String, dynamic>> get auditLogs => _auditLogs;

  /// Getter for the sending status.
  bool get isSendingEvent => _isSendingEvent;

  /// Getter for the last webhook response text.
  String? get lastWebhookResponse => _lastWebhookResponse;

  /// Getter for detected collections.
  List<String> get collections => _collections;

  /// Getter for the selected collection.
  String? get selectedCollection => _selectedCollection;

  /// Getter for entities in the selected collection.
  List<WorldModelEntity> get entities => _entities;

  /// Getter for the selected entity.
  WorldModelEntity? get selectedEntity => _selectedEntity;

  /// Getter for the project path validity status.
  bool get isProjectPathValid => _isProjectPathValid;

  /// Whether the dashboard is operating in cloud storage mode.
  bool get _isCloudMode => _firestoreStore != null;

  /// Sets the active tab and rebuilds the view.
  void setActiveTab(String tab) {
    setState(() {
      _activeTab = tab;
    });
  }

  /// Sets the project path and triggers configuration resolution and database reload.
  void setProjectPath(String path) {
    setState(() {
      _projectPath = path;
    });
    _resolveProjectConfiguration();
    unawaited(loadWorldModel());
  }

  /// Sets the agent webhook URL.
  void setAgentUrl(String url) {
    setState(() {
      _agentUrl = url;
    });
    unawaited(_pingAgent());
  }

  /// Reads the project identity and configures the appropriate storage backend.
  ///
  /// On web, attempts to create a Firestore store from compile-time constants. On desktop, reads the project identity
  /// file and creates either a Firestore store (cloud mode) or prepares for local filesystem access.
  void _resolveProjectConfiguration() {
    if (kIsWeb) {
      _firestoreStore = ProjectResolver.createFirestoreStore();
      _isProjectPathValid = _firestoreStore != null;
      return;
    }

    _identity = ProjectResolver.readIdentity(_projectPath);

    if (_identity == null) {
      setState(() {
        _isProjectPathValid = false;
        _firestoreStore = null;
      });
      return;
    }

    setState(() {
      _isProjectPathValid = true;
    });

    if (_identity!.storageMode == StorageMode.cloud) {
      _firestoreStore = ProjectResolver.createFirestoreStore(
        identity: _identity,
      );
    } else {
      _firestoreStore = null;
    }
  }

  /// Tests the connection to the agent.
  Future<void> _pingAgent() async {
    try {
      final Uri uri = Uri.parse(_agentUrl);
      final http.Response response = await http
          .get(Uri.parse('${uri.scheme}://${uri.host}:${uri.port}/'))
          .timeout(
            const Duration(seconds: 2),
          );
      setState(() {
        _isAgentOnline =
            response.statusCode == 200 || response.statusCode == 404;
      });
    } catch (_) {
      setState(() {
        _isAgentOnline = false;
      });
    }
  }

  /// Refreshes the collections list and reloads the current collection.
  Future<void> loadWorldModel() async {
    if (_isCloudMode) {
      await _loadCloudWorldModel();
      return;
    }

    if (kIsWeb) {
      // No Firestore config available on web; show empty state.
      setState(() {
        _collections = <String>[];
        _entities = <WorldModelEntity>[];
        _selectedEntity = null;
      });
      return;
    }

    await _loadLocalWorldModel();
  }

  /// Loads collections and entities from Firestore.
  Future<void> _loadCloudWorldModel() async {
    try {
      final List<String> foundCollections = await _firestoreStore!
          .listCollections();

      setState(() {
        _collections = foundCollections;
        if (_selectedCollection == null ||
            !_collections.contains(_selectedCollection)) {
          _selectedCollection = _collections.isNotEmpty
              ? _collections.first
              : null;
        }
      });

      if (_selectedCollection != null) {
        await loadEntities(_selectedCollection!);
      } else {
        setState(() {
          _entities = <WorldModelEntity>[];
          _selectedEntity = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading cloud world model: $e');
      setState(() {
        _collections = <String>[];
        _entities = <WorldModelEntity>[];
        _selectedEntity = null;
      });
    }
  }

  /// Loads collections and entities from the local filesystem.
  Future<void> _loadLocalWorldModel() async {
    try {
      final String? storagePath = ProjectResolver.resolveLocalStoragePath(
        _identity!,
        _projectPath,
      );
      if (storagePath == null) {
        setState(() {
          _collections = <String>[];
          _entities = <WorldModelEntity>[];
          _selectedEntity = null;
        });
        return;
      }

      final Directory dir = Directory(storagePath);
      if (!dir.existsSync()) {
        setState(() {
          _collections = <String>[];
          _entities = <WorldModelEntity>[];
          _selectedEntity = null;
        });
        return;
      }

      final List<String> foundCollections =
          dir
              .listSync()
              .whereType<Directory>()
              .map((Directory d) => p.basename(d.path))
              .toList()
            ..sort();

      setState(() {
        _collections = foundCollections;
        if (_selectedCollection == null ||
            !_collections.contains(_selectedCollection)) {
          _selectedCollection = _collections.isNotEmpty
              ? _collections.first
              : null;
        }
      });

      if (_selectedCollection != null) {
        await loadEntities(_selectedCollection!);
      } else {
        setState(() {
          _entities = <WorldModelEntity>[];
          _selectedEntity = null;
        });
      }
    } catch (_) {
      setState(() {
        _collections = <String>[];
        _entities = <WorldModelEntity>[];
        _selectedEntity = null;
      });
    }
  }

  /// Sets the selected collection and loads its entities.
  void selectCollection(String collection) {
    setState(() {
      _selectedCollection = collection;
      _selectedEntity = null;
    });
    unawaited(loadEntities(collection));
  }

  /// Loads entities for a given collection from the active storage backend.
  Future<void> loadEntities(String collection) async {
    try {
      List<Map<String, dynamic>> allJson;

      if (_isCloudMode) {
        allJson = await _firestoreStore!.listAll(collection: collection);
      } else {
        final String? storagePath = ProjectResolver.resolveLocalStoragePath(
          _identity!,
          _projectPath,
        );
        if (storagePath == null) {
          setState(() {
            _entities = <WorldModelEntity>[];
          });
          return;
        }
        final EntityStore store = EntityStore(storagePath: storagePath);
        allJson = await store.listAll(collection: collection);
      }

      final List<WorldModelEntity> loaded = allJson
          .map(WorldModelEntity.fromJson)
          .toList();

      loaded.sort(
        (WorldModelEntity a, WorldModelEntity b) =>
            b.createdAt.compareTo(a.createdAt),
      );

      setState(() {
        _entities = loaded;
      });
    } catch (e) {
      debugPrint('Error loading entities: $e');
      setState(() {
        _entities = <WorldModelEntity>[];
      });
    }
  }

  /// Sets the currently active entity.
  void selectEntity(WorldModelEntity? entity) {
    setState(() {
      _selectedEntity = entity;
    });
  }

  /// Adds a new entity to the active collection.
  Future<void> saveNewEntity(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final DateTime now = DateTime.now().toUtc();
    final WorldModelEntity entity = WorldModelEntity(
      id: id,
      createdAt: now,
      updatedAt: now,
      data: data,
    );

    try {
      if (_isCloudMode) {
        await _firestoreStore!.save(collection: collection, entity: entity);
      } else {
        final String? storagePath = ProjectResolver.resolveLocalStoragePath(
          _identity!,
          _projectPath,
        );
        if (storagePath == null) {
          _showErrorSnackBar('Local storage path could not be resolved.');
          return;
        }
        final EntityStore store = EntityStore(storagePath: storagePath);
        await store.save(collection: collection, entity: entity);
      }
      _logAction('create_entity', 'Created entity $id in $collection');
      await loadWorldModel();
    } catch (e) {
      _showErrorSnackBar('Failed to save entity: $e');
    }
  }

  /// Updates an existing entity.
  Future<void> updateEntity(String collection, WorldModelEntity entity) async {
    final DateTime now = DateTime.now().toUtc();
    final WorldModelEntity updated = WorldModelEntity(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: now,
      data: entity.data,
    );

    try {
      if (_isCloudMode) {
        await _firestoreStore!.update(collection: collection, entity: updated);
      } else {
        final String? storagePath = ProjectResolver.resolveLocalStoragePath(
          _identity!,
          _projectPath,
        );
        if (storagePath == null) {
          _showErrorSnackBar('Local storage path could not be resolved.');
          return;
        }
        final EntityStore store = EntityStore(storagePath: storagePath);
        await store.update(collection: collection, entity: updated);
      }
      _logAction('update_entity', 'Updated entity ${entity.id} in $collection');
      await loadWorldModel();
    } catch (e) {
      _showErrorSnackBar('Failed to update entity: $e');
    }
  }

  /// Deletes an entity.
  Future<void> deleteEntity(String collection, String id) async {
    try {
      bool deleted;
      if (_isCloudMode) {
        deleted = await _firestoreStore!.delete(collection: collection, id: id);
      } else {
        final String? storagePath = ProjectResolver.resolveLocalStoragePath(
          _identity!,
          _projectPath,
        );
        if (storagePath == null) {
          _showErrorSnackBar('Local storage path could not be resolved.');
          return;
        }
        final EntityStore store = EntityStore(storagePath: storagePath);
        deleted = await store.delete(collection: collection, id: id);
      }

      if (deleted) {
        _logAction('delete_entity', 'Deleted entity $id from $collection');
        setState(() {
          if (_selectedEntity?.id == id) {
            _selectedEntity = null;
          }
        });
        await loadWorldModel();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete entity: $e');
    }
  }

  /// Sends a simulated event webhook payload to the Thicket Agent server.
  Future<void> sendWebhookEvent({
    required String source,
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    setState(() {
      _isSendingEvent = true;
      _lastWebhookResponse = null;
    });

    final Map<String, dynamic> body = <String, dynamic>{
      'source': source,
      'eventType': eventType,
      'projectPath': _projectPath,
      'payload': payload,
    };

    final DateTime startTime = DateTime.now();
    _logAction(
      'send_webhook_request',
      'Sending "$eventType" event from "$source" to agent at $_agentUrl',
      metadata: body,
    );

    try {
      final http.Response response = await http
          .post(
            Uri.parse(_agentUrl),
            headers: <String, String>{'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final DateTime endTime = DateTime.now();
      final Duration duration = endTime.difference(startTime);

      setState(() {
        _lastWebhookResponse = response.body;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String summary = data['summary'] as String? ?? 'Success';
        _logAction(
          'send_webhook_success',
          'Agent successfully processed event in ${duration.inMilliseconds}ms',
          metadata: <String, dynamic>{
            'status': response.statusCode,
            'summary': summary,
          },
        );
        await loadWorldModel();
      } else {
        _logAction(
          'send_webhook_failure',
          'Agent returned status code ${response.statusCode}',
          metadata: <String, dynamic>{
            'status': response.statusCode,
            'body': response.body,
          },
        );
      }
    } catch (e) {
      _logAction(
        'send_webhook_error',
        'Failed to connect or talk to the agent: $e',
        metadata: <String, dynamic>{'error': e.toString()},
      );
      _showErrorSnackBar('Agent Webhook failed: $e');
    } finally {
      setState(() {
        _isSendingEvent = false;
      });
      unawaited(_pingAgent());
    }
  }

  /// Appends a new action log item.
  void _logAction(
    String action,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    setState(() {
      _auditLogs.insert(0, <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'message': message,
        'metadata': metadata,
      });
    });
  }

  /// Shows an error message in a SnackBar.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => HomeView(this);
}
