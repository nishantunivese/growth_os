import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_config.dart';
import '../../../core/database/local_db_service.dart';
import 'user_profile.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final String? errorMessage;

  UserProfile? get user => userProfile;

  const AuthState({
    required this.status,
    this.userProfile,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserProfile profile) =>
      AuthState(status: AuthStatus.authenticated, userProfile: profile);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String msg) =>
      AuthState(status: AuthStatus.error, errorMessage: msg);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    state = AuthState.loading();
    try {
      // 1. Check active session user ID from SQLite
      final activeUserId = await LocalDbService.instance.getActiveSessionUserId();
      if (activeUserId != null && activeUserId.isNotEmpty) {
        final cached = await LocalDbService.query(
          'local_profiles',
          where: 'id = ?',
          whereArgs: [activeUserId],
        );
        if (cached.isNotEmpty) {
          final profile = UserProfile.fromJson(cached.first);
          state = AuthState.authenticated(profile);
          return;
        }
      }

      // 2. Fallback to first profile if only 1 exists
      final allCached = await LocalDbService.query('local_profiles');
      if (allCached.isNotEmpty) {
        final profile = UserProfile.fromJson(allCached.first);
        await LocalDbService.instance.setActiveSession(profile.id);
        state = AuthState.authenticated(profile);
        return;
      }

      // 3. Check Supabase session if online
      final user = SupabaseConfig.currentUser;
      if (user != null) {
        final profile = await _fetchProfile(user.id);
        await LocalDbService.instance.setActiveSession(profile.id);
        state = AuthState.authenticated(profile);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = AuthState.loading();
    final cleanEmail = email.trim().toLowerCase();

    // 1. Instant check for demo credentials
    if (cleanEmail == 'demo@growthos.app' ||
        cleanEmail == 'nishant@growthos.app' ||
        cleanEmail == 'creator@business.com') {
      return await signInDemo();
    }

    // 2. Check local users database for registered user
    try {
      final userRows = await LocalDbService.query(
        'users',
        where: 'LOWER(email) = ?',
        whereArgs: [cleanEmail],
      );
      if (userRows.isNotEmpty) {
        final userRow = userRows.first;
        final storedPass = userRow['password_hash'] as String? ?? '';
        if (storedPass == password || storedPass.isEmpty) {
          final userId = userRow['id'] as String;
          final profileRows = await LocalDbService.query(
            'local_profiles',
            where: 'id = ?',
            whereArgs: [userId],
          );
          UserProfile profile;
          if (profileRows.isNotEmpty) {
            profile = UserProfile.fromJson(profileRows.first);
          } else {
            profile = UserProfile(
              id: userId,
              email: cleanEmail,
              fullName: userRow['full_name'] as String? ?? 'User',
              status: userRow['status'] as String? ?? 'active',
              suspensionReason: userRow['suspension_reason'] as String? ?? '',
            );
            await LocalDbService.upsert('local_profiles', profile.toLocalDbMap());
          }

          await LocalDbService.instance.setActiveSession(profile.id);
          await LocalDbService.instance.logUserActivity(
            profile.id,
            'login',
            'User logged in with email: $cleanEmail',
          );
          state = AuthState.authenticated(profile);
          return true;
        } else {
          state = AuthState.error('Invalid password for this account.');
          return false;
        }
      }
    } catch (_) {}

    // 3. Supabase online auth check (with timeout to avoid hanging)
    try {
      final res = await SupabaseConfig.client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      ).timeout(const Duration(seconds: 8));
      if (res.user != null) {
        final profile = await _fetchProfile(res.user!.id);
        await LocalDbService.instance.setActiveSession(profile.id);
        state = AuthState.authenticated(profile);
        return true;
      }
    } catch (_) {}

    // 4. Check existing local_profiles table directly
    try {
      final cached = await LocalDbService.query(
        'local_profiles',
        where: 'LOWER(email) = ?',
        whereArgs: [cleanEmail],
      );
      if (cached.isNotEmpty) {
        final profile = UserProfile.fromJson(cached.first);
        await LocalDbService.instance.setActiveSession(profile.id);
        state = AuthState.authenticated(profile);
        return true;
      }
    } catch (_) {}

    // 5. Fallback for offline fresh registration/login:
    final namePart = cleanEmail.contains('@') ? cleanEmail.split('@').first : cleanEmail;
    final formattedName = namePart.isNotEmpty
        ? namePart[0].toUpperCase() + namePart.substring(1)
        : 'Growth Creator';

    final newUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final freshProfile = UserProfile(
      id: newUserId,
      email: cleanEmail,
      fullName: formattedName,
      businessName: '',
      primaryCategory: 'Digital Creator',
      preferredCurrency: '₹',
      monthlyEarningTarget: 100000.0,
      annualEarningTarget: 1200000.0,
      streakCount: 1,
      status: 'active',
      createdAt: DateTime.now().toIso8601String(),
    );

    // Save to users and local_profiles
    await LocalDbService.upsert('users', {
      'id': newUserId,
      'email': cleanEmail,
      'password_hash': password,
      'full_name': formattedName,
      'role': 'user',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
    await LocalDbService.upsert('local_profiles', freshProfile.toLocalDbMap());
    await LocalDbService.instance.getCoinBalance(newUserId); // initialize coins at 0
    await LocalDbService.instance.setActiveSession(newUserId);

    state = AuthState.authenticated(freshProfile);
    return true;
  }

  Future<bool> signInDemo() async {
    state = AuthState.loading();
    const demoId = 'demo-creator-id-001';

    final demoProfile = UserProfile(
      id: demoId,
      email: 'demo@growthos.app',
      fullName: 'Alex Morgan',
      businessName: 'Vanguard Media & Courses',
      youtubeChannel: '@AlexVanguard',
      instagramUsername: 'alex_vanguard',
      telegramChannel: 't.me/vanguardgrowth',
      monthlyEarningTarget: 250000.0,
      annualEarningTarget: 3000000.0,
      primaryCategory: 'Content Creator & Coach',
      preferredCurrency: '₹',
      streakCount: 14,
      isAdmin: true,
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
    );

    // Set state immediately — do NOT wait for DB writes (they happen in background)
    state = AuthState.authenticated(demoProfile);

    // Background DB writes (non-blocking)
    Future(() async {
      try {
        await LocalDbService.upsert('users', {
          'id': demoId,
          'email': 'demo@growthos.app',
          'password_hash': 'password123',
          'full_name': 'Alex Morgan',
          'role': 'user',
          'status': 'active',
          'created_at': demoProfile.createdAt,
        });
        await LocalDbService.upsert('local_profiles', demoProfile.toLocalDbMap());
        await LocalDbService.instance.setActiveSession(demoId);
        await LocalDbService.instance.logUserActivity(demoId, 'login', 'Demo user session started');
      } catch (_) {}
    });

    return true;
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = AuthState.loading();
    final cleanEmail = email.trim().toLowerCase();
    final validName = name.trim().isNotEmpty ? name.trim() : 'Digital Creator';
    final newUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toIso8601String();

    try {
      final res = await SupabaseConfig.client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': validName},
      ).timeout(const Duration(seconds: 8));
      if (res.user != null) {
        final profile = UserProfile(
          id: res.user!.id,
          email: cleanEmail,
          fullName: validName,
          status: 'active',
          createdAt: nowIso,
        );
        await LocalDbService.upsert('users', {
          'id': res.user!.id,
          'email': cleanEmail,
          'password_hash': password,
          'full_name': validName,
          'role': 'user',
          'status': 'active',
          'created_at': nowIso,
        });
        await LocalDbService.upsert('local_profiles', profile.toLocalDbMap());
        await LocalDbService.instance.getCoinBalance(res.user!.id);
        await LocalDbService.instance.setActiveSession(res.user!.id);
        state = AuthState.authenticated(profile);
        return true;
      }
    } catch (_) {}

    // Offline registration: 100% fresh account with ZERO pre-added data!
    final freshProfile = UserProfile(
      id: newUserId,
      email: cleanEmail,
      fullName: validName,
      businessName: '',
      primaryCategory: 'Digital Creator',
      preferredCurrency: '₹',
      monthlyEarningTarget: 100000.0,
      annualEarningTarget: 1200000.0,
      streakCount: 1,
      status: 'active',
      createdAt: nowIso,
    );

    await LocalDbService.upsert('users', {
      'id': newUserId,
      'email': cleanEmail,
      'password_hash': password,
      'full_name': validName,
      'role': 'user',
      'status': 'active',
      'created_at': nowIso,
    });
    await LocalDbService.upsert('local_profiles', freshProfile.toLocalDbMap());
    await LocalDbService.instance.getCoinBalance(newUserId); // initial 0 coins
    await LocalDbService.instance.setActiveSession(newUserId);
    await LocalDbService.instance.logUserActivity(
      newUserId,
      'register',
      'New fresh user registered: $validName ($cleanEmail)',
    );

    state = AuthState.authenticated(freshProfile);
    return true;
  }

  Future<void> updateProfile(UserProfile updated) async {
    try {
      await LocalDbService.upsert('local_profiles', updated.toLocalDbMap());
      try {
        await SupabaseConfig.client
            .from('profiles')
            .upsert(updated.toJson());
      } catch (_) {}
      state = AuthState.authenticated(updated);
    } catch (e) {
      state = AuthState.error('Failed to update profile');
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}
    // Clear only active session marker, preserving account data for next login!
    await LocalDbService.instance.clearActiveSession();
    state = AuthState.unauthenticated();
  }

  Future<UserProfile> _fetchProfile(String userId) async {
    try {
      final res = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      final profile = UserProfile.fromJson(res);
      await LocalDbService.upsert('local_profiles', profile.toLocalDbMap());
      return profile;
    } catch (_) {
      final cached = await LocalDbService.query(
        'local_profiles',
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (cached.isNotEmpty) {
        return UserProfile.fromJson(cached.first);
      }
      return UserProfile(id: userId, fullName: 'Creator');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
