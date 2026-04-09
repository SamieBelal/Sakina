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
