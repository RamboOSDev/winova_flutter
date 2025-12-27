import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/contest.dart';
import '../config/app_config.dart';
import 'stage1_screen_new.dart';
import 'stage1_top50_screen.dart';
import 'final_results_screen.dart';

/// Enhanced Contests Hub Screen - Professional Daily Contest Management
class ContestsScreenNew extends StatefulWidget {
  const ContestsScreenNew({super.key});

  @override
  State<ContestsScreenNew> createState() => _ContestsScreenNewState();
}

class _ContestsScreenNewState extends State<ContestsScreenNew> {
  Timer? _countdownTimer;
  int _selectedTab = 0; // 0 = Today, 1 = History

  @override
  void initState() {
    super.initState();
    // Load contests when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.loadContests();
      
      // Start periodic updates (every 5 seconds for online counter and countdown)
      _startPeriodicUpdates();
    });
  }

  void _startPeriodicUpdates() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final appState = context.read<AppState>();
        appState.startOnlineCounterSimulation();
        setState(() {}); // Refresh countdown
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المسابقات'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppState>().loadContests();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading && appState.contests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Tabs
              _buildTabs(),
              
              // Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildTodayTab(context, appState)
                    : _buildHistoryTab(context, appState),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 0 ? Colors.purple : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  'اليوم',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTab == 0 ? Colors.purple : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 1 ? Colors.purple : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  'المسابقات السابقة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTab == 1 ? Colors.purple : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab(BuildContext context, AppState appState) {
    final contest = appState.activeContest;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Online Indicator
          _buildOnlineIndicator(appState),
          
          // Hero Card - Today's Contest
          if (contest != null)
            _buildContestHeroCard(context, appState, contest)
          else
            _buildNoContestCard(context, appState),
          
          // Free Hour Banner
          if (contest != null && contest.isStage1)
            _buildFreeHourBanner(appState, contest),
          
          // Spotlight Card
          if (contest != null && contest.isStage1)
            _buildSpotlightCard(appState, contest),
          
          const SizedBox(height: 16),
          
          // DEV Tools
          _buildDevTools(context, appState),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, AppState appState) {
    // For now, show placeholder
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'المسابقات السابقة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'قريبًا - سيتم عرض آخر 30 يوم',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.green[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '🟢 نشيط الآن: ${appState.onlineUsersCount}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContestHeroCard(BuildContext context, AppState appState, Contest contest) {
    final participantsCount = contest.participantIds.length;
    final prizePool = participantsCount * AppConfig.entryFeeNova;
    final hasJoined = appState.hasJoinedContest;
    
    // Get time remaining for current stage
    final timeRemaining = appState.getStageTimeRemaining();
    final timeString = timeRemaining != null 
        ? appState.formatTimeRemaining(timeRemaining) 
        : '--:--:--';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStageGradient(contest.stage),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          contest.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _buildStageBadge(contest.stage),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'ar').format(contest.startDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Countdown
                  _buildCountdownSection(contest.stage, timeString),
                  
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),
                  
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people,
                          label: 'المشتركون',
                          value: '$participantsCount',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.card_giftcard,
                          label: 'جائزة النوفا',
                          value: '${prizePool.toStringAsFixed(1)}',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Registration info
                  if (contest.isStage1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الاشتراك متاح حتى ${AppConfig.stage1EndHour}:00 PM',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // CTA Button
                  _buildCTAButton(context, appState, contest, hasJoined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoContestCard(BuildContext context, AppState appState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد مسابقة نشطة اليوم',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'استخدم أدوات DEV لإنشاء مسابقة تجريبية',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStageBadge(String stage) {
    Color color;
    String text;
    
    switch (stage) {
      case 'preStage':
        color = Colors.grey;
        text = 'قبل البداية';
        break;
      case 'stage1':
        color = Colors.orange;
        text = 'المرحلة الأولى';
        break;
      case 'stage1Top50':
        color = Colors.cyan;
        text = 'أفضل 50';
        break;
      case 'finalStage':
        color = Colors.amber;
        text = 'النهائي';
        break;
      case 'finished':
        color = Colors.green;
        text = 'انتهت';
        break;
      default:
        color = Colors.grey;
        text = stage;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  List<Color> _getStageGradient(String stage) {
    switch (stage) {
      case 'preStage':
        return [Colors.grey[700]!, Colors.grey[500]!];
      case 'stage1':
        return [Colors.orange[700]!, Colors.orange[400]!];
      case 'stage1Top50':
        return [Colors.cyan[700]!, Colors.cyan[400]!];
      case 'finalStage':
        return [Colors.amber[700]!, Colors.amber[400]!];
      case 'finished':
        return [Colors.green[700]!, Colors.green[400]!];
      default:
        return [Colors.purple[700]!, Colors.purple[400]!];
    }
  }

  Widget _buildCountdownSection(String stage, String timeString) {
    String label;
    switch (stage) {
      case 'preStage':
        label = 'باقي على البداية';
        break;
      case 'stage1':
        label = 'باقي على انتهاء المرحلة الأولى';
        break;
      case 'stage1Top50':
        label = 'باقي على النهائي';
        break;
      case 'finalStage':
        label = 'باقي على انتهاء النهائي';
        break;
      default:
        label = 'المسابقة انتهت';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              timeString,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(BuildContext context, AppState appState, Contest contest, bool hasJoined) {
    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor = Colors.white;
    Color textColor = Colors.purple;
    IconData icon = Icons.login;
    
    if (contest.isPreStage) {
      buttonText = 'باقي على البداية';
      onPressed = null;
      buttonColor = Colors.white38;
    } else if (contest.isStage1) {
      if (!hasJoined) {
        buttonText = 'اشترك الآن';
        icon = Icons.login;
        onPressed = () async {
          final success = await appState.joinContest(contest.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'تم الاشتراك بنجاح!' : appState.error ?? 'فشل الاشتراك'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        };
      } else {
        buttonText = 'ادخل وصوّت';
        icon = Icons.how_to_vote;
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Stage1ScreenNew()),
          );
        };
      }
    } else if (contest.isStage1Top50) {
      buttonText = 'شوف Top50';
      icon = Icons.leaderboard;
      onPressed = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Stage1Top50Screen()),
        );
      };
    } else if (contest.isFinalStage) {
      buttonText = 'ادخل النهائي وصوّت';
      icon = Icons.flag;
      onPressed = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Stage1ScreenNew()), // Reuse for final
        );
      };
    } else if (contest.isFinished) {
      buttonText = 'شوف نتائج اليوم';
      icon = Icons.emoji_events;
      onPressed = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FinalResultsScreen()),
        );
      };
    } else {
      buttonText = 'غير متاح';
      onPressed = null;
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: appState.isLoading ? null : onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          buttonText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildFreeHourBanner(AppState appState, Contest contest) {
    String message;
    Color color;
    IconData icon;
    
    if (!appState.isFreeHourAnnounced) {
      message = 'الساعة المجانية لم تُعلن بعد';
      color = Colors.grey;
      icon = Icons.schedule;
    } else if (appState.isFreeHourActive) {
      message = '🔥 الساعة المجانية شغالة الآن (صوت مجاني واحد فقط اليوم)';
      color = Colors.red;
      icon = Icons.local_fire_department;
    } else if (appState.isFreeHourPassed) {
      message = 'انتهت الساعة المجانية';
      color = Colors.grey;
      icon = Icons.check_circle;
    } else {
      final freeHourStart = contest.freeHourStart!;
      final now = DateTime.now();
      final diff = freeHourStart.difference(now);
      message = 'الساعة المجانية تبدأ خلال ${diff.inMinutes} دقيقة';
      color = Colors.orange;
      icon = Icons.timer;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightCard(AppState appState, Contest contest) {
    final isAnnounced = appState.isSpotlightAnnounced;
    final spotlightPrize = appState.spotlightPrize;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.amber[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '⭐ محظوظ اليوم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (!isAnnounced) ...[
                Text(
                  'سيتم الإعلان عن المحظوظ في الساعة ${AppConfig.spotlightAnnouncementHour}:00 PM',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'جائزة المحظوظ: ${spotlightPrize.toStringAsFixed(1)} نوفا',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (contest.spotlightUserId != null) ...[
                  Text(
                    'المحظوظ: ${contest.spotlightUserId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'جائزته: ${contest.spotlightPrize.toStringAsFixed(1)} نوفا 🎉',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Open profile
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('افتح بروفايل المحظوظ - قريبًا')),
                        );
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('افتح بروفايله'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'لم يتم تحديد المحظوظ بعد',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevTools(BuildContext context, AppState appState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.developer_mode, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'أدوات DEV للاختبار',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Full Flow button
          ElevatedButton.icon(
            onPressed: appState.isLoading ? null : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد'),
                  content: const Text(
                    'هذا سيقوم بإعداد المسابقة بالكامل من البداية للنهاية.\n\nهل تريد المتابعة؟',
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
              
              if (confirmed == true && context.mounted) {
                await appState.devOpenFullFlow();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تم إعداد المسابقة بالكامل!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.rocket_launch),
            label: const Text('🚀 فتح المسابقة كاملة (Full Flow)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Quick actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDevButton(
                context,
                label: 'Reset',
                icon: Icons.refresh,
                color: Colors.orange,
                onPressed: () async {
                  await appState.devResetDay();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إعادة التعيين')),
                    );
                  }
                },
              ),
              _buildDevButton(
                context,
                label: 'Create',
                icon: Icons.add,
                color: Colors.blue,
                onPressed: () async {
                  await appState.devCreateTodayContest();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إنشاء المسابقة')),
                    );
                  }
                },
              ),
              _buildDevButton(
                context,
                label: 'Seed 20',
                icon: Icons.people,
                color: Colors.red,
                onPressed: () async {
                  await appState.devSeedContestants();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم إضافة ${appState.contestants.length} متسابق')),
                    );
                  }
                },
              ),
              _buildDevButton(
                context,
                label: 'Start Stage1',
                icon: Icons.play_arrow,
                color: Colors.orange[700]!,
                onPressed: () async {
                  await appState.devStartStage1Now();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم بدء Stage1')),
                    );
                  }
                },
              ),
              _buildDevButton(
                context,
                label: 'Freeze Top50',
                icon: Icons.ac_unit,
                color: Colors.cyan,
                onPressed: () async {
                  await appState.devFreezeTop50Now();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تجميد أفضل 50')),
                    );
                  }
                },
              ),
              _buildDevButton(
                context,
                label: 'Start Final',
                icon: Icons.flag,
                color: Colors.amber[700]!,
                onPressed: () async {
                  await appState.devStartFinalNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم بدء النهائي')),
                    );
                  }
                },
              ),
              _buildDevButton(
                context,
                label: 'Finish',
                icon: Icons.emoji_events,
                color: Colors.green[700]!,
                onPressed: () async {
                  await appState.devFinishNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إنهاء المسابقة')),
                    );
                  }
                },
              ),
              _buildDevButton(
                context,
                label: 'Add Funds',
                icon: Icons.attach_money,
                color: Colors.blue[700]!,
                onPressed: () {
                  appState.devAddFunds(nova: 1000, aura: 1000);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إضافة 1000 نوفا و 1000 أورا')),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User balance
          if (appState.currentUser != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رصيدك الحالي:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('نوفا: ${appState.currentUser!.novaBalance.toStringAsFixed(1)}'),
                      Text('أورا: ${appState.currentUser!.auraBalance.toStringAsFixed(1)}'),
                      Text('أصوات متبقية اليوم: ${appState.remainingVotesToday}'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDevButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: context.watch<AppState>().isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: Size.zero,
      ),
    );
  }
}
