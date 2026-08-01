import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';

class NamesScreen extends ConsumerStatefulWidget {
  const NamesScreen({super.key});

  /// Test-only: clears the process-global "viewed this session" latch. The
  /// production flag deliberately has no other way to reset — it's meant to
  /// survive remounts for the life of the app process — so tests that need a
  /// clean session boundary call this explicitly.
  @visibleForTesting
  static void debugResetSession() {
    _NamesScreenState._viewedThisSession = false;
  }

  @override
  ConsumerState<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends ConsumerState<NamesScreen> {
  // W6 Wave D: `names_browse_viewed`. Static (not per-instance) so the latch
  // survives this screen being unmounted and remounted — e.g. a bottom-nav
  // tab switcher that isn't backed by an IndexedStack would otherwise
  // re-fire `initState` on every visit and inflate the count. Resets only on
  // the next app launch, which is the "per session" the event is scoped to.
  static bool _viewedThisSession = false;

  @override
  void initState() {
    super.initState();
    if (!_viewedThisSession) {
      _viewedThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(analyticsProvider).track(AnalyticsEvents.namesBrowseViewed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('99 Names of Allah')),
      body: const Center(
        child: Text('Names browser will appear here'),
      ),
    );
  }
}
