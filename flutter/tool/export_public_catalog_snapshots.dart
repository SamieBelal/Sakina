import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sakina/services/public_catalog_contracts.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help')) {
    stdout.writeln(
      'Usage: dart run tool/export_public_catalog_snapshots.dart '
      '[--supabase-url=URL] [--anon-key=KEY] [--output-dir=assets/content] '
      '[--env-file=.env]',
    );
    return;
  }

  final parsedArgs = _parseArgs(args);
  final env = await _readEnvFile(parsedArgs.envFilePath);

  final supabaseUrl = parsedArgs.supabaseUrl ??
      Platform.environment['SUPABASE_URL'] ??
      env['SUPABASE_URL'];
  final anonKey = parsedArgs.anonKey ??
      Platform.environment['SUPABASE_ANON_KEY'] ??
      env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw StateError('Missing SUPABASE_URL. Set it in the environment or .env');
  }
  if (anonKey == null || anonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_ANON_KEY. Set it in the environment or .env',
    );
  }

  await exportPublicCatalogSnapshots(
    supabaseUrl: supabaseUrl,
    anonKey: anonKey,
    outputDirectory: parsedArgs.outputDirectory,
  );
}

Future<void> exportPublicCatalogSnapshots({
  required String supabaseUrl,
  required String anonKey,
  required String outputDirectory,
  http.Client? client,
  List<PublicCatalogContract> definitions = publicCatalogContracts,
}) async {
  final directory = Directory(outputDirectory);
  await directory.create(recursive: true);

  final normalizedUrl = supabaseUrl.replaceFirst(RegExp(r'/$'), '');
  final activeClient = client ?? http.Client();
  final shouldCloseClient = client == null;
  const encoder = JsonEncoder.withIndent('  ');

  try {
    for (final definition in definitions) {
      final rows = await fetchPublicCatalogRows(
        client: activeClient,
        supabaseUrl: normalizedUrl,
        apiKey: anonKey,
        definition: definition,
      );
      validatePublicCatalogRows(definition, rows);

      final file = File('${directory.path}/${definition.fileName}');
      await file.writeAsString('${encoder.convert(rows)}\n');
      stdout.writeln(
        'Exported ${definition.table} -> ${file.path} (${rows.length} rows)',
      );
    }
  } finally {
    if (shouldCloseClient) {
      activeClient.close();
    }
  }
}

Future<List<Map<String, dynamic>>> fetchPublicCatalogRows({
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
    headers: {
      'apikey': apiKey,
      'Authorization': 'Bearer $apiKey',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Failed to export ${definition.table}: '
              '${response.statusCode} ${response.reasonPhrase ?? ''}'
          .trim(),
      uri: uri,
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! List) {
    throw const FormatException(
        'Expected Supabase response to be a JSON list.');
  }

  return decoded.map((row) {
    if (row is! Map) {
      throw const FormatException(
          'Expected each catalog row to be a JSON map.');
    }
    return Map<String, dynamic>.from(row);
  }).toList();
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
    // Strip surrounding quotes (single or double) to match flutter_dotenv behavior.
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
  String? anonKey;
  var outputDirectory = 'assets/content';
  var envFilePath = '.env';

  for (final arg in args) {
    if (arg.startsWith('--supabase-url=')) {
      supabaseUrl = arg.substring('--supabase-url='.length);
      continue;
    }
    if (arg.startsWith('--anon-key=')) {
      anonKey = arg.substring('--anon-key='.length);
      continue;
    }
    if (arg.startsWith('--output-dir=')) {
      outputDirectory = arg.substring('--output-dir='.length);
      continue;
    }
    if (arg.startsWith('--env-file=')) {
      envFilePath = arg.substring('--env-file='.length);
    }
  }

  return _ParsedArgs(
    supabaseUrl: supabaseUrl,
    anonKey: anonKey,
    outputDirectory: outputDirectory,
    envFilePath: envFilePath,
  );
}

class _ParsedArgs {
  final String? supabaseUrl;
  final String? anonKey;
  final String outputDirectory;
  final String envFilePath;

  const _ParsedArgs({
    required this.supabaseUrl,
    required this.anonKey,
    required this.outputDirectory,
    required this.envFilePath,
  });
}
