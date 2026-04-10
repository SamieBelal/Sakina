import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sakina/services/public_catalog_contracts.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help')) {
    stdout.writeln(
      'Usage: dart run tool/import_public_catalog_snapshots.dart '
      '[--supabase-url=URL] [--service-role-key=KEY] '
      '[--anon-key=KEY] [--input-dir=assets/content] [--env-file=.env] '
      '[--dry-run] [--verify-anon-read]',
    );
    return;
  }

  final parsedArgs = _parseArgs(args);
  final env = await _readEnvFile(parsedArgs.envFilePath);

  final supabaseUrl = parsedArgs.supabaseUrl ??
      Platform.environment['SUPABASE_URL'] ??
      env['SUPABASE_URL'];
  final serviceRoleKey = parsedArgs.serviceRoleKey ??
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
      env['SUPABASE_SERVICE_ROLE_KEY'];
  final anonKey = parsedArgs.anonKey ??
      Platform.environment['SUPABASE_ANON_KEY'] ??
      env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw StateError('Missing SUPABASE_URL. Set it in the environment or .env');
  }
  if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_SERVICE_ROLE_KEY. Set it in the environment or .env',
    );
  }
  if (parsedArgs.verifyAnonRead && (anonKey == null || anonKey.isEmpty)) {
    throw StateError(
      'Missing SUPABASE_ANON_KEY. Required when --verify-anon-read is set.',
    );
  }

  await importPublicCatalogSnapshots(
    supabaseUrl: supabaseUrl,
    serviceRoleKey: serviceRoleKey,
    anonKey: anonKey,
    inputDirectory: parsedArgs.inputDirectory,
    dryRun: parsedArgs.dryRun,
    verifyAnonRead: parsedArgs.verifyAnonRead,
  );
}

Future<void> importPublicCatalogSnapshots({
  required String supabaseUrl,
  required String serviceRoleKey,
  required String inputDirectory,
  String? anonKey,
  bool dryRun = false,
  bool verifyAnonRead = false,
  http.Client? client,
  List<PublicCatalogContract> definitions = publicCatalogContracts,
}) async {
  final snapshots = await _loadSnapshots(
    inputDirectory: inputDirectory,
    definitions: definitions,
  );

  if (dryRun) {
    for (final snapshot in snapshots) {
      stdout.writeln(
        'Validated ${snapshot.definition.table} from ${snapshot.file.path} '
        '(${snapshot.rows.length} rows)',
      );
    }
    stdout.writeln('Dry run complete. No remote changes applied.');
    return;
  }

  final normalizedUrl = supabaseUrl.replaceFirst(RegExp(r'/$'), '');
  final activeClient = client ?? http.Client();
  final shouldCloseClient = client == null;

  try {
    for (final snapshot in snapshots) {
      final definition = snapshot.definition;
      final remoteRows = await _fetchRows(
        client: activeClient,
        supabaseUrl: normalizedUrl,
        apiKey: serviceRoleKey,
        definition: definition,
      );

      await _upsertRows(
        client: activeClient,
        supabaseUrl: normalizedUrl,
        apiKey: serviceRoleKey,
        definition: definition,
        rows: snapshot.rows,
      );

      final localPrimaryKeys = snapshot.rows
          .map((row) => _primaryKeySignature(definition, row))
          .toSet();
      for (final row in remoteRows) {
        if (localPrimaryKeys.contains(_primaryKeySignature(definition, row))) {
          continue;
        }
        await _deleteRow(
          client: activeClient,
          supabaseUrl: normalizedUrl,
          apiKey: serviceRoleKey,
          definition: definition,
          primaryKeyValue: row[definition.primaryKey],
        );
      }

      final verifiedRows = await _fetchRows(
        client: activeClient,
        supabaseUrl: normalizedUrl,
        apiKey: serviceRoleKey,
        definition: definition,
      );
      validatePublicCatalogRows(definition, verifiedRows);
      _assertRowsMatch(
        definition: definition,
        expectedRows: snapshot.rows,
        actualRows: verifiedRows,
        audienceLabel: 'service role',
      );

      stdout.writeln(
        'Seeded ${definition.table} (${snapshot.rows.length} rows)',
      );

      if (!verifyAnonRead) continue;

      final anonRows = await _fetchRows(
        client: activeClient,
        supabaseUrl: normalizedUrl,
        apiKey: anonKey!,
        definition: definition,
      );
      validatePublicCatalogRows(definition, anonRows);
      _assertRowsMatch(
        definition: definition,
        expectedRows: snapshot.rows,
        actualRows: anonRows,
        audienceLabel: 'anon',
      );
      stdout.writeln(
        'Verified anon-read for ${definition.table} (${anonRows.length} rows)',
      );
    }
  } finally {
    if (shouldCloseClient) {
      activeClient.close();
    }
  }
}

