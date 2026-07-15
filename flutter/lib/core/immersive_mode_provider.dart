import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while a surface inside the bottom-nav shell wants to render full-screen
/// (the beat reveal flow's emerald canvas). [AppShell] hides the bottom nav bar
/// while this is set, so the immersive surface fills the whole screen. Root
/// routes like `/muhasabah` are already full-screen and don't need this.
///
/// Set it true when the immersive surface appears and false when it leaves; the
/// setter should be self-healing (re-evaluated on every build) so the flag can
/// never get stuck if the surface is torn down unexpectedly.
final immersiveModeProvider = StateProvider<bool>((ref) => false);
