import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/auth_provider.dart';
import '../../navigation/main_scaffold.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _businessNameController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _instagramController = TextEditingController();
  final _telegramController = TextEditingController();
  final _monthlyTargetController = TextEditingController(text: '100000');
  final _annualTargetController = TextEditingController(text: '1200000');

  String _selectedCategory = 'Digital Creator';
  String _selectedCurrency = '₹';
  String _selectedTimezone = 'Asia/Kolkata';

  final List<String> _categories = [
    'Digital Creator',
    'Course Seller / Coach',
    'Affiliate Marketer',
    'Agency Owner',
    'Software / SaaS Founder',
    'E-commerce Entrepreneur',
  ];

  final List<String> _currencies = ['₹', '\$', '€', '£'];

  @override
  void dispose() {
    _businessNameController.dispose();
    _youtubeController.dispose();
    _instagramController.dispose();
    _telegramController.dispose();
    _monthlyTargetController.dispose();
    _annualTargetController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final current = ref.read(authProvider).userProfile;
    if (current == null) return;

    final updated = current.copyWith(
      businessName: _businessNameController.text.trim(),
      youtubeChannel: _youtubeController.text.trim(),
      instagramUsername: _instagramController.text.trim(),
      telegramChannel: _telegramController.text.trim(),
      monthlyEarningTarget: double.tryParse(_monthlyTargetController.text) ?? 100000.0,
      annualEarningTarget: double.tryParse(_annualTargetController.text) ?? 1200000.0,
      primaryCategory: _selectedCategory,
      preferredCurrency: _selectedCurrency,
      timeZone: _selectedTimezone,
    );

    await ref.read(authProvider.notifier).updateProfile(updated);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Targets Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Your OS',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Personalize your financial targets and creator channels.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 26),

              // Business Name
              const Text('Business / Brand Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Apex Media Agency',
                  prefixIcon: Icon(Icons.business_center_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              // Category Dropdown
              const Text('Primary Business Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppColors.cardSurface,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Currency & Targets Row
              Row(
                children: [
                  // Currency Picker
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Currency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              isExpanded: true,
                              dropdownColor: AppColors.cardSurface,
                              items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCurrency = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Monthly Target
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Target', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _monthlyTargetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: '$_selectedCurrency ',
                            hintText: '100000',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Creator Channels Section Header
              const Text('Creator & Audience Channels (Optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),

              // YouTube Channel
              TextField(
                controller: _youtubeController,
                decoration: const InputDecoration(
                  labelText: 'YouTube Channel',
                  hintText: '@ChannelHandle',
                  prefixIcon: Icon(Icons.play_circle_outline_rounded, color: Colors.redAccent, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Instagram Handle
              TextField(
                controller: _instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram Handle',
                  hintText: 'instagram_username',
                  prefixIcon: Icon(Icons.camera_alt_outlined, color: Colors.pinkAccent, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Telegram Channel
              TextField(
                controller: _telegramController,
                decoration: const InputDecoration(
                  labelText: 'Telegram Channel',
                  hintText: 't.me/channel',
                  prefixIcon: Icon(Icons.send_rounded, color: Colors.blueAccent, size: 20),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Launch GROWTH OS →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

