import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AppShell publishes its tab bar's GlobalKey here on first build so the
/// Home tour can anchor its 3rd coachmark to it. AppShell sets this on
/// initState; ProgressScreen reads it via `ref.read`.
///
/// Per-screen ownership: the key itself is owned by AppShell's State. This
/// provider is just the publication channel. Eng review 1.5 explicitly
/// killed the global `TourKeys` provider in favor of this single-key
/// hand-off so the tab bar coachmark anchor can survive across screens
/// without leaking other keys' lifetimes.
final tabBarKeyProvider = StateProvider<GlobalKey?>((_) => null);
