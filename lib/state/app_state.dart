import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/contest.dart';
import '../models/contestant.dart';
import '../api/mock_winova_api.dart';
import '../config/app_config.dart';

/// Main application state with Provider pattern
class AppState with ChangeNotifier {
  final MockWinovaApi _api = MockWinovaApi();

  User? _currentUser;
  List<Contest> _contests = [];
  List<Contestant> _contestants = [];
  Contest? _activeContest;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  List<Contest> get contests => _contests;
  List<Contestant> get contestants => _contestants;
  Contest? get activeContest => _activeContest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  
  // Online counter (mock - simulates active users)
  int _onlineUsersCount = 0;
  int get onlineUsersCount => _onlineUsersCount;
  
  // Timer support for live updates
  DateTime? _lastUpdateTime;
  
  // Check if it's free hour
  bool get isFreeHourActive {
    if (_activeContest == null) return false;
    final now = DateTime.now();
    if (_activeContest!.freeHourStart != null && _activeContest!.freeHourEnd != null) {
      return now.isAfter(_activeContest!.freeHourStart!) && 
             now.isBefore(_activeContest!.freeHourEnd!);
    }
    return false;
  }
  
  // Check if free hour is announced (has times set)
  bool get isFreeHourAnnounced {
    return _activeContest?.freeHourStart != null;
  }
  
  // Check if free hour has passed
  bool get isFreeHourPassed {
    if (_activeContest == null || _activeContest!.freeHourEnd == null) return false;
    return DateTime.now().isAfter(_activeContest!.freeHourEnd!);
  }
  
  // Check if spotlight is announced
  bool get isSpotlightAnnounced {
    if (_activeContest == null) return false;
    final now = DateTime.now();
    if (_activeContest!.spotlightAnnouncementTime != null) {
      return now.isAfter(_activeContest!.spotlightAnnouncementTime!);
    }
    return false;
  }
  
  // Calculate spotlight prize
  double get spotlightPrize {
    if (_activeContest == null) return 0.0;
    return _activeContest!.participantIds.length * AppConfig.spotlightDeduction;
  }
  
  // Calculate remaining votes for today
  int get remainingVotesToday {
    if (_currentUser == null) return 0;
    final user = _currentUser!;
    
    // Check if we need to reset daily counter
    final now = DateTime.now();
    if (user.lastVoteDate == null || 
        !_isSameDay(user.lastVoteDate!, now)) {
      return AppConfig.dailyVoteLimit;
    }
    
    return AppConfig.dailyVoteLimit - user.dailyVotesUsed;
  }
  
  // Check if user can use free vote
  bool get canUseFreeVote {
    if (_currentUser == null || !isFreeHourActive) return false;
    
    final user = _currentUser!;
    final now = DateTime.now();
    
    // Check if free vote was already used today
    if (user.freeVoteDate != null && _isSameDay(user.freeVoteDate!, now)) {
      return !user.freeVoteUsedToday;
    }
    
    return true;
  }
  
  // Helper to check if two dates are same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Check if current user has joined the active contest
  bool get hasJoinedContest {
    if (_currentUser == null || _activeContest == null) return false;
    return _activeContest!.participantIds.contains(_currentUser!.id);
  }