class _LoadedSnapshot {
  final PublicCatalogContract definition;
  final File file;
  final List<Map<String, dynamic>> rows;

  const _LoadedSnapshot({
    required this.definition,
    required this.file,
    required this.rows,
  });
}

Future<List<_LoadedSnapshot>> _loadSnapshots({
  required String inputDirectory,
  required List<PublicCatalogContract> definitions,
}) async {
  final snapshots = <_LoadedSnapshot>[];

  for (final definition in definitions) {
    final file = File('$inputDirectory/${definition.fileName}');
    if (!await file.exists()) {
      throw StateError('Missing snapshot file: ${file.path}');
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      throw StateError(
        'Expected ${file.path} to contain a JSON list for ${definition.table}.',
      );
    }

    final rows = decoded.map((row) {
      if (row is! Map) {
        throw StateError(
          'Expected every row in ${file.path} to be a JSON object.',
        );
      }
      return Map<String, dynamic>.from(row);
    }).toList();

    validatePublicCatalogRows(definition, rows);
    snapshots.add(
      _LoadedSnapshot(
        definition: definition,
        file: file,
        rows: rows,
      ),
    );
  }

  return snapshots;
}

Future<List<Map<String, dynamic>>> _fetchRows({
  required http.Client client,
  required String supabaseUrl,
  required String apiKey,
  required PublicCatalogContract definition,
}) async {
  final uri = Uri.parse('$supabaseUrl/rest/v1/${definition.table}').replace(
    queryParameters: {
      'select': '*',
      'order': '${definition.orderBy}.asc',
    },
  );

  final response = await client.get(
    uri,
    headers: _headersForApiKey(apiKey),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Failed to fetch ${definition.table}: '
              '${response.statusCode} ${response.reasonPhrase ?? ''}'
          .trim(),
      uri: uri,
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! List) {
    throw const FormatException(
      'Expected Supabase response to be a JSON list.',
    );
  }

  return decoded.map((row) {
    if (row is! Map) {
      throw const FormatException(
        'Expected each catalog row to be a JSON map.',
      );
    }
    return Map<String, dynamic>.from(row);
  }).toList();
}

Future<void> _upsertRows({
  required http.Client client,
  required String supabaseUrl,
  required String apiKey,
  required PublicCatalogContract definition,
  required List<Map<String, dynamic>> rows,
}) async {
  final uri = Uri.parse('$supabaseUrl/rest/v1/${definition.table}').replace(
    queryParameters: {
      'on_conflict': definition.primaryKey,
    },
  );

  final response = await client.post(
    uri,
    headers: {
      ..._headersForApiKey(apiKey),
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates,return=minimal',
    },
    body: jsonEncode(rows),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Failed to upsert ${definition.table}: '
              '${response.statusCode} ${response.reasonPhrase ?? ''}'
          .trim(),
      uri: uri,
    );
  }
}

Future<void> _deleteRow({
  required http.Client client,
  required String supabaseUrl,
  required String apiKey,
  required PublicCatalogContract definition,
  required Object? primaryKeyValue,
}) async {
  if (primaryKeyValue == null) {
    throw StateError(
      'Cannot delete row from ${definition.table} without '
      '${definition.primaryKey}.',
    );
  }

  final uri = Uri.parse('$supabaseUrl/rest/v1/${definition.table}').replace(
    queryParameters: {
      definition.primaryKey: 'eq.$primaryKeyValue',
    },
  );

  final response = await client.delete(
    uri,
    headers: {
      ..._headersForApiKey(apiKey),
      'Prefer': 'return=minimal',
    },
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Failed to delete stale row from ${definition.table}: '
              '${response.statusCode} ${response.reasonPhrase ?? ''}'
          .trim(),
      uri: uri,
    );
  }
}

