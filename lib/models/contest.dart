/// Contest model for WINOVA competitions
class Contest {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String stage; // 'preStage', 'stage1', 'stage1Top50', 'finalStage', 'finished'
  final double entryFeeNova;
  final double voteAuraCost;
  final List<String> participantIds;
  final Map<String, int> voteCounts; // contestantId -> voteCount
  final List<String> top50Ids; // Top 50 contestant IDs after stage1
  final Map<String, double> winnerPrizes; // userId -> prize amount

  Contest({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.stage = 'preStage',
    this.entryFeeNova = 10.0,
    this.voteAuraCost = 10.0,
    List<String>? participantIds,
    Map<String, int>? voteCounts,
    List<String>? top50Ids,
    Map<String, double>? winnerPrizes,
  })  : participantIds = participantIds ?? [],
        voteCounts = voteCounts ?? {},
        top50Ids = top50Ids ?? [],
        winnerPrizes = winnerPrizes ?? {};

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isPreStage => stage == 'preStage';
  bool get isStage1 => stage == 'stage1';
  bool get isStage1Top50 => stage == 'stage1Top50';
  bool get isFinalStage => stage == 'finalStage';
  bool get isFinished => stage == 'finished';

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
    List<String>? top50Ids,
    Map<String, double>? winnerPrizes,
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
      top50Ids: top50Ids ?? this.top50Ids,
      winnerPrizes: winnerPrizes ?? this.winnerPrizes,
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
        'top50Ids': top50Ids,
        'winnerPrizes': winnerPrizes,
      };

  factory Contest.fromJson(Map<String, dynamic> json) => Contest(
        id: json['id'],
        name: json['name'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        stage: json['stage'] ?? 'preStage',
        entryFeeNova: json['entryFeeNova'] ?? 10.0,
        voteAuraCost: json['voteAuraCost'] ?? 10.0,
        participantIds: List<String>.from(json['participantIds'] ?? []),
        voteCounts: Map<String, int>.from(json['voteCounts'] ?? {}),
        top50Ids: List<String>.from(json['top50Ids'] ?? []),
        winnerPrizes: Map<String, double>.from(json['winnerPrizes'] ?? {}),
      );
}
