# sakina

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Public Catalog Tools

Export the live public catalogs from Supabase into the checked-in snapshots:

```bash
dart run tool/export_public_catalog_snapshots.dart
```

Seed the checked-in public catalogs back into Supabase with a service-role key:

```bash
dart run tool/import_public_catalog_snapshots.dart --verify-anon-read
```

The import tool expects:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY` when `--verify-anon-read` is used

Useful flags:

- `--input-dir=assets/content`
- `--env-file=.env`
- `--dry-run`
- `--verify-anon-read`
