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

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.novaBalance = 0.0,
    this.auraBalance = 0.0,
    this.isActive = true,
    this.lastActiveDate,
    this.dormantSince,
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
      );
}
