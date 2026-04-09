import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSyncService {
  static SupabaseSyncService instance = SupabaseSyncService();

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  String scopedKey(String baseKey) {
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return baseKey;
    return '$baseKey:$userId';
  }

  Future<Map<String, dynamic>?> fetchRow(
    String table,
    String userId, {
    String columns = '*',
  }) async {
    try {
      final row = await Supabase.instance.client
          .from(table)
          .select(columns)
          .eq('user_id', userId)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }

  /// Returns `true` when the write succeeds, `false` on any failure.
  Future<bool> upsertRow(
    String table,
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await Supabase.instance.client.from(table).upsert({
        'user_id': userId,
        ...data,
      });
      return true;
    } catch (e) {
      debugPrint('[SupabaseSyncService] upsertRow($table) failed: $e');
      return false;
    }
  }

  /// Returns `true` when the write succeeds, `false` on any failure.
  Future<bool> insertRow(String table, Map<String, dynamic> data) async {
    try {
      await Supabase.instance.client.from(table).insert(data);
      return true;
    } catch (e) {
      debugPrint('[SupabaseSyncService] insertRow($table) failed: $e');
      return false;
    }
  }

  /// Fetch multiple rows for a user, ordered and optionally limited.
  Future<List<Map<String, dynamic>>> fetchRows(
    String table,
    String userId, {
    String columns = '*',
    String orderBy = 'created_at',
    bool ascending = false,
    int? limit,
  }) async {
    try {
      var query = Supabase.instance.client
          .from(table)
          .select(columns)
          .eq('user_id', userId)
          .order(orderBy, ascending: ascending);
      if (limit != null) query = query.limit(limit);
      final rows = await query;
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('[SupabaseSyncService] fetchRows($table) failed: $e');
      return [];
    }
  }

  /// Delete a row by column match.
  Future<bool> deleteRow(String table, String column, dynamic value) async {
    try {
      await Supabase.instance.client
          .from(table)
          .delete()
          .eq(column, value);
      return true;
    } catch (e) {
      debugPrint('[SupabaseSyncService] deleteRow($table) failed: $e');
      return false;
    }
  }

  /// Insert multiple rows in a single request.
  Future<bool> batchInsertRows(
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return true;
    try {
      await Supabase.instance.client.from(table).insert(rows);
      return true;
    } catch (e) {
      debugPrint('[SupabaseSyncService] batchInsertRows($table) failed: $e');
      return false;
    }
  }

  /// Generic list-sync helper. Handles the common pattern:
  /// 1. Check userId  2. Migrate legacy key  3. Fetch from Supabase
  /// 4. If empty → seed from local  5. If not empty → cache from server
  ///
  /// [table] — Supabase table name
  /// [cacheKey] — SharedPreferences key (unscoped, will be scoped internally)
  /// [orderBy] — Supabase column to order by
  /// [toRows] — converts local JSON list items to Supabase row maps
  /// [fromRows] — converts Supabase rows to local JSON list items
  Future<void> syncList({
    required String table,
    required String cacheKey,
    required String orderBy,
    required List<Map<String, dynamic>> Function(
      List<dynamic> localItems, String userId,
    ) toRows,
    required List<Map<String, dynamic>> Function(
      List<Map<String, dynamic>> remoteRows,
    ) fromRows,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await migrateLegacyStringCache(prefs, cacheKey);

    final rows = await fetchRows(table, userId, orderBy: orderBy);
    final scoped = scopedKey(cacheKey);

    if (rows.isEmpty) {
      // Seed Supabase from local if we have data
      final localJson = prefs.getString(scoped);
      if (localJson != null) {
        final localItems = jsonDecode(localJson) as List<dynamic>;
        if (localItems.isNotEmpty) {
          await batchInsertRows(table, toRows(localItems, userId));
        }
      }
      return;
    }

    final localItems = fromRows(rows);
    await prefs.setString(scoped, jsonEncode(localItems));
  }

  Future<T?> callRpc<T>(String fn, [Map<String, dynamic>? params]) async {
    try {
      final result = await Supabase.instance.client.rpc(fn, params: params);
      return result as T?;
    } catch (_) {
      return null;
    }
  }

  Future<int?> migrateLegacyIntCache(
    SharedPreferences prefs,
    String baseKey,
  ) async {
    final scoped = scopedKey(baseKey);
    if (!prefs.containsKey(scoped) && prefs.containsKey(baseKey)) {
      final value = prefs.getInt(baseKey);
      if (value != null) {
        await prefs.setInt(scoped, value);
      }
    }
    return prefs.getInt(scoped);
  }

  Future<String?> migrateLegacyStringCache(
    SharedPreferences prefs,
    String baseKey,
  ) async {
    final scoped = scopedKey(baseKey);
    if (!prefs.containsKey(scoped) && prefs.containsKey(baseKey)) {
      final value = prefs.getString(baseKey);
      if (value != null) {
        await prefs.setString(scoped, value);
      }
    }
    return prefs.getString(scoped);
  }

  Future<List<String>?> migrateLegacyStringListCache(
    SharedPreferences prefs,
    String baseKey,
  ) async {
    final scoped = scopedKey(baseKey);
    if (!prefs.containsKey(scoped) && prefs.containsKey(baseKey)) {
      final value = prefs.getStringList(baseKey);
      if (value != null) {
        await prefs.setStringList(scoped, value);
      }
    }
    return prefs.getStringList(scoped);
  }

  @visibleForTesting
  static void debugSetInstance(SupabaseSyncService service) {
    instance = service;
  }

  @visibleForTesting
  static void debugReset() {
    instance = SupabaseSyncService();
  }
}

SupabaseSyncService get supabaseSyncService => SupabaseSyncService.instance;
