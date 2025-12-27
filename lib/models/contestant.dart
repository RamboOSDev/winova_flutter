/// Contestant model for contest participants
class Contestant {
  final String id;
  final String userId;
  final String contestId;
  final String displayName;
  final String bio;
  final String? photoUrl;
  final DateTime joinedAt;
  int voteCount;
  String stage; // 'stage1', 'stage2', 'stage3', 'eliminated', 'winner'
  
  // Separate vote tracking
  int stage1Votes; // Votes received in Stage1
  int finalVotes; // Votes received in Final stage
  
  // Aura rewards
  double stage1AuraEarned; // 20% of paid votes in Stage1
  double finalAuraEarned; // 20% of paid votes in Final

  Contestant({
    required this.id,
    required this.userId,
    required this.contestId,
    required this.displayName,
    this.bio = '',
    this.photoUrl,
    DateTime? joinedAt,
    this.voteCount = 0,
    this.stage = 'stage1',
    this.stage1Votes = 0,
    this.finalVotes = 0,
    this.stage1AuraEarned = 0.0,
    this.finalAuraEarned = 0.0,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Contestant copyWith({
    String? id,
    String? userId,
    String? contestId,
    String? displayName,
    String? bio,
    String? photoUrl,
    DateTime? joinedAt,
    int? voteCount,
    String? stage,
    int? stage1Votes,
    int? finalVotes,
    double? stage1AuraEarned,
    double? finalAuraEarned,
  }) {
    return Contestant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contestId: contestId ?? this.contestId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      voteCount: voteCount ?? this.voteCount,
      stage: stage ?? this.stage,
      stage1Votes: stage1Votes ?? this.stage1Votes,
      finalVotes: finalVotes ?? this.finalVotes,
      stage1AuraEarned: stage1AuraEarned ?? this.stage1AuraEarned,
      finalAuraEarned: finalAuraEarned ?? this.finalAuraEarned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'contestId': contestId,
        'displayName': displayName,
        'bio': bio,
        'photoUrl': photoUrl,
        'joinedAt': joinedAt.toIso8601String(),
        'voteCount': voteCount,
        'stage': stage,
        'stage1Votes': stage1Votes,
        'finalVotes': finalVotes,
        'stage1AuraEarned': stage1AuraEarned,
        'finalAuraEarned': finalAuraEarned,
      };

  factory Contestant.fromJson(Map<String, dynamic> json) => Contestant(
        id: json['id'],
        userId: json['userId'],
        contestId: json['contestId'],
        displayName: json['displayName'],
        bio: json['bio'] ?? '',
        photoUrl: json['photoUrl'],
        joinedAt: DateTime.parse(json['joinedAt']),
        voteCount: json['voteCount'] ?? 0,
        stage: json['stage'] ?? 'stage1',
        stage1Votes: json['stage1Votes'] ?? 0,
        finalVotes: json['finalVotes'] ?? 0,
        stage1AuraEarned: json['stage1AuraEarned'] ?? 0.0,
        finalAuraEarned: json['finalAuraEarned'] ?? 0.0,
      );
}
