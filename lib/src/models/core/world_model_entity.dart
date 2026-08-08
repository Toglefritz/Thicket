/// The base type for all entities stored in a Thicket world model.
///
/// Every object in the world model, episodes, beliefs, concepts, relationships, shares these common fields for
/// identity, temporal tracking, and optimistic concurrency via revision numbering.
///
/// This type is intentionally kept minimal. It represents the stable substrate described in the project architecture:
/// the small set of underlying primitives that remains fixed while the project-specific ontology evolves above it.
class WorldModelEntity {
  /// A globally unique identifier for this entity.
  ///
  /// Generated once at creation time and never changed, even if the entity's content is revised.
  final String id;

  /// When this entity was first created.
  final DateTime createdAt;

  /// When this entity was last modified.
  ///
  /// Updated on every revision. Equal to [createdAt] for newly created entities.
  final DateTime updatedAt;

  const WorldModelEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a JSON-serializable map of the base entity fields.
  ///
  /// Subclasses should call this and merge their own fields into the resulting map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  /// Reconstructs the base entity fields from a JSON map.
  ///
  /// Subclasses should use this in their own factory constructors.
  factory WorldModelEntity.fromJson(Map<String, dynamic> json) {
    return WorldModelEntity(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
