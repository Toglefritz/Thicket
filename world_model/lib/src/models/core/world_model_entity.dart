/// A generic container for any entity stored in a Thicket world model.
///
/// Thicket uses an entirely schema-flexible world model. Instead of static structures, every entity is stored as a
/// [WorldModelEntity] with a unique identifier [id], creation/modification timestamps, and a flexible JSON payload in
/// [data]. This structure allows LLM agents to dynamically define schemas at runtime.
class WorldModelEntity {
  /// Creates a new [WorldModelEntity] with the given unique identifier, timestamps, and dynamic payload.
  const WorldModelEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.data,
  });

  /// Reconstructs the entity fields and dynamic payload from a JSON map.
  factory WorldModelEntity.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String;
    final DateTime createdAt = DateTime.parse(json['createdAt'] as String);
    final DateTime updatedAt = DateTime.parse(json['updatedAt'] as String);

    final Map<String, dynamic> data = Map<String, dynamic>.from(json)
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');

    return WorldModelEntity(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      data: data,
    );
  }

  /// A globally unique identifier for this entity.
  final String id;

  /// When this entity was first created.
  final DateTime createdAt;

  /// When this entity was last modified.
  final DateTime updatedAt;

  /// The dynamic, flexible JSON properties of this entity.
  final Map<String, dynamic> data;

  /// Creates a JSON-serializable map merging the core fields with the dynamic payload.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    ...data,
  };
}
