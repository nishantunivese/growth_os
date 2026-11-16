import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

/// Local Offline Database Service for GROWTH OS
/// Provides zero-latency offline persistence, strict user-level data isolation,
/// task verification, gold coin rewards, withdrawals, and admin audit telemetry.
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  static Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    try {
      final db = await instance.database;
      return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
    } catch (e) {
      debugPrint('[LocalDbService Query Error] in $table: $e');
      return [];
    }
  }

  static Future<void> upsert(String table, Map<String, dynamic> data) async {
    try {
      final db = await instance.database;
      await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[LocalDbService Upsert Error] in $table: $e');
    }
  }

  static Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await instance.database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'growth_os_offline.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createAllTables(db);
        await _seedDefaultAdmin(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createAllTables(db);
          // Safely migrate existing tables if columns missing
          final alterQueries = [
            "ALTER TABLE local_profiles ADD COLUMN email TEXT",
            "ALTER TABLE local_profiles ADD COLUMN status TEXT DEFAULT 'active'",
            "ALTER TABLE local_profiles ADD COLUMN suspension_reason TEXT",
            "ALTER TABLE local_profiles ADD COLUMN admin_notes TEXT",
            "ALTER TABLE local_profiles ADD COLUMN created_at TEXT",
          ];
          for (final q in alterQueries) {
            try {
              await db.execute(q);
            } catch (_) {}
          }
          await _seedDefaultAdmin(db);
        }
        if (oldVersion < 3) {
          final alterV3 = [
            "ALTER TABLE goals ADD COLUMN platform_name TEXT DEFAULT 'All Platforms'",
            "ALTER TABLE goals ADD COLUMN period TEXT DEFAULT 'monthly'",
            "ALTER TABLE goals ADD COLUMN start_date TEXT",
            "ALTER TABLE goals ADD COLUMN end_date TEXT",
          ];
          for (final q in alterV3) {
            try {
              await db.execute(q);
            } catch (_) {}
          }
        }
        if (oldVersion < 4) {
          // Add app_settings table for onboarding flag and future settings
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY,
                value TEXT
              )
            ''');
          } catch (_) {}
        }
      },
    );
  }

  static Future<void> _createAllTables(Database db) async {
    // 1. Local Profiles
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_profiles (
        id TEXT PRIMARY KEY,
        email TEXT,
        full_name TEXT,
        business_name TEXT,
        avatar_url TEXT,
        youtube_channel TEXT,
        instagram_username TEXT,
        telegram_channel TEXT,
        monthly_earning_target REAL,
        annual_earning_target REAL,
        primary_category TEXT,
        preferred_currency TEXT,
        time_zone TEXT DEFAULT 'Asia/Kolkata',
        streak_count INTEGER,
        is_admin INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        suspension_reason TEXT,
        admin_notes TEXT,
        created_at TEXT
      )
    ''');

    // 2. Users registry (for multi-user offline login & isolation)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        password_hash TEXT,
        full_name TEXT,
        role TEXT DEFAULT 'user',
        status TEXT DEFAULT 'active',
        suspension_reason TEXT,
        admin_notes TEXT,
        created_at TEXT
      )
    ''');

    // 3. Admin Users (Dedicated admin credentials & RBAC)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS admin_users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE,
        password_hash TEXT,
        display_name TEXT,
        role TEXT DEFAULT 'superadmin',
        created_at TEXT
      )
    ''');

    // 4. Local Projects
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_projects (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT,
        platform_category TEXT,
        description TEXT,
        start_date TEXT,
        deadline TEXT,
        priority TEXT,
        status TEXT,
        expected_result TEXT,
        progress_percentage REAL,
        notes TEXT,
        reminder_enabled INTEGER,
        reminder_interval_hours INTEGER,
        last_updated TEXT,
        created_at TEXT
      )
    ''');

    // 5. Local Stages
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_stages (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        title TEXT,
        description TEXT,
        stage_order INTEGER,
        is_completed INTEGER,
        weight REAL,
        completed_at TEXT
      )
    ''');

    // 6. Local Updates
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_updates (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        stage_id TEXT,
        written_update TEXT,
        result_achieved TEXT,
        loss_or_problem TEXT,
        learnings TEXT,
        money_earned REAL,
        money_lost REAL,
        screenshot_urls TEXT,
        voice_note_url TEXT,
        voice_duration_seconds INTEGER,
        created_at TEXT
      )
    ''');

    // 7. Tasks (Work management with status lifecycle)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT,
        description TEXT,
        platform TEXT,
        project_id TEXT,
        category TEXT,
        deadline TEXT,
        priority TEXT,
        status TEXT,
        is_qualifying INTEGER DEFAULT 1,
        rejection_reason TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 8. Task Proofs (Screenshot + text proof submission)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_proofs (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        user_id TEXT,
        proof_type TEXT,
        screenshot_path TEXT,
        text_proof TEXT,
        submitted_date TEXT,
        submitted_time TEXT,
        submitted_at TEXT
      )
    ''');

    // 9. Task Reviews (Admin audit on tasks)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_reviews (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        user_id TEXT,
        reviewed_by TEXT,
        status TEXT,
        rejection_reason TEXT,
        reviewed_at TEXT
      )
    ''');

    // 10. Gold Coin Balances
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gold_coin_balances (
        user_id TEXT PRIMARY KEY,
        total_earned INTEGER DEFAULT 0,
        available_balance INTEGER DEFAULT 0,
        pending_rewards INTEGER DEFAULT 0,
        total_withdrawn INTEGER DEFAULT 0,
        last_calculated_at TEXT
      )
    ''');

    // 11. Reward Transactions (Unique per user + date prevents duplicate rewards)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reward_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        coins INTEGER,
        reason TEXT,
        reward_date TEXT,
        task_count INTEGER,
        created_at TEXT,
        UNIQUE(user_id, reward_date)
      )
    ''');

    // 12. Withdrawal Requests
    await db.execute('''
      CREATE TABLE IF NOT EXISTS withdrawal_requests (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        full_name TEXT,
        upi_id TEXT,
        amount INTEGER,
        coins_reserved INTEGER,
        month_year TEXT,
        status TEXT,
        notes TEXT,
        rejection_reason TEXT,
        payment_ref TEXT,
        submitted_at TEXT,
        reviewed_at TEXT
      )
    ''');

    // 13. Income Entries
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_income (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        amount REAL,
        date TEXT,
        platform_source TEXT,
        income_category TEXT,
        description TEXT,
        payment_status TEXT,
        payment_screenshot_url TEXT,
        notes TEXT
      )
    ''');

    // 14. Expense Entries
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_expenses (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        amount REAL,
        date TEXT,
        category TEXT,
        description TEXT,
        is_refund INTEGER,
        notes TEXT
      )
    ''');

    // 15. Goals
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT,
        platform_name TEXT DEFAULT 'All Platforms',
        period TEXT DEFAULT 'monthly',
        target_amount REAL,
        current_amount REAL,
        start_date TEXT,
        end_date TEXT,
        deadline TEXT,
        category TEXT,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 16. Clients
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_clients (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        client_brand_name TEXT,
        contact_person TEXT,
        phone TEXT,
        whatsapp TEXT,
        email TEXT,
        instagram TEXT,
        company_name TEXT,
        project_details TEXT,
        deal_amount REAL,
        payment_status TEXT,
        work_deadline TEXT,
        follow_up_date TEXT,
        status TEXT,
        notes TEXT,
        created_at TEXT
      )
    ''');

    // 17. Client Interactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_interactions (
        id TEXT PRIMARY KEY,
        client_id TEXT,
        interaction_type TEXT,
        notes TEXT,
        date TEXT
      )
    ''');

    // 18. User Activity Logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_activity_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        action TEXT,
        detail TEXT,
        created_at TEXT
      )
    ''');

    // 19. Admin Audit Logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS admin_audit_logs (
        id TEXT PRIMARY KEY,
        admin_id TEXT,
        action TEXT,
        target_user_id TEXT,
        detail TEXT,
        created_at TEXT
      )
    ''');

    // 20. Sync Queue
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT,
        record_id TEXT,
        action TEXT,
        payload TEXT,
        created_at TEXT
      )
    ''');

    // 21. Active Session (Preserves multiple user accounts offline)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_session (
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        logged_in_at TEXT
      )
    ''');

    // 22. App Settings (key-value store for onboarding flag etc.)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  static Future<void> _seedDefaultAdmin(Database db) async {
    // Seed default admin in admin_users if empty
    final existing = await db.query('admin_users', where: 'username = ?', whereArgs: ['admin@growthos.app']);
    if (existing.isEmpty) {
      await db.insert('admin_users', {
        'id': 'admin_master_001',
        'username': 'admin@growthos.app',
        'password_hash': 'admin123', // Standard default hash/credential for admin access
        'display_name': 'Chief Executive Admin',
        'role': 'superadmin',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // --- Projects (Isolated by user_id) ---
  Future<List<Map<String, dynamic>>> getProjects({String? userId}) async {
    final db = await database;
    if (userId != null && userId.isNotEmpty) {
      return await db.query('local_projects', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    }
    return await db.query('local_projects', orderBy: 'created_at DESC');
  }

  Future<void> upsertProject(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_projects', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('local_projects', where: 'id = ?', whereArgs: [id]);
  }

  // --- Stages ---
  Future<List<Map<String, dynamic>>> getStages(String projectId) async {
    final db = await database;
    return await db.query('local_stages', where: 'project_id = ?', whereArgs: [projectId], orderBy: 'stage_order ASC');
  }

  Future<void> upsertStage(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_stages', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteStage(String id) async {
    final db = await database;
    await db.delete('local_stages', where: 'id = ?', whereArgs: [id]);
  }

  // --- Updates ---
  Future<List<Map<String, dynamic>>> getUpdates(String projectId) async {
    final db = await database;
    return await db.query('local_updates', where: 'project_id = ?', whereArgs: [projectId], orderBy: 'created_at DESC');
  }

  Future<void> upsertUpdate(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_updates', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Income (Isolated by user_id) ---
  Future<List<Map<String, dynamic>>> getIncome({String? userId}) async {
    final db = await database;
    if (userId != null && userId.isNotEmpty) {
      return await db.query('local_income', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
    }
    return await db.query('local_income', orderBy: 'date DESC');
  }

  Future<void> upsertIncome(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_income', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Expenses (Isolated by user_id) ---
  Future<List<Map<String, dynamic>>> getExpenses({String? userId}) async {
    final db = await database;
    if (userId != null && userId.isNotEmpty) {
      return await db.query('local_expenses', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
    }
    return await db.query('local_expenses', orderBy: 'date DESC');
  }

  Future<void> upsertExpense(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_expenses', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Goals (Isolated by user_id) ---
  Future<List<Map<String, dynamic>>> getGoals({String? userId}) async {
    final db = await database;
    if (userId != null && userId.isNotEmpty) {
      return await db.query('goals', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    }
    return await db.query('goals', orderBy: 'created_at DESC');
  }

  Future<void> upsertGoal(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('goals', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // --- Tasks (Isolated by user_id) ---
  Future<List<Map<String, dynamic>>> getTasks(String userId, {String? status}) async {
    final db = await database;
    if (status != null && status.isNotEmpty && status != 'All') {
      return await db.query('tasks', where: 'user_id = ? AND status = ?', whereArgs: [userId, status], orderBy: 'created_at DESC');
    }
    return await db.query('tasks', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllTasksForAdmin({String? status}) async {
    final db = await database;
    if (status != null && status.isNotEmpty && status != 'All') {
      return await db.query('tasks', where: 'status = ?', whereArgs: [status], orderBy: 'created_at DESC');
    }
    return await db.query('tasks', orderBy: 'created_at DESC');
  }

  Future<void> upsertTask(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('tasks', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Task Proofs ---
  Future<List<Map<String, dynamic>>> getTaskProofs(String taskId) async {
    final db = await database;
    return await db.query('task_proofs', where: 'task_id = ?', whereArgs: [taskId], orderBy: 'submitted_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllTaskProofs() async {
    final db = await database;
    return await db.query('task_proofs', orderBy: 'submitted_at DESC');
  }

  Future<void> upsertTaskProof(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('task_proofs', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Task Reviews ---
  Future<List<Map<String, dynamic>>> getTaskReviews(String taskId) async {
    final db = await database;
    return await db.query('task_reviews', where: 'task_id = ?', whereArgs: [taskId], orderBy: 'reviewed_at DESC');
  }

  Future<void> upsertTaskReview(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('task_reviews', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Gold Coin Balances ---
  Future<Map<String, dynamic>?> getCoinBalance(String userId) async {
    final db = await database;
    final res = await db.query('gold_coin_balances', where: 'user_id = ?', whereArgs: [userId]);
    if (res.isNotEmpty) return res.first;
    // Initialize with 0
    final initial = {
      'user_id': userId,
      'total_earned': 0,
      'available_balance': 0,
      'pending_rewards': 0,
      'total_withdrawn': 0,
      'last_calculated_at': DateTime.now().toIso8601String(),
    };
    await db.insert('gold_coin_balances', initial, conflictAlgorithm: ConflictAlgorithm.ignore);
    return initial;
  }

  Future<void> upsertCoinBalance(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('gold_coin_balances', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Reward Transactions ---
  Future<List<Map<String, dynamic>>> getRewardTransactions(String userId) async {
    final db = await database;
    return await db.query('reward_transactions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllRewardTransactions() async {
    final db = await database;
    return await db.query('reward_transactions', orderBy: 'created_at DESC');
  }

  Future<bool> insertRewardTransaction(Map<String, dynamic> data) async {
    final db = await database;
    try {
      final res = await db.insert('reward_transactions', data, conflictAlgorithm: ConflictAlgorithm.abort);
      return res > 0;
    } catch (e) {
      // Duplicate reward for same date prevented by unique constraint
      debugPrint('[RewardTransaction Ignored] Duplicate: $e');
      return false;
    }
  }

  // --- Withdrawal Requests ---
  Future<List<Map<String, dynamic>>> getWithdrawals(String userId) async {
    final db = await database;
    return await db.query('withdrawal_requests', where: 'user_id = ?', whereArgs: [userId], orderBy: 'submitted_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllWithdrawals({String? status}) async {
    final db = await database;
    if (status != null && status.isNotEmpty && status != 'All') {
      return await db.query('withdrawal_requests', where: 'status = ?', whereArgs: [status], orderBy: 'submitted_at DESC');
    }
    return await db.query('withdrawal_requests', orderBy: 'submitted_at DESC');
  }

  Future<void> upsertWithdrawal(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('withdrawal_requests', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- User Activity & Audit Logs ---
  Future<void> logUserActivity(String userId, String action, String detail) async {
    final db = await database;
    await db.insert('user_activity_logs', {
      'id': 'log_${DateTime.now().microsecondsSinceEpoch}',
      'user_id': userId,
      'action': action,
      'detail': detail,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserActivityLogs({String? userId}) async {
    final db = await database;
    if (userId != null && userId.isNotEmpty) {
      return await db.query('user_activity_logs', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC', limit: 100);
    }
    return await db.query('user_activity_logs', orderBy: 'created_at DESC', limit: 100);
  }

  Future<void> logAdminAudit(String adminId, String action, String targetUserId, String detail) async {
    final db = await database;
    await db.insert('admin_audit_logs', {
      'id': 'audit_${DateTime.now().microsecondsSinceEpoch}',
      'admin_id': adminId,
      'action': action,
      'target_user_id': targetUserId,
      'detail': detail,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAdminAuditLogs() async {
    final db = await database;
    return await db.query('admin_audit_logs', orderBy: 'created_at DESC', limit: 100);
  }

  // --- Users & Profiles Management ---
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'created_at DESC');
  }

  Future<void> updateUserStatus(String userId, String status, {String? reason, String? adminNotes}) async {
    final db = await database;
    await db.update('users', {
      'status': status,
      if (reason != null) 'suspension_reason': reason,
      if (adminNotes != null) 'admin_notes': adminNotes,
    }, where: 'id = ?', whereArgs: [userId]);

    await db.update('local_profiles', {
      'status': status,
      if (reason != null) 'suspension_reason': reason,
      if (adminNotes != null) 'admin_notes': adminNotes,
    }, where: 'id = ?', whereArgs: [userId]);
  }

  // --- Clients (Isolated by user_id) ---
  Future<List<Map<String, dynamic>>> getClients({String? userId}) async {
    final db = await database;
    if (userId != null && userId.isNotEmpty) {
      return await db.query('local_clients', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    }
    return await db.query('local_clients', orderBy: 'created_at DESC');
  }

  Future<void> upsertClient(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_clients', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.delete('local_clients', where: 'id = ?', whereArgs: [id]);
  }

  // --- Client Interactions ---
  Future<List<Map<String, dynamic>>> getInteractions(String clientId) async {
    final db = await database;
    return await db.query('local_interactions', where: 'client_id = ?', whereArgs: [clientId], orderBy: 'date DESC');
  }

  Future<void> upsertInteraction(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_interactions', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Session Management ---
  Future<void> setActiveSession(String userId) async {
    final db = await database;
    await db.insert('active_session', {
      'id': 1,
      'user_id': userId,
      'logged_in_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Redundant file-based persistence for instant auto-login on app restart
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(docDir.path, 'growth_os_active_session.txt'));
      await file.writeAsString(userId);
    } catch (_) {}
  }

  Future<String?> getActiveSessionUserId() async {
    final db = await database;
    try {
      final res = await db.query('active_session', where: 'id = 1');
      if (res.isNotEmpty) {
        final uid = res.first['user_id'] as String?;
        if (uid != null && uid.isNotEmpty) return uid;
      }
    } catch (_) {}

    // Fallback to file-based session
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(docDir.path, 'growth_os_active_session.txt'));
      if (await file.exists()) {
        final uid = (await file.readAsString()).trim();
        if (uid.isNotEmpty) return uid;
      }
    } catch (_) {}

    return null;
  }

  Future<void> clearActiveSession() async {
    final db = await database;
    await db.delete('active_session');
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(docDir.path, 'growth_os_active_session.txt'));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  // --- Sync Queue ---
  Future<void> addToSyncQueue({
    required String table,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': table,
      'record_id': payload['id']?.toString() ?? '',
      'action': operation,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- App Settings (Onboarding flag, etc.) ---
  Future<bool> isOnboardingCompleted() async {
    try {
      final db = await database;
      final res = await db.query('app_settings', where: 'key = ?', whereArgs: ['onboarding_completed']);
      if (res.isNotEmpty) {
        return (res.first['value'] as String?) == '1';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setOnboardingCompleted() async {
    try {
      final db = await database;
      await db.insert('app_settings', {'key': 'onboarding_completed', 'value': '1'},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }
}
