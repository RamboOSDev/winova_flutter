import '../models/user.dart';
import '../models/contest.dart';
import '../models/contestant.dart';

/// Mock API for WINOVA - simulates backend responses
class MockWinovaApi {
  // In-memory storage
  final Map<String, User> _users = {};
  final Map<String, Contest> _contests = {};
  final Map<String, Contestant> _contestants = {};

  MockWinovaApi() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create a default user
    final defaultUser = User(
      id: 'user_1',
      username: 'testuser',
      displayName: 'Test User',
      novaBalance: 100.0,
      auraBalance: 50.0,
      isActive: true,
      lastActiveDate: DateTime.now(),
    );
    _users[defaultUser.id] = defaultUser;
  }

  // Auth methods
  Future<User?> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _users.values.firstWhere(
      (u) => u.username == username,
      orElse: () => User(
        id: 'user_${_users.length + 1}',
        username: username,
        displayName: username,
        novaBalance: 100.0,
        auraBalance: 50.0,
      ),
    );
    _users[user.id] = user;
    return user;
  }

  Future<User?> signup(String username, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_users.values.any((u) => u.username == username)) {
      throw Exception('Username already exists');
    }
    final user = User(
      id: 'user_${_users.length + 1}',
      username: username,
      displayName: displayName,
      novaBalance: 100.0,
      auraBalance: 50.0,
    );
    _users[user.id] = user;
    return user;
  }

  // Contest methods
  Future<List<Contest>> getActiveContests() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _contests.values.where((c) => c.isActive).toList();
  }

  Future<Contest?> getContestById(String contestId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _contests[contestId];
  }

  Future<Contest> createContest(Contest contest) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _contests[contest.id] = contest;
    return contest;
  }

  Future<Contest> updateContest(Contest contest) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _contests[contest.id] = contest;
    return contest;
  }

  Future<void> clearTodayContest() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final todayContests = _contests.values.where((c) {
      return c.startDate.year == now.year &&
             c.startDate.month == now.month &&
             c.startDate.day == now.day;
    }).toList();
    
    for (final contest in todayContests) {
      _contests.remove(contest.id);
      // Also remove contestants for this contest
      _contestants.removeWhere((key, value) => value.contestId == contest.id);
    }
  }

  // Contestant methods
  Future<List<Contestant>> getContestants(String contestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _contestants.values.where((c) => c.contestId == contestId).toList();
  }

  Future<Contestant> addContestant(Contestant contestant) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _contestants[contestant.id] = contestant;
    
    // Update contest participant list
    final contest = _contests[contestant.contestId];
    if (contest != null) {
      final updatedContest = contest.copyWith(
        participantIds: [...contest.participantIds, contestant.userId],
      );
      _contests[contest.id] = updatedContest;
    }
    
    return contestant;
  }

  Future<void> clearTestContestants(String contestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Remove all dev contestants for this contest
    _contestants.removeWhere((key, value) => 
      value.contestId == contestId && value.id.startsWith('dev_contestant_')
    );
  }

  Future<bool> vote(String contestantId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final contestant = _contestants[contestantId];
    if (contestant == null) return false;
    
    contestant.voteCount++;
    _contestants[contestantId] = contestant;
    return true;
  }

  Future<void> seedVotes(String contestId, bool isFinalStage) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final contestants = _contestants.values.where((c) => c.contestId == contestId).toList();
    
    if (contestants.isEmpty) return;
    
    // Distribute votes with variety
    for (int i = 0; i < contestants.length; i++) {
      final contestant = contestants[i];
      // Create varied vote distribution
      // Top contestants get more votes, rest get less
      int baseVotes = 100 - (i * 4);
      if (baseVotes < 10) baseVotes = 10;
      
      // Add some randomness
      final variation = (i % 5) * 10;
      contestant.voteCount = baseVotes + variation;
      
      _contestants[contestant.id] = contestant;
    }
  }

  // Wallet methods
  Future<bool> convertNovaToAura(String userId, double novaAmount) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final user = _users[userId];
    if (user == null || user.novaBalance < novaAmount) return false;
    
    user.novaBalance -= novaAmount;
    user.auraBalance += novaAmount * 2; // 1 Nova = 2 Aura
    return true;
  }

  Future<bool> deductNova(String userId, double amount) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final user = _users[userId];
    if (user == null || user.novaBalance < amount) return false;
    
    user.novaBalance -= amount;
    return true;
  }

  Future<bool> deductAura(String userId, double amount) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final user = _users[userId];
    if (user == null || user.auraBalance < amount) return false;
    
    user.auraBalance -= amount;
    return true;
  }

  Future<bool> addNova(String userId, double amount) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final user = _users[userId];
    if (user == null) return false;
    
    user.novaBalance += amount;
    return true;
  }

  User? getUser(String userId) => _users[userId];
}
