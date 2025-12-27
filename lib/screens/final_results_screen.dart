import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/contestant.dart';

/// Final Results screen - shows winners and prizes
class FinalResultsScreen extends StatelessWidget {
  const FinalResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النتائج النهائية'),
        backgroundColor: Colors.amber,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final contest = appState.activeContest;
          final contestants = appState.contestants;

          // Empty state
          if (contest == null || !contest.isFinished) {
            return _buildEmptyState(
              context,
              appState,
              title: 'لم تنته المسابقة بعد',
              message: contest == null
                  ? 'لا توجد مسابقة نشطة'
                  : 'المسابقة في مرحلة: ${_getStageName(contest.stage)}',
              showDevButton: true,
            );
          }

          if (contestants.isEmpty) {
            return _buildEmptyState(
              context,
              appState,
              title: 'لا توجد نتائج',
              message: 'لم يتم تسجيل أي متسابقين',
              showDevButton: true,
            );
          }

          // Sort by vote count and get top 5
          final sortedContestants = List<Contestant>.from(contestants)
            ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
          final top5 = sortedContestants.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Trophy header
                Card(
                  color: Colors.amber[50],
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 80,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'الفائزون',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contest.name,
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'إجمالي الجوائز: ${_calculateTotalPrizePool(contest.participantIds.length).toStringAsFixed(1)} نوفا',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Top 5 Winners
                ...top5.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final contestant = entry.value;
                  final prize = _calculatePrize(rank, contest.participantIds.length);
                  
                  return _buildWinnerCard(
                    context,
                    contestant,
                    rank,
                    prize,
                  );
                }),

                const SizedBox(height: 24),

                // Rest of contestants
                if (sortedContestants.length > 5) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'بقية المتسابقين',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...sortedContestants.skip(5).map((contestant) {
                    final rank = sortedContestants.indexOf(contestant) + 1;
                    return _buildOtherContestantCard(context, contestant, rank);
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWinnerCard(
    BuildContext context,
    Contestant contestant,
    int rank,
    double prize,
  ) {
    Color rankColor;
    IconData rankIcon;
    
    switch (rank) {
      case 1:
        rankColor = Colors.amber;
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = Colors.grey[400]!;
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = Colors.brown[300]!;
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.blue[300]!;
        rankIcon = Icons.military_tech;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: rank <= 3 ? 8 : 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: rank == 1
                ? [Colors.amber[100]!, Colors.amber[50]!]
                : rank == 2
                    ? [Colors.grey[200]!, Colors.grey[50]!]
                    : rank == 3
                        ? [Colors.brown[100]!, Colors.brown[50]!]
                        : [Colors.blue[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: rankColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(rankIcon, color: Colors.white, size: 24),
                    Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.how_to_vote, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${contestant.voteCount} صوت',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.card_giftcard, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${prize.toStringAsFixed(1)} نوفا',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
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

  Widget _buildOtherContestantCard(BuildContext context, Contestant contestant, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Text(
            '$rank',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          contestant.displayName,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_vote, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${contestant.voteCount}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
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

            if (showDevButton) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await appState.devFinishNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إنهاء المسابقة'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.emoji_events),
                label: const Text('DEV: إنهاء المسابقة الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalPrizePool(int participantsCount) {
    return participantsCount * 6.0; // 10 entry - 4 platform fee = 6 Nova per participant
  }

  double _calculatePrize(int rank, int participantsCount) {
    final totalPrizePool = _calculateTotalPrizePool(participantsCount);
    final percentages = [0.50, 0.20, 0.12, 0.10, 0.08];
    
    if (rank > 0 && rank <= percentages.length) {
      return totalPrizePool * percentages[rank - 1];
    }
    return 0.0;
  }

  String _getStageName(String stage) {
    switch (stage) {
      case 'preStage':
        return 'ما قبل البداية';
      case 'stage1':
        return 'المرحلة الأولى';
      case 'stage1Top50':
        return 'أفضل 50 - المرحلة الأولى';
      case 'finalStage':
        return 'المرحلة النهائية';
      case 'finished':
        return 'انتهت';
      default:
        return stage;
    }
  }
}
