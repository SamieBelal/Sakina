import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listens to a Riverpod provider and surfaces its `error` field as a SnackBar
/// whenever it transitions from one value to another non-null value.
///
/// Used by `journal_screen.dart` to surface optimistic-rollback failures from
/// `reflectProvider` (deleteReflection) and `duasProvider` (removeSavedBuiltDua,
/// removeSavedRelatedDua). Without this, those providers' `state.error` values
/// were only rendered on the Reflect input screen, so a delete-while-offline
/// in Journal silently rolled back with no user feedback.
///
/// Calls `hideCurrentSnackBar` before showing so toasts don't stack across
/// rapid retries.
class ProviderErrorSnackBarListener<T> extends ConsumerWidget {
  const ProviderErrorSnackBarListener({
    super.key,
    required this.provider,
    required this.errorOf,
    required this.child,
  });

  final ProviderListenable<T> provider;
  final String? Function(T state) errorOf;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<T>(provider, (prev, next) {
      final err = errorOf(next);
      if (err == null) return;
      final prevErr = prev == null ? null : errorOf(prev);
      if (err == prevErr) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(err)));
    });
    return child;
  }
}
