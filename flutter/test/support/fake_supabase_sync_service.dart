import 'dart:async';

import 'package:sakina/services/supabase_sync_service.dart';

class FakeSupabaseSyncService extends SupabaseSyncService {
  FakeSupabaseSyncService({this.userId});

  String? userId;
  final Map<String, Map<String, dynamic>?> rows = {};
  final Map<String, List<Map<String, dynamic>>> rowLists = {};
  final Map<String, List<Map<String, dynamic>>> publicRows = {};
  final List<Map<String, dynamic>> upsertCalls = [];
  final List<Map<String, dynamic>> rawUpsertCalls = [];
  final List<Map<String, dynamic>> insertCalls = [];
  final List<Map<String, dynamic>> batchInsertCalls = [];
  final List<Map<String, dynamic>> deleteCalls = [];
  final List<Map<String, dynamic>> rpcCalls = [];
  final Map<String, FutureOr<dynamic> Function(Map<String, dynamic>? params)>
      rpcHandlers = {};
  int _nextSyntheticId = 1;

  /// When set, the next upsert-style write (upsertRow / upsertRawRow) will
  /// return `false` without touching storage, then reset to `false`. Use to
  /// exercise the failure path in sync-service callers.
  bool nextUpsertShouldFail = false;

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
    Map<String, dynamic> data, {
    String? onConflict,
  }) async {
    upsertCalls.add({
      'table': table,
      'userId': userId,
      'data': data,
      'onConflict': onConflict,
    });

    if (nextUpsertShouldFail) {
      nextUpsertShouldFail = false;
      return false;
    }

    // Merge user_id + data into the row payload, matching production behavior.
    final merged = <String, dynamic>{
      'user_id': userId,
      ...data,
    };

    return _applyUpsert(
      table,
      merged,
      onConflict: onConflict,
      singleRowKey: '$table:$userId',
    );
  }

  @override
  Future<bool> upsertRawRow(
    String table,
    Map<String, dynamic> data, {
    String? onConflict,
  }) async {
    rawUpsertCalls.add({
      'table': table,
      'data': data,
      'onConflict': onConflict,
    });

    if (nextUpsertShouldFail) {
      nextUpsertShouldFail = false;
      return false;
    }

    String? singleRowKey;
    final id = data['id'];
    if (id != null) {
      singleRowKey = '$table:$id';
    }

    return _applyUpsert(
      table,
      Map<String, dynamic>.from(data),
      onConflict: onConflict,
      singleRowKey: singleRowKey,
    );
  }

  @override
  Future<bool> insertRow(String table, Map<String, dynamic> data) async {
    final normalized = Map<String, dynamic>.from(data);
    normalized.putIfAbsent('id', () => 'fake-${_nextSyntheticId++}');
    insertCalls.add({
      'table': table,
      'data': normalized,
    });
    final list = rowLists.putIfAbsent(table, () => []);
    list.add(normalized);
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRows(
    String table,
    String userId, {
    String columns = '*',
    String orderBy = 'created_at',
    bool ascending = false,
    int? limit,
  }) async {
    final all = rowLists[table] ?? const <Map<String, dynamic>>[];
    final filtered = all
        .where((row) => row['user_id'] == userId)
        .map(Map<String, dynamic>.from)
        .toList();
    if (limit != null && filtered.length > limit) {
      return filtered.take(limit).toList();
    }
    return filtered;
  }

  @override
  Future<bool> batchInsertRows(
    String table,
    List<Map<String, dynamic>> rowsToInsert,
  ) async {
    batchInsertCalls.add({
      'table': table,
      'rows': rowsToInsert,
    });
    final list = rowLists.putIfAbsent(table, () => []);
    for (final row in rowsToInsert) {
      final normalized = Map<String, dynamic>.from(row);
      normalized.putIfAbsent('id', () => 'fake-${_nextSyntheticId++}');
      list.add(normalized);
    }
    return true;
  }

  @override
  Future<bool> deleteRow(String table, String column, dynamic value) async {
    deleteCalls.add({
      'table': table,
      'column': column,
      'value': value,
    });
    final list = rowLists[table];
    if (list != null) {
      list.removeWhere((row) => row[column] == value);
    }
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
    if (result == null) return null;
    if (T == int && result is num) {
      return result.toInt() as T;
    }
    return result as T;
  }

  Future<bool> _applyUpsert(
    String table,
    Map<String, dynamic> merged, {
    String? onConflict,
    String? singleRowKey,
  }) async {
    if (onConflict != null && onConflict.isNotEmpty) {
      final conflictCols = onConflict.split(',').map((s) => s.trim()).toList();
      final list = rowLists.putIfAbsent(table, () => []);
      final existingIdx = list.indexWhere((row) {
        for (final col in conflictCols) {
          if (row[col] != merged[col]) return false;
        }
        return true;
      });
      if (existingIdx >= 0) {
        list[existingIdx] = {...list[existingIdx], ...merged};
      } else {
        final normalized = Map<String, dynamic>.from(merged);
        normalized.putIfAbsent('id', () => 'fake-${_nextSyntheticId++}');
        list.add(normalized);
      }

      if (singleRowKey != null &&
          conflictCols.length == 1 &&
          merged.containsKey(conflictCols.single)) {
        rows[singleRowKey] = {...merged};
      }
      return true;
    }

    if (singleRowKey != null) {
      rows[singleRowKey] = {
        ...(rows[singleRowKey] ?? <String, dynamic>{}),
        ...merged,
      };
      return true;
    }

    final list = rowLists.putIfAbsent(table, () => []);
    final normalized = Map<String, dynamic>.from(merged);
    normalized.putIfAbsent('id', () => 'fake-${_nextSyntheticId++}');
    list.add(normalized);
    return true;
  }
}