Map<String, String> _headersForApiKey(String apiKey) {
  return {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Accept': 'application/json',
  };
}

String _primaryKeySignature(
  PublicCatalogContract definition,
  Map<String, dynamic> row,
) {
  return '${definition.primaryKey}:${row[definition.primaryKey]}';
}

void _assertRowsMatch({
  required PublicCatalogContract definition,
  required List<Map<String, dynamic>> expectedRows,
  required List<Map<String, dynamic>> actualRows,
  required String audienceLabel,
}) {
  final expectedJson = jsonEncode(
    _canonicalizeValue(_sortRowsForComparison(definition, expectedRows)),
  );
  final actualJson = jsonEncode(
    _canonicalizeValue(_sortRowsForComparison(definition, actualRows)),
  );
  if (expectedJson == actualJson) return;

  throw StateError(
    '${definition.table} $audienceLabel verification returned data that does '
    'not exactly match the checked-in snapshot.',
  );
}

List<Map<String, dynamic>> _sortRowsForComparison(
  PublicCatalogContract definition,
  List<Map<String, dynamic>> rows,
) {
  final copy = rows.map(Map<String, dynamic>.from).toList();
  copy.sort((left, right) {
    final leftValue = left[definition.orderBy] as Comparable<dynamic>;
    final rightValue = right[definition.orderBy] as Comparable<dynamic>;
    return leftValue.compareTo(rightValue);
  });
  return copy;
}

Object? _canonicalizeValue(Object? value) {
  if (value is List) {
    return value.map(_canonicalizeValue).toList();
  }
  if (value is Map) {
    final sortedKeys = value.keys.map((key) => key.toString()).toList()..sort();
    return SplayTreeMap<String, Object?>.fromIterables(
      sortedKeys,
      sortedKeys.map((key) => _canonicalizeValue(value[key])),
    );
  }
  return value;
}

Future<Map<String, String>> _readEnvFile(String path) async {
  final file = File(path);
  if (!await file.exists()) return const {};

  final values = <String, String>{};
  final lines = await file.readAsLines();
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    final separatorIndex = trimmed.indexOf('=');
    if (separatorIndex <= 0) continue;

    final key = trimmed.substring(0, separatorIndex).trim();
    var value = trimmed.substring(separatorIndex + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}

_ParsedArgs _parseArgs(List<String> args) {
  String? supabaseUrl;
  String? serviceRoleKey;
  String? anonKey;
  var inputDirectory = 'assets/content';
  var envFilePath = '.env';
  var dryRun = false;
  var verifyAnonRead = false;

  for (final arg in args) {
    if (arg.startsWith('--supabase-url=')) {
      supabaseUrl = arg.substring('--supabase-url='.length);
      continue;
    }
    if (arg.startsWith('--service-role-key=')) {
      serviceRoleKey = arg.substring('--service-role-key='.length);
      continue;
    }
    if (arg.startsWith('--anon-key=')) {
      anonKey = arg.substring('--anon-key='.length);
      continue;
    }
    if (arg.startsWith('--input-dir=')) {
      inputDirectory = arg.substring('--input-dir='.length);
      continue;
    }
    if (arg.startsWith('--env-file=')) {
      envFilePath = arg.substring('--env-file='.length);
      continue;
    }
    if (arg == '--dry-run') {
      dryRun = true;
      continue;
    }
    if (arg == '--verify-anon-read') {
      verifyAnonRead = true;
    }
  }

  return _ParsedArgs(
    supabaseUrl: supabaseUrl,
    serviceRoleKey: serviceRoleKey,
    anonKey: anonKey,
    inputDirectory: inputDirectory,
    envFilePath: envFilePath,
    dryRun: dryRun,
    verifyAnonRead: verifyAnonRead,
  );
}

class _ParsedArgs {
  final String? supabaseUrl;
  final String? serviceRoleKey;
  final String? anonKey;
  final String inputDirectory;
  final String envFilePath;
  final bool dryRun;
  final bool verifyAnonRead;

  const _ParsedArgs({
    required this.supabaseUrl,
    required this.serviceRoleKey,
    required this.anonKey,
    required this.inputDirectory,
    required this.envFilePath,
    required this.dryRun,
    required this.verifyAnonRead,
  });
}
