import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/contestant.dart';
import '../config/app_config.dart';

/// Enhanced Stage1 voting screen with multi-vote support and free hour
class Stage1ScreenNew extends StatefulWidget {
  const Stage1ScreenNew({super.key});

  @override
  State<Stage1ScreenNew> createState() => _Stage1ScreenNewState();
}

class _Stage1ScreenNewState extends State<Stage1ScreenNew> {
  @override
  void initState() {
    super.initState();
    // Load contestants when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.activeContest != null) {
        appState.loadContestants(appState.activeContest!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المرحلة الأولى - التصويت'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final appState = context.read<AppState>();
              if (appState.activeContest != null) {
                appState.loadContestants(appState.activeContest!.id);
              }
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading && appState.contestants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final contest = appState.activeContest;
          final contestants = appState.contestants;
          final hasJoined = appState.hasJoinedContest;

          // Handle no contest case
          if (contest == null) {
            return _buildEmptyState(
              context,
              title: 'لا توجد مسابقة نشطة',
              message: 'استخدم أدوات DEV لإنشاء مسابقة تجريبية',
            );
          }

          // Handle wrong stage
          if (!contest.isStage1 && !contest.isFinalStage) {
            return _buildEmptyState(
              context,
              title: 'مرحلة التصويت غير نشطة',
              message: 'المسابقة في مرحلة: ${_getStageName(contest.stage)}',
            );
          }

          // Handle not joined
          if (!hasJoined) {
            return _buildEmptyState(
              context,
              title: 'لم تنضم للمسابقة بعد',
              message: 'يجب الانضمام للمسابقة أولاً للتصويت',
              showJoinButton: true,
              contest: contest,
            );
          }

          // Handle no contestants
          if (contestants.isEmpty) {
            return _buildEmptyState(
              context,
              title: 'لا يوجد متسابقون',
              message: 'استخدم زر "Seed 20" لإضافة متسابقين تجريبيين',
            );
          }

          // Show contestants list for voting
          return _buildVotingList(context, appState, contestants, contest);
        },
      ),
    );
  }

  Widget _buildVotingList(
    BuildContext context,
    AppState appState,
    List<Contestant> contestants,
    Contest contest,
  ) {
    // Sort by vote count descending
    final sortedContestants = List<Contestant>.from(contestants)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    // Filter by Top50 if in final stage
    final displayContestants = contest.isFinalStage && contest.top50Ids.isNotEmpty
        ? sortedContestants.where((c) => contest.top50Ids.contains(c.id)).toList()
        : sortedContestants;

    return Column(
      children: [
        // Header with info
        _buildHeaderInfo(context, appState, contest, displayContestants.length),

        // Free Hour Banner (only in Stage1)
        if (contest.isStage1 && appState.isFreeHourActive)
          _buildFreeHourBanner(appState),

        // Contestants list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayContestants.length,
            itemBuilder: (context, index) {
              final contestant = displayContestants[index];
              return _buildContestantVoteCard(
                context,
                appState,
                contestant,
                index + 1,
                contest,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo(
    BuildContext context,
    AppState appState,
    Contest contest,
    int contestantsCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: contest.isFinalStage ? Colors.amber[50] : Colors.orange[50],
        border: Border(
          bottom: BorderSide(
            color: contest.isFinalStage ? Colors.amber[200]! : Colors.orange[200]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contest.isFinalStage ? 'النهائي - صوّت لأفضل 50' : 'المرحلة الأولى - صوّت',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: contest.isFinalStage ? Colors.amber[900] : Colors.orange[900],
                ),
          ),
          const SizedBox(height: 12),
          
          // Stats row
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.people,
                label: 'المتسابقين',
                value: '$contestantsCount',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.how_to_vote,
                label: 'أصوات متبقية',
                value: '${appState.remainingVotesToday}',
                color: Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Balance
          if (appState.currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'رصيد الأورا: ${appState.currentUser!.auraBalance.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'التكلفة: ${AppConfig.voteAuraCost} أورا/صوت',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeHourBanner(AppState appState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔥 الساعة المجانية شغالة الآن!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appState.canUseFreeVote
                      ? 'لديك صوت مجاني واحد'
                      : 'استخدمت صوتك المجاني اليوم',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContestantVoteCard(
    BuildContext context,
    AppState appState,
    Contestant contestant,
    int rank,
    Contest contest,
  ) {
    final isOwnContestant = appState.currentUser?.id == contestant.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: rank <= 3 ? _getRankColor(rank).withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Open profile when tapping on card/avatar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('افتح بروفايل ${contestant.displayName} - قريبًا'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRankColor(rank),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.purple[100],
                child: Text(
                  contestant.displayName.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contestant.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isOwnContestant)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'أنت',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contestant.bio,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.how_to_vote,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${contestant.voteCount} صوت',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (contest.isStage1) ...[
                          const SizedBox(width: 12),
                          Text(
                            'Stage1: ${contestant.stage1Votes}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                        if (contest.isFinalStage) ...[
                          const SizedBox(width: 12),
                          Text(
                            'Final: ${contestant.finalVotes}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Vote button
              const SizedBox(width: 12),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: appState.isLoading
                        ? null
                        : () => _showVoteModal(
                              context,
                              appState,
                              contestant,
                              contest,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'صوّت',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoteModal(
    BuildContext context,
    AppState appState,
    Contestant contestant,
    Contest contest,
  ) {
    final canUseFree = appState.canUseFreeVote && contest.isStage1;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VoteModal(
        contestant: contestant,
        appState: appState,
        canUseFreeVote: canUseFree,
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[300]!;
    if (rank <= 10) return Colors.orange[300]!;
    return Colors.blue[200]!;
  }

  String _getStageName(String stage) {
    switch (stage) {
      case 'preStage':
        return 'ما قبل البداية';
      case 'stage1':
        return 'المرحلة الأولى';
      case 'stage1Top50':
        return 'أفضل 50';
      case 'finalStage':
        return 'المرحلة النهائية';
      case 'finished':
        return 'انتهت';
      default:
        return stage;
    }
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String message,
    bool showJoinButton = false,
    Contest? contest,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Join button
            if (showJoinButton && contest != null)
              ElevatedButton.icon(
                onPressed: () async {
                  final appState = context.read<AppState>();
                  final success = await appState.joinContest(contest.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'تم الاشتراك بنجاح!' : appState.error ?? 'فشل الاشتراك',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.login),
                label: Text('اشترك الآن (${contest.entryFeeNova} نوفا)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vote Modal - allows selecting vote count and free vote
class _VoteModal extends StatefulWidget {
  final Contestant contestant;
  final AppState appState;
  final bool canUseFreeVote;

  const _VoteModal({
    required this.contestant,
    required this.appState,
    required this.canUseFreeVote,
  });

  @override
  State<_VoteModal> createState() => _VoteModalState();
}

class _VoteModalState extends State<_VoteModal> {
  int _voteCount = 1;
  bool _useFreeVote = false;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    // Default to free vote if available
    _useFreeVote = widget.canUseFreeVote;
  }

  double get _totalCost {
    if (_useFreeVote) return 0.0;
    return _voteCount * AppConfig.voteAuraCost;
  }

  int get _maxVotes {
    if (_useFreeVote) return 1;
    final remaining = widget.appState.remainingVotesToday;
    final canAfford = (widget.appState.currentUser?.auraBalance ?? 0) ~/ AppConfig.voteAuraCost;
    return [remaining, canAfford, 50].reduce((a, b) => a < b ? a : b); // Max 50 at once
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'صوّت لـ ${widget.contestant.displayName}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Free vote option
          if (widget.canUseFreeVote)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useFreeVote ? Colors.red : Colors.red[200]!,
                  width: _useFreeVote ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _useFreeVote,
                    onChanged: (value) {
                      setState(() {
                        _useFreeVote = value ?? false;
                        if (_useFreeVote) {
                          _voteCount = 1;
                        }
                      });
                    },
                    activeColor: Colors.red,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.red, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'استخدم التصويت المجاني',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'صوت واحد مجاني خلال الساعة المجانية',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          if (widget.canUseFreeVote) const SizedBox(height: 20),
          
          // Vote count selector
          if (!_useFreeVote) ...[
            Text(
              'عدد الأصوات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Slider
            Row(
              children: [
                IconButton(
                  onPressed: _voteCount > 1
                      ? () => setState(() => _voteCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle),
                  color: Colors.orange,
                  iconSize: 32,
                ),
                Expanded(
                  child: Slider(
                    value: _voteCount.toDouble(),
                    min: 1,
                    max: _maxVotes.toDouble(),
                    divisions: _maxVotes > 1 ? _maxVotes - 1 : 1,
                    activeColor: Colors.orange,
                    label: '$_voteCount',
                    onChanged: (value) {
                      setState(() {
                        _voteCount = value.toInt();
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: _voteCount < _maxVotes
                      ? () => setState(() => _voteCount++)
                      : null,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.orange,
                  iconSize: 32,
                ),
              ],
            ),
            
            // Vote count display
            Center(
              child: Text(
                '$_voteCount ${_voteCount == 1 ? "صوت" : "أصوات"}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Quick select buttons
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [1, 5, 10, 20, 50]
                  .where((n) => n <= _maxVotes)
                  .map((n) => OutlinedButton(
                        onPressed: () => setState(() => _voteCount = n),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _voteCount == n ? Colors.white : Colors.orange,
                          backgroundColor: _voteCount == n ? Colors.orange : null,
                          side: BorderSide(color: Colors.orange),
                        ),
                        child: Text('$n'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          
          // Cost display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'التكلفة:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  _useFreeVote ? 'مجاني 🔥' : '${_totalCost.toStringAsFixed(1)} أورا',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _useFreeVote ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Vote button
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isVoting ? null : _handleVote,
              icon: _isVoting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.how_to_vote, size: 24),
              label: Text(
                _isVoting ? 'جاري التصويت...' : 'صوّت الآن',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Cancel button
          TextButton(
            onPressed: _isVoting ? null : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Future<void> _handleVote() async {
    setState(() => _isVoting = true);
    
    try {
      final success = await widget.appState.vote(
        widget.contestant.id,
        voteCount: _voteCount,
        useFreeVote: _useFreeVote,
      );
      
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? _useFreeVote
                      ? '✅ تم استخدام التصويت المجاني بنجاح!'
                      : '✅ تم التصويت بـ $_voteCount ${_voteCount == 1 ? "صوت" : "أصوات"} بنجاح!'
                  : widget.appState.error ?? 'فشل التصويت',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }
}
