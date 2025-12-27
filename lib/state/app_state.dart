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
        stage: 'preview',
        entryFeeNova: 10.0,
        voteAuraCost: 1.0,
      );
      
      await _api.createContest(todayContest);
      await loadContests();
      
      debugPrint('DEV: Created today contest: ${todayContest.id}');
    }
    
    _activeContest = todayContest;
    notifyListeners();
    return todayContest;
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
          _currentUser!.novaBalance = 100.0;
        }
        await joinContest(contest.id);
      }
      
      // Clear existing contestants for this contest to avoid duplicates
      _contestants.clear();
      
      // Create 20 mock contestants
      final now = DateTime.now();
      for (int i = 1; i <= 20; i++) {
        final contestant = Contestant(
          id: 'dev_contestant_${now.millisecondsSinceEpoch}_$i',
          userId: 'dev_user_$i',
          contestId: contest.id,
          displayName: 'متسابق $i',
          bio: 'هذا متسابق تجريبي رقم $i للاختبار',
          joinedAt: now.subtract(Duration(hours: i)),
          voteCount: (20 - i) * 5, // Varied vote counts for testing
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
