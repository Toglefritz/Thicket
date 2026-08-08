library;

import '../core/world_model_entity.dart';

part 'episode_kind.dart';

/// Records a significant experience encountered while performing development work.
///
/// Episodes provide historical evidence from which more general knowledge (beliefs) can be derived. They are not
/// intended to capture every action performed by the agent or become transcripts of entire coding sessions. Instead,
/// they preserve experiences that may influence how future work should be approached.
///
/// An episode might describe a task that was performed, an architectural constraint that was discovered, an approach
/// that failed, the reason an implementation was rejected, an unexpected interaction between subsystems, or the outcome
/// of a debugging investigation.
class Episode extends WorldModelEntity {
  /// Creates a new [Episode] with the given unique identifier, timestamps, kind, summary, and content.
  const Episode({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.kind,
    required this.summary,
    required this.content,
  });

  /// Reconstructs an [Episode] from a JSON map.
  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      kind: EpisodeKind.values.byName(json['kind'] as String),
      summary: json['summary'] as String,
      content: json['content'] as String,
    );
  }

  /// The category of experience this episode represents.
  final EpisodeKind kind;

  /// A concise summary of the experience.
  ///
  /// Should be brief enough to be useful in retrieval results without requiring the full content to be read.
  final String summary;

  /// The full description of the experience, including relevant context, reasoning, and outcome.
  final String content;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'kind': kind.name,
    'summary': summary,
    'content': content,
  };
}
