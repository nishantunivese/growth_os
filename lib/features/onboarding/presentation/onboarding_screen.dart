import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/local_db_service.dart';
import '../../navigation/main_scaffold.dart';

/// OnboardingScreen – shown only once to new users after first login.
/// Every step has a visible Skip button. On last step or skip, marks
/// onboarding as completed and navigates to MainScaffold.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const _steps = [
    _OnboardingStep(
      emoji: '🚀',
      title: 'Welcome to GROWTH OS',
      subtitle: 'Your Personal Business Command Center',
      description:
          'Growth OS helps you track every rupee earned, every task completed, and every goal achieved — all in one powerful offline-first app.',
      gradientColors: [Color(0xFF6C3CE1), Color(0xFF9B5EEA)],
    ),
    _OnboardingStep(
      emoji: '📊',
      title: 'Command Center',
      subtitle: 'Your Daily Dashboard',
      description:
          'See today\'s earnings, pending tasks, active projects, and progress at a glance. Your entire business health on one screen.',
      gradientColors: [Color(0xFF3C1E8C), Color(0xFF6C3CE1)],
    ),
    _OnboardingStep(
      emoji: '💼',
      title: 'Track Your Work',
      subtitle: 'Tasks & Projects',
      description:
          'Add tasks with deadlines, submit proof of work via screenshot or text, and get verified. Completed & verified tasks earn you Gold Coins!',
      gradientColors: [Color(0xFF1A5276), Color(0xFF2E86C1)],
    ),
    _OnboardingStep(
      emoji: '💰',
      title: 'Financial Intelligence',
      subtitle: 'Finance & Goals',
      description:
          'Log income and expenses, track platform-wise earnings (YouTube, Instagram, Freelance), and set monthly or annual financial goals.',
      gradientColors: [Color(0xFF1E8449), Color(0xFF27AE60)],
    ),
    _OnboardingStep(
      emoji: '🥇',
      title: 'Earn While You Work',
      subtitle: 'Gold Coins & Rewards',
      description:
          'Every verified task rewards you with Gold Coins. Accumulate coins and withdraw real money at month-end. Work more, earn more!',
      gradientColors: [Color(0xFF7D6608), Color(0xFFD4AC0D)],
    ),
    _OnboardingStep(
      emoji: '🤝',
      title: 'Client Management',
      subtitle: 'CRM Built for Creators',
      description:
          'Track all your clients, deals, follow-up dates, and interactions. Never miss a follow-up or payment deadline again.',
      gradientColors: [Color(0xFF78281F), Color(0xFFC0392B)],
    ),
    _OnboardingStep(
      emoji: '🔔',
      title: 'Smart Reminders',
      subtitle: 'Stay on Track Every Day',
      description:
          'Enable daily reminders from Profile → Notifications. Get nudged to log earnings, complete tasks, and hit your goals.',
      gradientColors: [Color(0xFF4A235A), Color(0xFF8E44AD)],
    ),
    _OnboardingStep(
      emoji: '🎉',
      title: "You're All Set!",
      subtitle: 'Start Your Growth Journey',
      description:
          'Everything is ready. Build your empire, one verified task at a time. Growth OS works fully offline — no internet needed!',
      gradientColors: [Color(0xFF6C3CE1), Color(0xFFE91E63)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await LocalDbService.instance.setOnboardingCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScaffold(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentPage];
    final isLast = _currentPage == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated background gradient blob
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  step.gradientColors[0].withOpacity(0.18),
                  AppColors.background,
                  step.gradientColors[1].withOpacity(0.10),
                ],
              ),
            ),
          ),

          // Skip button (always visible top-right)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),

          // Main Page Content
          SafeArea(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                _fadeController.reset();
                _fadeController.forward();
              },
              itemCount: _steps.length,
              itemBuilder: (_, index) {
                final s = _steps[index];
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildStepContent(s, index == _steps.length - 1),
                );
              },
            ),
          ),

          // Bottom controls
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_steps.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? step.gradientColors[1]
                                : AppColors.textSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    // Next / Let's Start button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: step.gradientColors,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: step.gradientColors[1].withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isLast ? "🚀  Let's Start!" : 'Next  →',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(_OnboardingStep step, bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 160),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large emoji with glow circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  step.gradientColors[0].withOpacity(0.3),
                  step.gradientColors[1].withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: step.gradientColors[1].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                step.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Title
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: step.gradientColors[1].withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: step.gradientColors[1].withOpacity(0.35),
              ),
            ),
            child: Text(
              step.subtitle,
              style: TextStyle(
                color: step.gradientColors[1],
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradientColors;

  const _OnboardingStep({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradientColors,
  });
}
