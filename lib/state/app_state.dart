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

  Future<bool> vote(String contestantId) async {
    if (_currentUser == null || _activeContest == null) return false;
    
    _setLoading(true);
    try {
      // Check Aura balance
      if (_currentUser!.auraBalance < _activeContest!.voteAuraCost) {
        _error = 'Insufficient Aura balance';
        notifyListeners();
        return false;
      }
      
      // Deduct vote cost
      final success = await _api.deductAura(_currentUser!.id, _activeContest!.voteAuraCost);
      if (!success) {
        _error = 'Failed to deduct vote cost';
        notifyListeners();
        return false;
      }
      
      // Cast vote
      await _api.vote(contestantId, _currentUser!.id);
      
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
        name: 'Contest ${now.year}-${now.month}-${now.day}',
        startDate: todayStart,
        endDate: todayEnd,
        stage: 'preStage',
        entryFeeNova: 10.0,
        voteAuraCost: 10.0,
      );
      
      await _api.createContest(todayContest);
      await loadContests();
      
      debugPrint('DEV: Created today contest: ${todayContest.id}');
    }
    
    _activeContest = todayContest;
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
