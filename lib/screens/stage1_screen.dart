import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/contestant.dart';

/// Stage1 voting screen
class Stage1Screen extends StatefulWidget {
  const Stage1Screen({super.key});

  @override
  State<Stage1Screen> createState() => _Stage1ScreenState();
}

class _Stage1ScreenState extends State<Stage1Screen> {
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
        title: const Text('Stage1 — التصويت'),
        backgroundColor: Colors.orange,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final contest = appState.activeContest;
          final contestants = appState.contestants;
          final hasJoined = appState.hasJoinedContest;

          // Handle no contest case
          if (contest == null) {
            return _buildEmptyState(
              context,
              appState,
              title: 'لا توجد مسابقة نشطة',
              message: 'استخدم أدوات DEV لإنشاء مسابقة تجريبية',
              showDevButton: true,
            );
          }

          // Handle wrong stage
          if (!contest.isStage1) {
            return _buildEmptyState(
              context,
              appState,
              title: 'المرحلة الأولى غير نشطة',
              message: 'المسابقة في مرحلة: ${_getStageName(contest.stage)}\n'
                  'استخدم زر "بدء المرحلة الأولى" في DEV Tools',
              showDevButton: true,
            );
          }

          // Handle not joined
          if (!hasJoined) {
            return _buildEmptyState(
              context,
              appState,
              title: 'لم تنضم للمسابقة بعد',
              message: 'يجب الانضمام للمسابقة أولاً للتصويت',
              showJoinButton: true,
            );
          }

          // Handle no contestants
          if (contestants.isEmpty) {
            return _buildEmptyState(
              context,
              appState,
              title: 'لا يوجد متسابقون',
              message: 'استخدم زر "إضافة 20 متسابق وهمي" للاختبار',
              showDevButton: true,
            );
          }

          // Show contestants list for voting
          return _buildVotingList(context, appState, contestants);
        },
      ),
    );
  }

  Widget _buildVotingList(BuildContext context, AppState appState, List<Contestant> contestants) {
    // Sort by vote count descending
    final sortedContestants = List<Contestant>.from(contestants)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return Column(
      children: [
        // Header with info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ابدأ التصويت',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'عدد المتسابقين: ${contestants.length}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              Text(
                'تكلفة التصويت: ${appState.activeContest?.voteAuraCost ?? 1} أورا',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              if (appState.currentUser != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'رصيد الأورا: ${appState.currentUser!.auraBalance.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Contestants list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedContestants.length,
            itemBuilder: (context, index) {
              final contestant = sortedContestants[index];
              return _buildContestantVoteCard(context, appState, contestant, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContestantVoteCard(
    BuildContext context,
    AppState appState,
    Contestant contestant,
    int rank,
  ) {
    final isOwnContestant = appState.currentUser?.id == contestant.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank
            Container(
              width: 36,
              height: 36,
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
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.purple[100],
              child: Text(
                contestant.displayName.substring(0, 1),
                style: const TextStyle(
                  fontSize: 20,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'أنت',
                            style: TextStyle(
                              fontSize: 12,
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.how_to_vote,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${contestant.voteCount} صوت',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Vote button
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: appState.isLoading
                  ? null
                  : () async {
                      final success = await appState.vote(contestant.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'تم التصويت بنجاح!'
                                  : appState.error ?? 'فشل التصويت',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.thumb_up, size: 18),
              label: const Text('صوّت'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppState appState, {
    required String title,
    required String message,
    bool showDevButton = false,
    bool showJoinButton = false,
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
            if (showJoinButton && appState.activeContest != null)
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await appState.joinContest(appState.activeContest!.id);
                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم الانضمام بنجاح!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(appState.error ?? 'فشل الانضمام'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.login),
                label: Text('انضم الآن (${appState.activeContest!.entryFeeNova} نوفا)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

            // DEV buttons
            if (showDevButton) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await appState.devSeedContestants();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم إضافة ${appState.contestants.length} متسابق'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle),
                label: const Text('DEV: إضافة 20 متسابق'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await appState.devStartStage1Now();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم بدء المرحلة الأولى'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('DEV: بدء Stage1'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة للمسابقات'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[300]!;
    return Colors.orange;
  }

  String _getStageName(String stage) {
    switch (stage) {
      case 'preview':
        return 'معاينة';
      case 'stage1':
        return 'المرحلة الأولى';
      case 'stage2':
        return 'المرحلة الثانية';
      case 'stage3':
        return 'المرحلة الثالثة';
      case 'complete':
        return 'مكتملة';
      default:
        return stage;
    }
  }
}
