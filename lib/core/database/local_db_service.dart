import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

/// Local Offline Database Service for GROWTH OS
/// Provides zero-latency offline persistence and automatic sync queueing
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

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
      version: 1,
      onCreate: (db, version) async {
        // 1. Local Profiles
        await db.execute('''
          CREATE TABLE local_profiles (
            id TEXT PRIMARY KEY,
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
            streak_count INTEGER,
            is_admin INTEGER DEFAULT 0
          )
        ''');

        // 2. Local Projects
        await db.execute('''
          CREATE TABLE local_projects (
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

        // 3. Local Stages
        await db.execute('''
          CREATE TABLE local_stages (
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

        // 4. Local Updates
        await db.execute('''
          CREATE TABLE local_updates (
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

        // 5. Income Entries
        await db.execute('''
          CREATE TABLE local_income (
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

        // 6. Expense Entries
        await db.execute('''
          CREATE TABLE local_expenses (
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

        // 7. Clients
        await db.execute('''
          CREATE TABLE local_clients (
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

        // 8. Client Interactions
        await db.execute('''
          CREATE TABLE local_interactions (
            id TEXT PRIMARY KEY,
            client_id TEXT,
            interaction_type TEXT,
            notes TEXT,
            date TEXT
          )
        ''');

        // 9. Sync Queue
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT,
            record_id TEXT,
            action TEXT,
            payload TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  // --- Projects ---
  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
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

  // --- Income ---
  Future<List<Map<String, dynamic>>> getIncome() async {
    final db = await database;
    return await db.query('local_income', orderBy: 'date DESC');
  }

  Future<void> upsertIncome(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_income', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Expenses ---
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.query('local_expenses', orderBy: 'date DESC');
  }

  Future<void> upsertExpense(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_expenses', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Clients ---
  Future<List<Map<String, dynamic>>> getClients() async {
    final db = await database;
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
}
