import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/auth_provider.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../../navigation/main_scaffold.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Brand Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricPurple.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 28),

              // Title
              const Text(
                'Scale Your\nDigital Empire.',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -1.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'The unified business OS built for modern creators, educators and digital entrepreneurs.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Feature Pillars
              _buildFeaturePill(
                icon: Icons.alt_route_rounded,
                title: 'Multi-Stage Process Tracking',
                sub: 'Document your journey with screenshots & learnings.',
              ),
              const SizedBox(height: 16),
              _buildFeaturePill(
                icon: Icons.currency_rupee_rounded,
                title: 'Net Profit & Financial Goals',
                sub: 'Track real revenue vs expenses with live targets.',
              ),
              const SizedBox(height: 16),
              _buildFeaturePill(
                icon: Icons.campaign_rounded,
                title: 'Creator Growth Center',
                sub: 'Content calendar, audience metrics & course funnels.',
              ),

              const Spacer(),

              // Primary CTA: Sign Up
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text('Get Started Free →'),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary: Log In
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'I already have an account',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Zero-friction instant Demo Login
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signInDemo();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainScaffold()),
                      );
                    }
                  },
                  icon: const Icon(Icons.bolt_rounded, color: AppColors.electricPurpleLight, size: 18),
                  label: const Text(
                    'Instant Demo Mode (No signup required)',
                    style: TextStyle(color: AppColors.electricPurpleLight, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.electricPurpleLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

