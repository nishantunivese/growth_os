import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_config.dart';
import '../../../../core/database/local_db_service.dart';
import 'user_profile.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? userProfile;
  final String? errorMessage;

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
      // 1. Check local offline cache first
      final cached = await LocalDbService.query('local_profiles');
      if (cached.isNotEmpty) {
        final profile = UserProfile.fromJson(cached.first);
        state = AuthState.authenticated(profile);
        return;
      }

      // 2. Check Supabase session if online
      final user = SupabaseConfig.currentUser;
      if (user != null) {
        final profile = await _fetchProfile(user.id);
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
    try {
      final res = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user != null) {
        final profile = await _fetchProfile(res.user!.id);
        state = AuthState.authenticated(profile);
        return true;
      }
      state = AuthState.error('Authentication failed');
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<bool> signInDemo() async {
    state = AuthState.loading();
    // Instant zero-friction demo user
    final demoProfile = UserProfile(
      id: 'demo-creator-id-001',
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
    );

    // Save locally
    await LocalDbService.upsert('local_profiles', demoProfile.toJson());
    state = AuthState.authenticated(demoProfile);
    return true;
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = AuthState.loading();
    try {
      final res = await SupabaseConfig.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
      );
      if (res.user != null) {
        final profile = UserProfile(
          id: res.user!.id,
          fullName: name.trim(),
        );
        await LocalDbService.upsert('local_profiles', profile.toJson());
        state = AuthState.authenticated(profile);
        return true;
      }
      state = AuthState.error('Sign up failed');
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> updateProfile(UserProfile updated) async {
    try {
      await LocalDbService.upsert('local_profiles', updated.toJson());
      try {
        await SupabaseConfig.client
            .from('profiles')
            .upsert(updated.toJson());
      } catch (_) {
        // Will sync when online
      }
      state = AuthState.authenticated(updated);
    } catch (e) {
      state = AuthState.error('Failed to update profile');
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}
    await LocalDbService.delete('local_profiles');
    state = AuthState.unauthenticated();
  }

  Future<UserProfile> _fetchProfile(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      final profile = UserProfile.fromJson(data);
      await LocalDbService.upsert('local_profiles', profile.toJson());
      return profile;
    } catch (_) {
      return UserProfile(id: userId, fullName: 'Creator');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

