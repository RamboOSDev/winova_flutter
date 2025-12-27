class AppConfig {
  static const bool useMockApi = true;
  static const String apiBaseUrl = 'https://api.winova.com';
  
  // KSA week starts on Saturday
  static const int ksaWeekStartDay = DateTime.saturday;
  
  // Contest timing (KSA timezone - UTC+3)
  // Stage1: 2:00 PM - 8:00 PM (6 hours)
  static const int stage1StartHour = 14; // 2:00 PM
  static const int stage1EndHour = 20; // 8:00 PM
  
  // Final: 8:00 PM - 10:00 PM (120 minutes)
  static const int finalStartHour = 20; // 8:00 PM
  static const int finalEndHour = 22; // 10:00 PM
  
  // Spotlight announcement time
  static const int spotlightAnnouncementHour = 17; // 5:00 PM
  
  // Free Hour (random hour between stage1 start and end)
  // Will be randomly selected daily between 2 PM and 7 PM
  
  // Contest parameters
  static const double entryFeeNova = 6.0; // Entry fee
  static const double voteAuraCost = 1.0; // Cost per vote
  static const int dailyVoteLimit = 100; // Daily vote limit (100 Aura = 100 votes)
  static const double spotlightDeduction = 0.2; // 0.2 Nova per participant
  static const double auraRewardPercentage = 0.2; // 20% of paid votes
  
  // Prize distribution percentages
  static const List<double> prizeDist ribution = [0.50, 0.20, 0.12, 0.10, 0.08]; // Top 5
}
