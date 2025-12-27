/// Contest model for WINOVA competitions
class Contest {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String stage; // 'preview', 'stage1', 'stage2', 'stage3', 'complete'
  final double entryFeeNova;
  final double voteAuraCost;
  final List<String> participantIds;
  final Map<String, int> voteCounts; // contestantId -> voteCount

  Contest({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.stage = 'preview',
    this.entryFeeNova = 10.0,
    this.voteAuraCost = 1.0,
    List<String>? participantIds,
    Map<String, int>? voteCounts,
  })  : participantIds = participantIds ?? [],
        voteCounts = voteCounts ?? {};

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isStage1 => stage == 'stage1';
  bool get isPreview => stage == 'preview';

  Contest copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? stage,
    double? entryFeeNova,
    double? voteAuraCost,
    List<String>? participantIds,
    Map<String, int>? voteCounts,
  }) {
    return Contest(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      stage: stage ?? this.stage,
      entryFeeNova: entryFeeNova ?? this.entryFeeNova,
      voteAuraCost: voteAuraCost ?? this.voteAuraCost,
      participantIds: participantIds ?? this.participantIds,
      voteCounts: voteCounts ?? this.voteCounts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'stage': stage,
        'entryFeeNova': entryFeeNova,
        'voteAuraCost': voteAuraCost,
        'participantIds': participantIds,
        'voteCounts': voteCounts,
      };

  factory Contest.fromJson(Map<String, dynamic> json) => Contest(
        id: json['id'],
        name: json['name'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        stage: json['stage'] ?? 'preview',
        entryFeeNova: json['entryFeeNova'] ?? 10.0,
        voteAuraCost: json['voteAuraCost'] ?? 1.0,
        participantIds: List<String>.from(json['participantIds'] ?? []),
        voteCounts: Map<String, int>.from(json['voteCounts'] ?? {}),
      );
}
