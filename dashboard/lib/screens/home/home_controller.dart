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
/// This controller handles loading and mutating entities in the world model database (directly via [EntityStore] on
/// desktop, or using simulated data on the web), sending mock webhook events to the agent, and recording audit logs.
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

  /// Map of simulated collections for Web platforms.
  final Map<String, List<WorldModelEntity>> _webSimulatedDb = <String, List<WorldModelEntity>>{};

  /// Validation status of the project path.
  bool _isProjectPathValid = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSimulation();
    _checkProjectPath();
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

  /// Sets the active tab and rebuilds the view.
  void setActiveTab(String tab) {
    setState(() {
      _activeTab = tab;
    });
  }

  /// Sets the project path and triggers database reload.
  void setProjectPath(String path) {
    setState(() {
      _projectPath = path;
    });
    _checkProjectPath();
    unawaited(loadWorldModel());
  }

  /// Sets the agent webhook URL.
  void setAgentUrl(String url) {
    setState(() {
      _agentUrl = url;
    });
    unawaited(_pingAgent());
  }

  /// Tests the connection to the agent.
  Future<void> _pingAgent() async {
    try {
      final Uri uri = Uri.parse(_agentUrl);
      // Send a dummy request to check if the server is up
      final http.Response response = await http
          .get(Uri.parse('${uri.scheme}://${uri.host}:${uri.port}/'))
          .timeout(
            const Duration(seconds: 2),
          );
      setState(() {
        _isAgentOnline = response.statusCode == 200 || response.statusCode == 404;
      });
    } catch (_) {
      setState(() {
        _isAgentOnline = false;
      });
    }
  }

  /// Checks if the project path is initialized with Thicket.
  void _checkProjectPath() {
    if (kIsWeb) {
      _isProjectPathValid = true;
      return;
    }

    try {
      final File identityFile = File(
        p.join(_projectPath, '.thicket', 'project.json'),
      );
      setState(() {
        _isProjectPathValid = identityFile.existsSync();
      });
    } catch (_) {
      setState(() {
        _isProjectPathValid = false;
      });
    }
  }

  /// Populates initial simulated database values for the Web demo environment.
  void _initializeWebSimulation() {
    final DateTime now = DateTime.now();

    _webSimulatedDb['beliefs'] = <WorldModelEntity>[
      WorldModelEntity(
        id: 'bel_001',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        data: <String, dynamic>{
          'summary': 'GitHub commits should trigger codebase investigation',
          'confidence': 0.95,
          'source': 'experience_e1',
        },
      ),
      WorldModelEntity(
        id: 'bel_002',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        data: <String, dynamic>{
          'summary': 'User prefers direct deployment to Cloud Run without Docker',
          'confidence': 1.0,
          'source': 'webhook_slack',
        },
      ),
    ];

    _webSimulatedDb['concepts'] = <WorldModelEntity>[
      WorldModelEntity(
        id: 'con_001',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        data: <String, dynamic>{
          'name': 'WorldModelEntity',
          'definition': 'Flexible container for world model data',
          'type': 'class',
          'filePath': 'world_model/lib/src/models/core/world_model_entity.dart',
        },
      ),
      WorldModelEntity(
        id: 'con_002',
        createdAt: now.subtract(const Duration(hours: 18)),
        updatedAt: now.subtract(const Duration(hours: 18)),
        data: <String, dynamic>{
          'name': 'ProjectResolver',
          'definition': 'Resolves persistent database paths from root settings',
          'type': 'class',
          'filePath': 'agent/bin/server.dart',
        },
      ),
    ];

    _webSimulatedDb['episodes'] = <WorldModelEntity>[
      WorldModelEntity(
        id: 'epi_001',
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        data: <String, dynamic>{
          'summary': 'Parsed git push webhook event',
          'result': 'Created concept definition for new module',
          'actions': <String>['recall', 'remember'],
        },
      ),
    ];
  }

  /// Refreshes the collections list and reloads the current collection.
  Future<void> loadWorldModel() async {
    if (kIsWeb) {
      setState(() {
        _collections = _webSimulatedDb.keys.toList()..sort();
        if (_selectedCollection == null || !_collections.contains(_selectedCollection)) {
          _selectedCollection = _collections.isNotEmpty ? _collections.first : null;
        }
      });
      _loadWebEntities();
      return;
    }

    try {
      final String storagePath = ProjectResolver.resolveStoragePath(_projectPath);
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
          dir.listSync().whereType<Directory>().map((Directory d) => p.basename(d.path)).toList()..sort();

      setState(() {
        _collections = foundCollections;
        if (_selectedCollection == null || !_collections.contains(_selectedCollection)) {
          _selectedCollection = _collections.isNotEmpty ? _collections.first : null;
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
    if (kIsWeb) {
      _loadWebEntities();
    } else {
      unawaited(loadEntities(collection));
    }
  }

  /// Loads entities for a given collection from disk (desktop only).
  Future<void> loadEntities(String collection) async {
    if (kIsWeb) {
      _loadWebEntities();
      return;
    }

    try {
      final String storagePath = ProjectResolver.resolveStoragePath(_projectPath);
      final EntityStore store = EntityStore(storagePath: storagePath);
      final List<Map<String, dynamic>> allJson = await store.listAll(collection: collection);
      final List<WorldModelEntity> loaded = allJson.map(WorldModelEntity.fromJson).toList();

      // Sort newest first
      loaded.sort(
        (WorldModelEntity a, WorldModelEntity b) => b.createdAt.compareTo(a.createdAt),
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

  /// Loads simulated entities from the in-memory web database.
  void _loadWebEntities() {
    if (_selectedCollection != null) {
      final List<WorldModelEntity> list = _webSimulatedDb[_selectedCollection] ?? <WorldModelEntity>[];
      setState(() {
        _entities = List<WorldModelEntity>.from(list)
          ..sort(
            (WorldModelEntity a, WorldModelEntity b) => b.createdAt.compareTo(a.createdAt),
          );
      });
    } else {
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
  Future<void> saveNewEntity(String collection, String id, Map<String, dynamic> data) async {
    final DateTime now = DateTime.now().toUtc();
    final WorldModelEntity entity = WorldModelEntity(
      id: id,
      createdAt: now,
      updatedAt: now,
      data: data,
    );

    if (kIsWeb) {
      if (!_webSimulatedDb.containsKey(collection)) {
        _webSimulatedDb[collection] = <WorldModelEntity>[];
      }
      _webSimulatedDb[collection]!.add(entity);
      _logAction('create_entity', 'Created simulated entity $id in $collection');
      await loadWorldModel();
      return;
    }

    try {
      final String storagePath = ProjectResolver.resolveStoragePath(_projectPath);
      final EntityStore store = EntityStore(storagePath: storagePath);
      await store.save(collection: collection, entity: entity);
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

    if (kIsWeb) {
      final List<WorldModelEntity> list = _webSimulatedDb[collection] ?? <WorldModelEntity>[];
      final int idx = list.indexWhere((WorldModelEntity e) => e.id == entity.id);
      if (idx != -1) {
        list[idx] = updated;
      }
      _logAction('update_entity', 'Updated simulated entity ${entity.id} in $collection');
      await loadWorldModel();
      return;
    }

    try {
      final String storagePath = ProjectResolver.resolveStoragePath(_projectPath);
      final EntityStore store = EntityStore(storagePath: storagePath);
      await store.update(collection: collection, entity: updated);
      _logAction('update_entity', 'Updated entity ${entity.id} in $collection');
      await loadWorldModel();
    } catch (e) {
      _showErrorSnackBar('Failed to update entity: $e');
    }
  }

  /// Deletes an entity.
  Future<void> deleteEntity(String collection, String id) async {
    if (kIsWeb) {
      if (_webSimulatedDb.containsKey(collection)) {
        _webSimulatedDb[collection]!.removeWhere((WorldModelEntity e) => e.id == id);
      }
      _logAction('delete_entity', 'Deleted simulated entity $id from $collection');
      setState(() {
        if (_selectedEntity?.id == id) {
          _selectedEntity = null;
        }
      });
      await loadWorldModel();
      return;
    }

    try {
      final String storagePath = ProjectResolver.resolveStoragePath(_projectPath);
      final EntityStore store = EntityStore(storagePath: storagePath);
      final bool deleted = await store.delete(collection: collection, id: id);
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
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String summary = data['summary'] as String? ?? 'Success';
        _logAction(
          'send_webhook_success',
          'Agent successfully processed event in ${duration.inMilliseconds}ms',
          metadata: <String, dynamic>{
            'status': response.statusCode,
            'summary': summary,
          },
        );
        // Refresh world model to see what the agent changed/learned!
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
  void _logAction(String action, String message, {Map<String, dynamic>? metadata}) {
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
