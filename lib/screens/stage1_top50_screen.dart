import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/contestant.dart';

/// Stage1 Top 50 screen - shows leaderboard
class Stage1Top50Screen extends StatelessWidget {
  const Stage1Top50Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top 50 — Stage1'),
        backgroundColor: Colors.amber,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final contestants = appState.contestants;

          if (contestants.isEmpty) {
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
                      'لا توجد بيانات للعرض',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لم يتم تسجيل أي أصوات بعد',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
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

          // Sort by vote count and take top 50
          final sortedContestants = List<Contestant>.from(contestants)
            ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
          final top50 = sortedContestants.take(50).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: top50.length,
            itemBuilder: (context, index) {
              final contestant = top50[index];
              final rank = index + 1;
              return _buildLeaderboardCard(context, contestant, rank);
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context, Contestant contestant, int rank) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
    } else {
      rankColor = Colors.blue[200]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: rank <= 3 ? 4 : 1,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rankColor,
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
        title: Text(
          contestant.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(contestant.bio),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.how_to_vote, size: 18, color: Colors.grey),
            const SizedBox(height: 2),
            Text(
              '${contestant.voteCount}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
