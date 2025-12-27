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
  
  // Stage timing (KSA time)
  final DateTime? stage1StartTime; // When Stage1 starts (e.g., 2:00 PM)
  final DateTime? stage1EndTime; // When Stage1 ends (e.g., 8:00 PM)
  final DateTime? finalStartTime; // When Final starts (e.g., 8:00 PM)
  final DateTime? finalEndTime; // When Final ends (e.g., 10:00 PM)
  
  // Free Hour (random hour during Stage1)
  final DateTime? freeHourStart;
  final DateTime? freeHourEnd;
  
  // Spotlight (Lucky person of the day)
  final String? spotlightUserId; // Winner of spotlight
  final double spotlightPrize; // Amount won by spotlight winner
  final DateTime? spotlightAnnouncementTime; // When to announce (e.g., 5:00 PM)
  
  // Stage1 vote rewards tracking
  final Map<String, double> stage1AuraRewards; // contestantId -> aura earned from stage1

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
    this.stage1StartTime,
    this.stage1EndTime,
    this.finalStartTime,
    this.finalEndTime,
    this.freeHourStart,
    this.freeHourEnd,
    this.spotlightUserId,
    this.spotlightPrize = 0.0,
    this.spotlightAnnouncementTime,
    Map<String, double>? stage1AuraRewards,
  })  : participantIds = participantIds ?? [],
        voteCounts = voteCounts ?? {},
        top50Ids = top50Ids ?? [],
        winnerPrizes = winnerPrizes ?? {},
        stage1AuraRewards = stage1AuraRewards ?? {};

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
    DateTime? stage1StartTime,
    DateTime? stage1EndTime,
    DateTime? finalStartTime,
    DateTime? finalEndTime,
    DateTime? freeHourStart,
    DateTime? freeHourEnd,
    String? spotlightUserId,
    double? spotlightPrize,
    DateTime? spotlightAnnouncementTime,
    Map<String, double>? stage1AuraRewards,
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
      stage1StartTime: stage1StartTime ?? this.stage1StartTime,
      stage1EndTime: stage1EndTime ?? this.stage1EndTime,
      finalStartTime: finalStartTime ?? this.finalStartTime,
      finalEndTime: finalEndTime ?? this.finalEndTime,
      freeHourStart: freeHourStart ?? this.freeHourStart,
      freeHourEnd: freeHourEnd ?? this.freeHourEnd,
      spotlightUserId: spotlightUserId ?? this.spotlightUserId,
      spotlightPrize: spotlightPrize ?? this.spotlightPrize,
      spotlightAnnouncementTime: spotlightAnnouncementTime ?? this.spotlightAnnouncementTime,
      stage1AuraRewards: stage1AuraRewards ?? this.stage1AuraRewards,
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
        'stage1StartTime': stage1StartTime?.toIso8601String(),
        'stage1EndTime': stage1EndTime?.toIso8601String(),
        'finalStartTime': finalStartTime?.toIso8601String(),
        'finalEndTime': finalEndTime?.toIso8601String(),
        'freeHourStart': freeHourStart?.toIso8601String(),
        'freeHourEnd': freeHourEnd?.toIso8601String(),
        'spotlightUserId': spotlightUserId,
        'spotlightPrize': spotlightPrize,
        'spotlightAnnouncementTime': spotlightAnnouncementTime?.toIso8601String(),
        'stage1AuraRewards': stage1AuraRewards,
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
        stage1StartTime: json['stage1StartTime'] != null 
            ? DateTime.parse(json['stage1StartTime']) 
            : null,
        stage1EndTime: json['stage1EndTime'] != null 
            ? DateTime.parse(json['stage1EndTime']) 
            : null,
        finalStartTime: json['finalStartTime'] != null 
            ? DateTime.parse(json['finalStartTime']) 
            : null,
        finalEndTime: json['finalEndTime'] != null 
            ? DateTime.parse(json['finalEndTime']) 
            : null,
        freeHourStart: json['freeHourStart'] != null 
            ? DateTime.parse(json['freeHourStart']) 
            : null,
        freeHourEnd: json['freeHourEnd'] != null 
            ? DateTime.parse(json['freeHourEnd']) 
            : null,
        spotlightUserId: json['spotlightUserId'],
        spotlightPrize: json['spotlightPrize'] ?? 0.0,
        spotlightAnnouncementTime: json['spotlightAnnouncementTime'] != null 
            ? DateTime.parse(json['spotlightAnnouncementTime']) 
            : null,
        stage1AuraRewards: json['stage1AuraRewards'] != null 
            ? Map<String, double>.from(json['stage1AuraRewards']) 
            : {},
      );
}
