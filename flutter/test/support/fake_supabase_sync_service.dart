import 'dart:async';

import 'package:sakina/services/supabase_sync_service.dart';

class FakeSupabaseSyncService extends SupabaseSyncService {
  FakeSupabaseSyncService({this.userId});

  String? userId;
  final Map<String, Map<String, dynamic>?> rows = {};
  final Map<String, List<Map<String, dynamic>>> publicRows = {};
  final List<Map<String, dynamic>> upsertCalls = [];
  final List<Map<String, dynamic>> insertCalls = [];
  final List<Map<String, dynamic>> rpcCalls = [];
  final Map<String, FutureOr<dynamic> Function(Map<String, dynamic>? params)>
      rpcHandlers = {};

  @override
  String? get currentUserId => userId;

  @override
  String scopedKey(String baseKey) {
    if (userId == null || userId!.isEmpty) return baseKey;
    return '$baseKey:$userId';
  }

  @override
  Future<Map<String, dynamic>?> fetchRow(
    String table,
    String userId, {
    String columns = '*',
  }) async {
    return rows['$table:$userId'];
  }

  @override
  Future<bool> upsertRow(
    String table,
    String userId,
    Map<String, dynamic> data,
  ) async {
    upsertCalls.add({
      'table': table,
      'userId': userId,
      'data': data,
    });
    rows['$table:$userId'] = {
      ...(rows['$table:$userId'] ?? <String, dynamic>{}),
      'user_id': userId,
      ...data,
    };
    return true;
  }

  @override
  Future<bool> insertRow(String table, Map<String, dynamic> data) async {
    insertCalls.add({
      'table': table,
      'data': data,
    });
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPublicRows(
    String table, {
    String columns = '*',
    String orderBy = 'id',
    bool ascending = true,
    int? limit,
  }) async {
    final rows = List<Map<String, dynamic>>.from(publicRows[table] ?? const []);
    if (limit != null && rows.length > limit) {
      return rows.take(limit).toList();
    }
    return rows;
  }

  @override
  Future<T?> callRpc<T>(String fn, [Map<String, dynamic>? params]) async {
    rpcCalls.add({
      'fn': fn,
      'params': params ?? <String, dynamic>{},
    });
    final handler = rpcHandlers[fn];
    if (handler == null) return null;
    final result = await handler(params);
    return result as T?;
  }
}
