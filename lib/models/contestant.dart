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
      );
}
