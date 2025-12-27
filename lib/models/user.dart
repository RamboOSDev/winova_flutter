/// User model for WINOVA app
class User {
  final String id;
  final String username;
  final String displayName;
  double novaBalance;
  double auraBalance;
  bool isActive;
  DateTime? lastActiveDate;
  DateTime? dormantSince;
  
  // Daily voting tracking
  int dailyVotesUsed; // Votes used today (reset daily)
  DateTime? lastVoteDate; // Last vote date to track daily reset
  bool freeVoteUsedToday; // Whether free vote was used today
  DateTime? freeVoteDate; // Date of free vote to track daily reset
  
  // Rank for spotlight eligibility (Marketer, Leader, Manager)
  String? rank;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.novaBalance = 0.0,
    this.auraBalance = 0.0,
    this.isActive = true,
    this.lastActiveDate,
    this.dormantSince,
    this.dailyVotesUsed = 0,
    this.lastVoteDate,
    this.freeVoteUsedToday = false,
    this.freeVoteDate,
    this.rank,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'novaBalance': novaBalance,
        'auraBalance': auraBalance,
        'isActive': isActive,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'dormantSince': dormantSince?.toIso8601String(),
        'dailyVotesUsed': dailyVotesUsed,
        'lastVoteDate': lastVoteDate?.toIso8601String(),
        'freeVoteUsedToday': freeVoteUsedToday,
        'freeVoteDate': freeVoteDate?.toIso8601String(),
        'rank': rank,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'],
        displayName: json['displayName'],
        novaBalance: json['novaBalance'] ?? 0.0,
        auraBalance: json['auraBalance'] ?? 0.0,
        isActive: json['isActive'] ?? true,
        lastActiveDate: json['lastActiveDate'] != null
            ? DateTime.parse(json['lastActiveDate'])
            : null,
        dormantSince: json['dormantSince'] != null
            ? DateTime.parse(json['dormantSince'])
            : null,
        dailyVotesUsed: json['dailyVotesUsed'] ?? 0,
        lastVoteDate: json['lastVoteDate'] != null
            ? DateTime.parse(json['lastVoteDate'])
            : null,
        freeVoteUsedToday: json['freeVoteUsedToday'] ?? false,
        freeVoteDate: json['freeVoteDate'] != null
            ? DateTime.parse(json['freeVoteDate'])
            : null,
        rank: json['rank'],
      );
}
