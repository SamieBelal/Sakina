import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
      await Supabase.instance.client.from(table).delete().eq(column, value);
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

  Future<List<Map<String, dynamic>>> fetchPublicRows(
    String table, {
    String columns = '*',
    String orderBy = 'id',
    bool ascending = true,
    int? limit,
  }) async {
    try {
      var query = Supabase.instance.client
          .from(table)
          .select(columns)
          .order(orderBy, ascending: ascending);
      if (limit != null) query = query.limit(limit);
      final rows = await query;
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('[SupabaseSyncService] fetchPublicRows($table) failed: $e');
      return [];
    }
  }

  Future<String?> getPublicCatalogCache(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(cacheKey);
  }

  Future<void> setPublicCatalogCache(String cacheKey, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, json);
  }

  Future<String?> ensurePublicCatalogCache({
    required String cacheKey,
    required String assetPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final bundled = await rootBundle.loadString(assetPath);
      await prefs.setString(cacheKey, bundled);
      return bundled;
    } catch (e) {
      debugPrint(
        '[SupabaseSyncService] ensurePublicCatalogCache($assetPath) failed: $e',
      );
      return null;
    }
  }

  /// Seed a list-backed Supabase table from the local cached JSON list.
  ///
  /// Used by batch hydration when the RPC explicitly reports that the server
  /// section is empty for the current user.
  ///
  /// [table] — Supabase table name
  /// [cacheKey] — SharedPreferences key (unscoped, will be scoped internally)
  /// [toRows] — converts local JSON list items to Supabase row maps
  Future<void> seedListFromLocalCache({
    required String table,
    required String cacheKey,
    required List<Map<String, dynamic>> Function(
      List<dynamic> localItems,
      String userId,
    ) toRows,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await migrateLegacyStringCache(prefs, cacheKey);
    final scoped = scopedKey(cacheKey);
    final localJson = prefs.getString(scoped);
    if (localJson == null) return;

    final localItems = jsonDecode(localJson) as List<dynamic>;
    if (localItems.isEmpty) return;

    await batchInsertRows(table, toRows(localItems, userId));
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
