import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/contestant.dart';
import 'stage1_screen.dart';
import 'stage1_top50_screen.dart';
import 'final_results_screen.dart';

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
                      label: const Text('ابدأ التصويت - Stage1'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                  if (!contest.isStage1 && !contest.isStage1Top50 && !contest.isFinalStage && !contest.isFinished)
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.lock),
                      label: Text('Stage1 — ${_getStageName(contest.stage)}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                  // Top50 button
                  if (contest.isStage1Top50 || contest.isFinalStage || contest.isFinished) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Stage1Top50Screen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.leaderboard),
                      label: const Text('عرض أفضل 50 - Top50'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],

                  // Final stage button
                  if (contest.isFinalStage) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Stage1Screen(), // Reuse Stage1 screen for final voting
                          ),
                        );
                      },
                      icon: const Icon(Icons.flag),
                      label: const Text('التصويت النهائي - Final'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],

                  // Results button
                  if (contest.isFinished) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FinalResultsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('النتائج النهائية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
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

                // DEV: Open Full Flow
                ElevatedButton.icon(
                  onPressed: appState.isLoading
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('تأكيد'),
                              content: const Text(
                                'هذا سيقوم بإعداد المسابقة بالكامل:\n'
                                '• إنشاء مسابقة اليوم\n'
                                '• إضافة 20 متسابق\n'
                                '• بدء المرحلة الأولى + تصويت\n'
                                '• تجميد أفضل 50\n'
                                '• بدء المرحلة النهائية + تصويت\n'
                                '• إنهاء المسابقة + النتائج\n\n'
                                'هل تريد المتابعة؟',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('إلغاء'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('نعم'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true && mounted) {
                            await appState.devOpenFullFlow();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ تم إعداد المسابقة بالكامل!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('🚀 DEV: فتح المسابقة كاملة (Full Flow)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 12),

                // Row 1: Reset + Create
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appState.isLoading
                            ? null
                            : () async {
                                await appState.devResetDay();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إعادة تعيين اليوم'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reset Day', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appState.isLoading
                            ? null
                            : () async {
                                await appState.devCreateTodayContest();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إنشاء مسابقة اليوم'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Contest', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 2: Seed Contestants + Seed Votes
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appState.isLoading
                            ? null
                            : () async {
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
                        icon: const Icon(Icons.people, size: 18),
                        label: const Text('Seed 20', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appState.isLoading
                            ? null
                            : () async {
                                final isFinal = appState.activeContest?.isFinalStage ?? false;
                                await appState.devSeedVotes(isFinalStage: isFinal);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إضافة الأصوات'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.how_to_vote, size: 18),
                        label: const Text('Seed Votes', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 3: Start Stage1 + Freeze Top50
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appState.isLoading
                            ? null
                            : () async {
                                await appState.devStartStage1Now();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم بدء Stage1'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Start Stage1', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appState.isLoading
                            ? null
                            : () async {
                                await appState.devFreezeTop50Now();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تجميد أفضل 50'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.ac_unit, size: 18),
                        label: const Text('Freeze Top50', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 4: Start Final + Finish
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appState.isLoading
                            ? null
                            : () async {
                                await appState.devStartFinalNow();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم بدء النهائي'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.flag, size: 18),
                        label: const Text('Start Final', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: appState.isLoading
                            ? null
                            : () async {
                                await appState.devFinishNow();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إنهاء المسابقة'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.emoji_events, size: 18),
                        label: const Text('Finish Now', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // DEV add funds
                ElevatedButton.icon(
                  onPressed: () {
                    appState.devAddFunds(nova: 1000, aura: 1000);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إضافة 1000 نوفا و 1000 أورا'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.attach_money),
                  label: const Text('إضافة أموال (1000+1000)'),
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