  // Auth methods
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    try {
      final user = await _api.login(username, password);
      _currentUser = user;
      _error = null;
      notifyListeners();
      
      // Load contests after login
      await loadContests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signup(String username, String password, String displayName) async {
    _setLoading(true);
    try {
      final user = await _api.signup(username, password, displayName);
      _currentUser = user;
      _error = null;
      notifyListeners();
      
      // Load contests after signup
      await loadContests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _currentUser = null;
    _contests = [];
    _contestants = [];
    _activeContest = null;
    _error = null;
    notifyListeners();
  }

  // Contest methods
  Future<void> loadContests() async {
    _setLoading(true);
    try {
      _contests = await _api.getActiveContests();
      
      // Set active contest to today's contest if exists
      final now = DateTime.now();
      _activeContest = _contests.where((c) {
        return c.startDate.year == now.year &&
               c.startDate.month == now.month &&
               c.startDate.day == now.day;
      }).firstOrNull;
      
      // Load contestants for active contest
      if (_activeContest != null) {
        await loadContestants(_activeContest!.id);
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading contests: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadContestants(String contestId) async {
    try {
      _contestants = await _api.getContestants(contestId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading contestants: $e');
      notifyListeners();
    }
  }

  Future<bool> joinContest(String contestId) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    try {
      final contest = _contests.firstWhere((c) => c.id == contestId);
      
      // Check balance
      if (_currentUser!.novaBalance < contest.entryFeeNova) {
        _error = 'Insufficient Nova balance';
        notifyListeners();
        return false;
      }
      
      // Deduct entry fee
      final success = await _api.deductNova(_currentUser!.id, contest.entryFeeNova);
      if (!success) {
        _error = 'Failed to deduct entry fee';
        notifyListeners();
        return false;
      }
      
      // Create contestant
      final contestant = Contestant(
        id: 'contestant_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.id,
        contestId: contestId,
        displayName: _currentUser!.displayName,
        bio: 'Contestant ${_currentUser!.displayName}',
        joinedAt: DateTime.now(),
      );
      
      await _api.addContestant(contestant);
      
      // Reload data
      await loadContests();
      await loadContestants(contestId);
      
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error joining contest: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Vote for a contestant
  /// 
  /// Enhanced voting with support for:
  /// - Multiple votes at once (voteCount parameter)
  /// - Free vote during Free Hour (useFreeVote parameter)
  /// - Daily limit tracking (100 votes per day)
  /// - Balance verification
  /// 
  /// Note: This is an enhanced version of the vote method that maintains
  /// backward compatibility through optional named parameters.
  Future<bool> vote(String contestantId, {int voteCount = 1, bool useFreeVote = false}) async {
    if (_currentUser == null || _activeContest == null) return false;
    
    _setLoading(true);
    try {
      // Check if using free vote
      if (useFreeVote) {
        if (!canUseFreeVote) {
          _error = 'لا يمكنك استخدام التصويت المجاني الآن';
          notifyListeners();
          return false;
        }
        
        // Use free vote (no Aura deduction)
        await _api.vote(contestantId, _currentUser!.id, voteCount: 1, isFreeVote: true);
        
        // Mark free vote as used
        _currentUser!.freeVoteUsedToday = true;
        _currentUser!.freeVoteDate = DateTime.now();
        
        // Reload contestants
        await loadContestants(_activeContest!.id);
        
        _error = null;
        notifyListeners();
        return true;
      }
      
      // Regular paid voting
      final totalCost = _activeContest!.voteAuraCost * voteCount;
      
      // Check daily limit
      final now = DateTime.now();
      if (_currentUser!.lastVoteDate != null && 
          _isSameDay(_currentUser!.lastVoteDate!, now)) {
        // Same day - check limit
        if (_currentUser!.dailyVotesUsed + voteCount > AppConfig.dailyVoteLimit) {
          _error = 'تجاوزت الحد اليومي للتصويت (${AppConfig.dailyVoteLimit} صوت)';
          notifyListeners();
          return false;
        }
      } else {
        // New day - reset counter
        _currentUser!.dailyVotesUsed = 0;
      }
      
      // Check Aura balance
      if (_currentUser!.auraBalance < totalCost) {
        _error = 'رصيد الأورا غير كافي';
        notifyListeners();
        return false;
      }
      
      // Deduct vote cost
      final success = await _api.deductAura(_currentUser!.id, totalCost);
      if (!success) {
        _error = 'فشل خصم تكلفة التصويت';
        notifyListeners();
        return false;
      }
      
      // Update daily votes
      _currentUser!.dailyVotesUsed += voteCount;
      _currentUser!.lastVoteDate = now;
      
      // Cast vote
      await _api.vote(contestantId, _currentUser!.id, voteCount: voteCount);
      
      // Reload contestants
      await loadContestants(_activeContest!.id);
      
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error voting: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Wallet methods
  Future<bool> convertNovaToAura(double novaAmount) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    try {
      final success = await _api.convertNovaToAura(_currentUser!.id, novaAmount);
      if (success) {
        // Refresh user data
        final updatedUser = _api.getUser(_currentUser!.id);
        if (updatedUser != null) {
          _currentUser = updatedUser;
        }
        _error = null;
      } else {
        _error = 'Insufficient Nova balance';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error converting Nova to Aura: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Online counter and timing methods
  
  /// Start simulating online users counter (updates every 5 seconds)
  void startOnlineCounterSimulation() {
    _updateOnlineCounter();
    // In a real app, this would be a Timer.periodic
    // For now, we'll update it manually when needed
  }
  
  /// Update online counter with simulated value
  void _updateOnlineCounter() {
    // Simulate online users (random between 50-200)
    final baseCount = 100;
    final variation = (DateTime.now().second % 20) - 10;
    _onlineUsersCount = baseCount + variation;
    _lastUpdateTime = DateTime.now();
    notifyListeners();
  }
  
  /// Get time remaining for current stage in seconds
  int? getStageTimeRemaining() {
    if (_activeContest == null) return null;
    
    final now = DateTime.now();
    final contest = _activeContest!;
    
    switch (contest.stage) {
      case 'preStage':
        if (contest.stage1StartTime != null) {
          return contest.stage1StartTime!.difference(now).inSeconds;
        }
        break;
      case 'stage1':
        if (contest.stage1EndTime != null) {
          return contest.stage1EndTime!.difference(now).inSeconds;
        }
        break;
      case 'stage1Top50':
        if (contest.finalStartTime != null) {
          return contest.finalStartTime!.difference(now).inSeconds;
        }
        break;
      case 'finalStage':
        if (contest.finalEndTime != null) {
          return contest.finalEndTime!.difference(now).inSeconds;
        }
        break;
    }
    
    return null;
  }
  
  /// Format seconds to HH:MM:SS
  String formatTimeRemaining(int seconds) {
    if (seconds < 0) seconds = 0;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  /// Initialize contest timing (call when creating a contest)
  Contest _initializeContestTiming(Contest contest) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Set stage times
    final stage1Start = today.add(Duration(hours: AppConfig.stage1StartHour));
    final stage1End = today.add(Duration(hours: AppConfig.stage1EndHour));
    final finalStart = today.add(Duration(hours: AppConfig.finalStartHour));
    final finalEnd = today.add(Duration(hours: AppConfig.finalEndHour));
    
    // Set spotlight announcement time
    final spotlightTime = today.add(Duration(hours: AppConfig.spotlightAnnouncementHour));
    
    // Generate random free hour (between 2 PM and 7 PM)
    final freeHourStart = _generateRandomFreeHour(today);
    final freeHourEnd = freeHourStart.add(const Duration(hours: 1));
    
    return contest.copyWith(
      stage1StartTime: stage1Start,
      stage1EndTime: stage1End,
      finalStartTime: finalStart,
      finalEndTime: finalEnd,
      freeHourStart: freeHourStart,
      freeHourEnd: freeHourEnd,
      spotlightAnnouncementTime: spotlightTime,
      entryFeeNova: AppConfig.entryFeeNova,
      voteAuraCost: AppConfig.voteAuraCost,
    );
  }
  
  /// Generate random free hour between stage1 start and end
  DateTime _generateRandomFreeHour(DateTime today) {
    // Random hour between 2 PM (14) and 7 PM (19)
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final randomHour = 14 + (seed % 5); // Will give consistent hour for same day
    return today.add(Duration(hours: randomHour));
  }
  
  /// Select random spotlight winner from eligible users
  Future<void> _selectSpotlightWinner() async {
    if (_activeContest == null) return;
    
    // Get all participants
    final participants = _contestants
        .where((c) => c.contestId == _activeContest!.id)
        .toList();
    
    if (participants.isEmpty) return;
    
    // In a real app, filter by rank (Marketer, Leader, Manager)
    // For now, select randomly from all participants
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final winnerIndex = seed % participants.length;
    final winner = participants[winnerIndex];
    
    // Calculate spotlight prize
    final prize = spotlightPrize;
    
    // Update contest with spotlight winner
    final updatedContest = _activeContest!.copyWith(
      spotlightUserId: winner.userId,
      spotlightPrize: prize,
    );
    
    await _api.updateContest(updatedContest);
    
    // Award prize to winner
    await _api.addNova(winner.userId, prize);
    
    _activeContest = updatedContest;
    notifyListeners();
    
    debugPrint('Spotlight winner selected: ${winner.displayName} (${prize.toStringAsFixed(1)} Nova)');
  }

  // DEV methods for testing
  
  /// DEV: Create or get today's contest
  Future<Contest> devEnsureTodayContest() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    // Check if today's contest already exists
    Contest? todayContest = _contests.where((c) {
      return c.startDate.year == now.year &&
             c.startDate.month == now.month &&
             c.startDate.day == now.day;
    }).firstOrNull;
    
    if (todayContest == null) {
      // Create today's contest
      todayContest = Contest(
        id: 'contest_${now.millisecondsSinceEpoch}',
        name: 'مسابقة ${now.day}/${now.month}/${now.year}',
        startDate: todayStart,
        endDate: todayEnd,
        stage: 'preStage',
      );
      
      // Initialize timing
      todayContest = _initializeContestTiming(todayContest);
      
      await _api.createContest(todayContest);
      await loadContests();
      
      debugPrint('DEV: Created today contest: ${todayContest.id}');
    }
    
    _activeContest = todayContest;
    
    // Start online counter simulation
    startOnlineCounterSimulation();
    
    notifyListeners();
    return todayContest;
  }

  /// DEV: Reset day - clear today's contest and all related data
  Future<void> devResetDay() async {
    debugPrint('DEV: Resetting day');
    
    _setLoading(true);
    try {
      // Clear today's contest
      await _api.clearTodayContest();
      
      // Reload data
      _contests = [];
      _contestants = [];
      _activeContest = null;
      
      debugPrint('DEV: Day reset complete');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error resetting day: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Create today's contest explicitly
  Future<void> devCreateTodayContest() async {
    debugPrint('DEV: Creating today contest');
    
    _setLoading(true);
    try {
      await devEnsureTodayContest();
      _error = null;
      debugPrint('DEV: Today contest created');
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error creating today contest: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Seed 20 mock contestants for testing
  Future<void> devSeedContestants() async {
    debugPrint('DEV: Starting devSeedContestants');
    
    _setLoading(true);
    try {
      // Ensure today's contest exists
      final contest = await devEnsureTodayContest();
      debugPrint('DEV: Contest ensured: ${contest.id}');
      
      // Ensure current user has joined
      if (_currentUser != null && !hasJoinedContest) {
        debugPrint('DEV: Current user joining contest');
        // Give user enough Nova if needed
        if (_currentUser!.novaBalance < contest.entryFeeNova) {
          _currentUser!.novaBalance = 1000.0;
          _currentUser!.auraBalance = 1000.0;
        }
        await joinContest(contest.id);
      }
      
      // Clear existing test contestants for this contest to avoid duplicates
      await _api.clearTestContestants(contest.id);
      
      // Create 20 mock contestants
      final now = DateTime.now();
      for (int i = 1; i <= 20; i++) {
        final contestant = Contestant(
          id: 'dev_contestant_${contest.id}_$i',
          userId: 'dev_user_$i',
          contestId: contest.id,
          displayName: 'متسابق $i',
          bio: 'هذا متسابق تجريبي رقم $i للاختبار',
          joinedAt: now.subtract(Duration(hours: i)),
          voteCount: 0, // Start with 0, will be set by seed votes
          stage: 'stage1',
        );
        
        await _api.addContestant(contestant);
        debugPrint('DEV: Added contestant $i: ${contestant.id}');
      }
      
      // Reload contestants to update UI
      await loadContestants(contest.id);
      
      _error = null;
      debugPrint('DEV: Successfully seeded ${_contestants.length} contestants');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error seeding contestants: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Seed votes for contestants
  Future<void> devSeedVotes({bool isFinalStage = false}) async {
    debugPrint('DEV: Seeding votes (finalStage: $isFinalStage)');
    
    _setLoading(true);
    try {
      final contest = _activeContest;
      if (contest == null) {
        throw Exception('No active contest');
      }
      
      // Seed votes using API
      await _api.seedVotes(contest.id, isFinalStage);
      
      // Reload contestants to show updated vote counts
      await loadContestants(contest.id);
      
      _error = null;
      debugPrint('DEV: Votes seeded successfully');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error seeding votes: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Start Stage1 voting immediately
  Future<void> devStartStage1Now() async {
    debugPrint('DEV: Starting Stage1');
    
    _setLoading(true);
    try {
      // Ensure today's contest exists
      final contest = await devEnsureTodayContest();
      
      // Update contest stage to stage1
      final updatedContest = contest.copyWith(stage: 'stage1');
      await _api.updateContest(updatedContest);
      
      // Reload contests
      await loadContests();
      
      _error = null;
      debugPrint('DEV: Contest stage updated to stage1');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error starting stage1: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Freeze Top50 - move to stage1Top50
  Future<void> devFreezeTop50Now() async {
    debugPrint('DEV: Freezing Top50');
    
    _setLoading(true);
    try {
      final contest = _activeContest;
      if (contest == null) {
        throw Exception('No active contest');
      }
      
      // Get top 50 contestants by vote count
      final sortedContestants = List<Contestant>.from(_contestants)
        ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
      final top50 = sortedContestants.take(50).toList();
      final top50Ids = top50.map((c) => c.id).toList();
      
      // Update contest stage and save top50
      final updatedContest = contest.copyWith(
        stage: 'stage1Top50',
        top50Ids: top50Ids,
      );
      await _api.updateContest(updatedContest);
      
      // Reload contests
      await loadContests();
      
      _error = null;
      debugPrint('DEV: Top50 frozen with ${top50Ids.length} contestants');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error freezing top50: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Start Final stage immediately
  Future<void> devStartFinalNow() async {
    debugPrint('DEV: Starting Final Stage');
    
    _setLoading(true);
    try {
      final contest = _activeContest;
      if (contest == null) {
        throw Exception('No active contest');
      }
      
      // Ensure top50 is set
      if (contest.top50Ids.isEmpty) {
        await devFreezeTop50Now();
        return; // devFreezeTop50Now will reload and notify
      }
      
      // Update contest stage to finalStage
      final updatedContest = contest.copyWith(stage: 'finalStage');
      await _api.updateContest(updatedContest);
      
      // Reload contests
      await loadContests();
      
      _error = null;
      debugPrint('DEV: Contest stage updated to finalStage');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error starting final stage: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Finish contest and calculate winners
  Future<void> devFinishNow() async {
    debugPrint('DEV: Finishing contest');
    
    _setLoading(true);
    try {
      final contest = _activeContest;
      if (contest == null) {
        throw Exception('No active contest');
      }
      
      // Get final top 5 from contestants
      final sortedContestants = List<Contestant>.from(_contestants)
        ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
      final top5 = sortedContestants.take(5).toList();
      
      // Calculate prizes
      final totalPrizePool = contest.participantIds.length * 6.0; // 10 entry - 4 platform fee = 6 Nova per participant
      final prizes = <String, double>{};
      
      if (top5.isNotEmpty) {
        final percentages = [0.50, 0.20, 0.12, 0.10, 0.08]; // Top 5 distribution
        for (int i = 0; i < top5.length && i < 5; i++) {
          prizes[top5[i].userId] = totalPrizePool * percentages[i];
        }
      }
      
      // Update contest with winners and mark as finished
      final updatedContest = contest.copyWith(
        stage: 'finished',
        winnerPrizes: prizes,
      );
      await _api.updateContest(updatedContest);
      
      // Distribute prizes
      for (final entry in prizes.entries) {
        await _api.addNova(entry.key, entry.value);
      }
      
      // Reload contests
      await loadContests();
      
      _error = null;
      debugPrint('DEV: Contest finished with ${prizes.length} winners');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error finishing contest: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Open Full Flow - complete end-to-end setup
  Future<void> devOpenFullFlow() async {
    debugPrint('DEV: Starting Full Flow');
    
    _setLoading(true);
    try {
      // 1. Reset day
      await _api.clearTodayContest();
      _contests = [];
      _contestants = [];
      _activeContest = null;
      
      // 2. Create today contest
      await devEnsureTodayContest();
      
      // 3. Seed contestants (20)
      await devSeedContestants();
      
      // 4. Set stage to Stage1
      await devStartStage1Now();
      
      // 5. Seed votes
      await devSeedVotes(isFinalStage: false);
      
      // 6. Freeze top50
      await devFreezeTop50Now();
      
      // 7. Set stage to Final
      await devStartFinalNow();
      
      // 8. Seed final votes
      await devSeedVotes(isFinalStage: true);
      
      // 9. Finish results
      await devFinishNow();
      
      _error = null;
      debugPrint('DEV: Full Flow completed successfully');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('DEV: Error in full flow: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// DEV: Give current user extra funds for testing
  void devAddFunds({double nova = 100.0, double aura = 100.0}) {
    if (_currentUser != null) {
      _currentUser!.novaBalance += nova;
      _currentUser!.auraBalance += aura;
      debugPrint('DEV: Added $nova Nova and $aura Aura to current user');
      notifyListeners();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Extension to get firstOrNull
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
