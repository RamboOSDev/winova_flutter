import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/contestant.dart';
import 'stage1_screen.dart';

/// Contests screen with preview functionality
class ContestsScreen extends StatefulWidget {
  const ContestsScreen({super.key});

  @override
  State<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends State<ContestsScreen> {
  @override
  void initState() {
    super.initState();
    // Load contests when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.loadContests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المسابقات'),
        backgroundColor: Colors.purple,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final contest = appState.activeContest;
          final contestants = appState.contestants;
          final hasJoined = appState.hasJoinedContest;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contest info card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contest?.name ?? 'لا توجد مسابقة نشطة اليوم',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        if (contest != null) ...[
                          Text('المرحلة: ${_getStageName(contest.stage)}'),
                          const SizedBox(height: 4),
                          Text('عدد المتسابقين: ${contestants.length}'),
                          const SizedBox(height: 4),
                          Text(
                            hasJoined ? '✓ أنت مشترك في المسابقة' : 'لم تنضم بعد',
                            style: TextStyle(
                              color: hasJoined ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            'لا توجد مسابقة نشطة اليوم. استخدم أدوات DEV لإنشاء مسابقة تجريبية.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                if (contest != null) ...[
                  // Join contest button
                  if (!hasJoined)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success = await appState.joinContest(contest.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'تم الانضمام للمسابقة بنجاح!'
                                    : appState.error ?? 'فشل الانضمام',
                              ),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: Text('انضم للمسابقة (${contest.entryFeeNova} نوفا)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Preview contestants button
                  OutlinedButton.icon(
                    onPressed: () {
                      _showContestantsPreview(context, appState);
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('عرض المتسابقين (Preview)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Stage1 voting button
                  if (contest.isStage1)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Stage1Screen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.how_to_vote),
                      label: const Text('Stage1 — التصويت'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                  if (!contest.isStage1)
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock),
                      label: Text('Stage1 — ${_getStageName(contest.stage)}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                // DEV Tools section
                const Divider(),
                Text(
                  'أدوات DEV للاختبار',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // DEV seed contestants
                ElevatedButton.icon(
                  onPressed: appState.isLoading
                      ? null
                      : () async {
                          await appState.devSeedContestants();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم إضافة ${appState.contestants.length} متسابق وهمي',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.add_circle),
                  label: const Text('إضافة 20 متسابق وهمي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 8),

                // DEV start stage1
                ElevatedButton.icon(
                  onPressed: appState.isLoading
                      ? null
                      : () async {
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
                  label: const Text('بدء المرحلة الأولى (Stage1)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 8),

                // DEV add funds
                ElevatedButton.icon(
                  onPressed: () {
                    appState.devAddFunds(nova: 100, aura: 100);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إضافة 100 نوفا و 100 أورا'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.attach_money),
                  label: const Text('إضافة أموال تجريبية (100+100)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 16),

                // User balance display
                if (appState.currentUser != null) ...[
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رصيدك الحالي:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text('نوفا: ${appState.currentUser!.novaBalance.toStringAsFixed(1)}'),
                          Text('أورا: ${appState.currentUser!.auraBalance.toStringAsFixed(1)}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
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

  void _showContestantsPreview(BuildContext context, AppState appState) {
    final contestants = appState.contestants;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المتسابقون (${contestants.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Content
                  Expanded(
                    child: contestants.isEmpty
                        ? _buildEmptyState(context, appState)
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: contestants.length,
                            itemBuilder: (context, index) {
                              return _buildContestantCard(contestants[index]);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد متسابقون بعد',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'استخدم زر "إضافة 20 متسابق وهمي" للاختبار',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await appState.devSeedContestants();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم إضافة ${appState.contestants.length} متسابق وهمي',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('إضافة متسابقين الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContestantCard(Contestant contestant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[100],
          child: Text(
            contestant.displayName.substring(0, 1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
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
            const Icon(Icons.how_to_vote, size: 16, color: Colors.grey),
            Text(
              '${contestant.voteCount}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
