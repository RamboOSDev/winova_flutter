import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/contestant.dart';
import '../config/app_config.dart';

/// Enhanced Stage1 Top 50 screen - shows leaderboard with Stage1 stats
class Stage1Top50ScreenNew extends StatelessWidget {
  const Stage1Top50ScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أفضل 50 - المرحلة الأولى'),
        backgroundColor: Colors.cyan,
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
          final contest = appState.activeContest;
          final contestants = appState.contestants;

          if (appState.isLoading && contestants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (contest == null) {
            return _buildEmptyState(
              context,
              title: 'لا توجد مسابقة نشطة',
              message: 'استخدم أدوات DEV لإنشاء مسابقة',
            );
          }

          if (contestants.isEmpty) {
            return _buildEmptyState(
              context,
              title: 'لا توجد بيانات للعرض',
              message: 'لم يتم تسجيل أي أصوات بعد',
            );
          }

          // Sort by vote count and take top 50
          final sortedContestants = List<Contestant>.from(contestants)
            ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
          final top50 = sortedContestants.take(50).toList();

          return Column(
            children: [
              // Header
              _buildHeader(context, contest, top50.length),
              
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: top50.length,
                  itemBuilder: (context, index) {
                    final contestant = top50[index];
                    final rank = index + 1;
                    return _buildLeaderboardCard(context, contestant, rank, contest);
                  },
                ),
              ),
              
              // Bottom action
              if (contest.isFinalStage || contest.isFinished)
                _buildBottomAction(context, contest),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Contest contest, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan[700]!, Colors.cyan[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.leaderboard,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أفضل 50 متسابق',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المتأهلون للمرحلة النهائية',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.people,
                  label: 'المتأهلون',
                  value: '$count',
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildStatItem(
                  icon: Icons.how_to_vote,
                  label: 'المرحلة',
                  value: 'Stage1',
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildStatItem(
                  icon: Icons.flag,
                  label: 'التالي',
                  value: contest.isFinalStage ? 'نشط' : 'قريبًا',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(
    BuildContext context,
    Contestant contestant,
    int rank,
    Contest contest,
  ) {
    final isTopThree = rank <= 3;
    final rankColor = _getRankColor(rank);
    
    // Calculate Stage1 Aura earned (20% of Stage1 votes)
    // Assuming 1 vote = 1 Aura paid
    final stage1AuraEarned = contestant.stage1Votes * AppConfig.auraRewardPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTopThree ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTopThree
            ? BorderSide(color: rankColor.withOpacity(0.3), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          // TODO: Open profile
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
                width: isTopThree ? 50 : 44,
                height: isTopThree ? 50 : 44,
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                  boxShadow: isTopThree
                      ? [
                          BoxShadow(
                            color: rankColor.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isTopThree)
                      Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 20,
                      ),
                    Text(
                      '$rank',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isTopThree ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Avatar
              CircleAvatar(
                radius: isTopThree ? 32 : 28,
                backgroundColor: Colors.purple[100],
                child: Text(
                  contestant.displayName.substring(0, 1),
                  style: TextStyle(
                    fontSize: isTopThree ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contestant.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTopThree ? 17 : 15,
                      ),
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
                    
                    // Stats
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildStatChip(
                          icon: Icons.how_to_vote,
                          label: '${contestant.stage1Votes} صوت',
                          color: Colors.orange,
                        ),
                        _buildStatChip(
                          icon: Icons.stars,
                          label: '${stage1AuraEarned.toStringAsFixed(1)} أورا',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Qualified badge
              if (rank <= 50)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'متأهل',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, Contest contest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              if (contest.isFinalStage) {
                // Go to final voting
                Navigator.pushNamed(context, '/stage1'); // Reuse Stage1 screen
              } else {
                // Show message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('المرحلة النهائية ستبدأ قريبًا'),
                  ),
                );
              }
            },
            icon: Icon(
              contest.isFinalStage ? Icons.flag : Icons.schedule,
              size: 24,
            ),
            label: Text(
              contest.isFinalStage ? 'ادخل النهائي وصوّت' : 'باقي على النهائي',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: contest.isFinalStage ? Colors.amber : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[300]!;
    if (rank <= 10) return Colors.orange[300]!;
    if (rank <= 25) return Colors.blue[300]!;
    return Colors.cyan[200]!;
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
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
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final appState = context.read<AppState>();
                await appState.devFreezeTop50Now();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تجميد أفضل 50'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.ac_unit),
              label: const Text('DEV: تجميد أفضل 50 الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
