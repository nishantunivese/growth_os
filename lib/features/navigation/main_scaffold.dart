import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../home/presentation/home_dashboard_screen.dart';
import '../work/presentation/work_screen.dart';
import '../finance/presentation/goals_screen.dart';
import '../growth_center/presentation/growth_center_screen.dart';
import '../profile/presentation/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    WorkScreen(),
    GoalsScreen(),
    GrowthCenterScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _openQuickActionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Quick Action',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildQuickActionItem(
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.emeraldGreen,
                  title: 'Record Earning',
                  sub: 'Log a new income from course, platform, or client',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 2); // Goals tab
                  },
                ),
                const SizedBox(height: 10),
                _buildQuickActionItem(
                  icon: Icons.work_outline_rounded,
                  color: AppColors.electricPurpleLight,
                  title: 'New Work Project',
                  sub: 'Create a multi-stage process tracker',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 1); // Work tab
                  },
                ),
                const SizedBox(height: 10),
                _buildQuickActionItem(
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppColors.cyberCyan,
                  title: 'Add Client / Lead',
                  sub: 'Track high-ticket deal or creator sponsorship',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 3); // Growth tab
                  },
                ),
                const SizedBox(height: 10),
                _buildQuickActionItem(
                  icon: Icons.edit_note_rounded,
                  color: AppColors.amberWarning,
                  title: 'Post Work Journey Update',
                  sub: 'Attach screenshots, voice notes & learnings',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 1); // Work tab
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickActionModal,
        backgroundColor: AppColors.electricPurple,
        elevation: 6,
        shape: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.purpleGradient,
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.backgroundElevated,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left tabs (Home, My Work)
            Row(
              children: [
                _buildNavBarItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
                const SizedBox(width: 8),
                _buildNavBarItem(1, Icons.alt_route_outlined, Icons.alt_route_rounded, 'My Work'),
              ],
            ),
            // Middle spacing for FAB
            const SizedBox(width: 48),
            // Right tabs (Goals, Growth, Profile)
            Row(
              children: [
                _buildNavBarItem(2, Icons.savings_outlined, Icons.savings_rounded, 'Goals'),
                const SizedBox(width: 4),
                _buildNavBarItem(3, Icons.rocket_outlined, Icons.rocket_launch_rounded, 'Growth'),
                const SizedBox(width: 4),
                _buildNavBarItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? AppColors.electricPurpleLight : AppColors.textDim,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

