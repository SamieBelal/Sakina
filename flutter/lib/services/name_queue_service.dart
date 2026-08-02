import 'package:supabase_flutter/supabase_flutter.dart';

/// One row of `user_name_queue` — the 7-Name acquisition promise.
class NameQueueRow {
  const NameQueueRow({
    required this.position,
    required this.nameId,
    this.unsealedAt,
  });

  /// 1-7. Position 1 is the Name met at the onboarding reveal (born unsealed
  /// server-side); 2 is the sealed partner; 3-7 come from the aspiration map.
  final int position;
  final int nameId;

  /// Null while the position is still sealed.
  final DateTime? unsealedAt;

  bool get isSealed => unsealedAt == null;

  factory NameQueueRow.fromJson(Map<String, dynamic> json) {
    final raw = json['unsealed_at'];
    return NameQueueRow(
      position: (json['position'] as num).toInt(),
      nameId: (json['name_id'] as num).toInt(),
      unsealedAt: raw is String ? DateTime.tryParse(raw) : null,
    );
  }
}

/// Client for the W1 `user_name_queue` objects: an RLS select of the user's own
/// rows plus the two SECURITY DEFINER RPCs.
///
/// **Nothing here swallows a raise.** `seed_name_queue` uses the same
/// `check_violation` errcode for "already seeded", "wrong length" AND
/// "duplicate ids", so a `catch (_)` would hide a wholesale seed failure behind
/// the benign case and leave the user with a dead W3 unseal. Hence
/// [seedIfEmpty] pre-checks with a SELECT and lets every error out — the
/// deliberate reason this service does not go through
/// `SupabaseSyncService.callRpc`, which returns null on failure.
///
/// Binding (W1 review note): unsealing a Name never grants tokens/XP/tier. The
/// queue only decides WHICH Name; the card award goes through the existing
/// economy path.
class NameQueueService {
  NameQueueService({
    Future<List<Map<String, dynamic>>> Function(String userId)? selectRows,
    Future<dynamic> Function(String fn, Map<String, dynamic>? params)? callRpc,
    String? Function()? currentUserId,
  })  : _selectRows = selectRows ?? _defaultSelectRows,
        _callRpc = callRpc ?? _defaultCallRpc,
        _currentUserId = currentUserId ?? _defaultCurrentUserId;

  static const String tableName = 'user_name_queue';
  static const String seedRpcName = 'seed_name_queue';
  static const String unsealRpcName = 'unseal_next_name';

  final Future<List<Map<String, dynamic>>> Function(String userId) _selectRows;
  final Future<dynamic> Function(String fn, Map<String, dynamic>? params)
      _callRpc;
  final String? Function() _currentUserId;

  /// The user's own queue, ordered by position. Empty when unauthenticated.
  Future<List<NameQueueRow>> queue() async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) return const [];
    final rows = await _selectRows(userId);
    return rows.map(NameQueueRow.fromJson).toList(growable: false)
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Seeds the queue once, at onboarding completion.
  ///
  /// Pre-checks with the RLS select: rows already exist → no-op (the honest
  /// idempotent case, including a re-run of `completeOnboarding`). Zero rows →
  /// call the RPC, and let ANY failure propagate to the caller.
  ///
  /// Returns true when this call did the seeding, false when it found a queue
  /// already there.
  Future<bool> seedIfEmpty(List<int> nameIds) async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('$seedRpcName requires an authenticated user');
    }
    final existing = await _selectRows(userId);
    if (existing.isNotEmpty) return false;
    await _callRpc(seedRpcName, {'p_name_ids': nameIds});
    return true;
  }

  /// Unseals the next sealed position, or returns the row already unsealed
  /// today (the RPC is idempotent per user-local day). Null when the queue is
  /// exhausted. W3 owns the caller; this is the client half landed early so the
  /// W3 change is one call site.
  Future<NameQueueRow?> unsealNext() async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError('$unsealRpcName requires an authenticated user');
    }
    final result = await _callRpc(unsealRpcName, null);
    if (result is! List || result.isEmpty) return null;
    return NameQueueRow.fromJson(Map<String, dynamic>.from(result.first as Map));
  }
}

Future<List<Map<String, dynamic>>> _defaultSelectRows(String userId) async {
  final rows = await Supabase.instance.client
      .from(NameQueueService.tableName)
      .select('position, name_id, unsealed_at')
      .eq('user_id', userId)
      .order('position');
  return List<Map<String, dynamic>>.from(rows);
}

Future<dynamic> _defaultCallRpc(String fn, Map<String, dynamic>? params) =>
    Supabase.instance.client.rpc(fn, params: params);

String? _defaultCurrentUserId() =>
    Supabase.instance.client.auth.currentUser?.id;
