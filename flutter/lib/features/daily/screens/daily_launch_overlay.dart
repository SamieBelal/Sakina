import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/streaks/providers/companion_inputs_provider.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/services/daily_question_gate.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/core/app_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — push as a full-screen opaque route
// ─────────────────────────────────────────────────────────────────────────────

class DailyLaunchOverlay extends ConsumerStatefulWidget {
  const DailyLaunchOverlay({super.key});

  @override
  ConsumerState<DailyLaunchOverlay> createState() => _DailyLaunchOverlayState();
}

class _DailyLaunchOverlayState extends ConsumerState<DailyLaunchOverlay> {
  AppSessionNotifier?
      _session; // Captured ref so listener cleanup works after dispose

  /// Captured so the listener can be removed after dispose, when `context` is
  /// no longer usable to look the router up.
  GoRouter? _router;

  /// Set the instant this route starts leaving, by any path. Without it the
  /// location listener below would fire on our own `go('/muhasabah')` and pop a
  /// second time — taking the question route with it.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // Both day-open markers, stamped at the moment the app ASKS (W4 Wave 4).
    //
    // The UTC one keeps subsequent opens quiet for the rest of the reward day.
    // The user-local one is what makes "auto-entry at most once per local day"
    // hold however the user leaves this screen — including the system back
    // gesture, which is not a defer and used to leave them open to being asked
    // again. See `daily_question_gate.dart` for why the two clocks differ and
    // which way their disagreement is allowed to fall.
    markDailyLaunchShown();
    markDailyQuestionAutoEnteredToday();
    // Economy hydration for the home screen behind this route. It no longer
    // gates anything drawn here — the reward strip this used to block on is
    // gone (W4 Wave 4) — so nothing on this screen waits on a network hop, and
    // the frame paints immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Armed FIRST, before any await, because the thing it guards against is a
      // navigation that lands while this screen is still doing its own setup.
      _router = GoRouter.of(context);
      _router!.routerDelegate.addListener(_onLocationChanged);
      final session = ref.read(appSessionProvider);
      _session = session;
      if (!session.economyHydrated) {
        session.addListener(_onSessionChange);
      } else {
        // Hydration already complete — refresh economy + scroll state now.
        ref.read(dailyLoopProvider.notifier).refreshEconomyState();
        ref.read(tierUpScrollProvider.notifier).reload();
      }

      // Kept, though nothing here renders it: `shouldShowDailyLaunch()` reads
      // `claimedToday` on the next open, and Home's daily-rewards row reads the
      // same cache. Still bounded — a hung network must not leave the reward
      // state pinned stale behind an await nobody can see.
      try {
        await ref
            .read(dailyRewardsProvider.notifier)
            .reload()
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Swallow timeout / network errors — the local cache stands.
      }
    });
  }

  void _onSessionChange() {
    if (!mounted) {
      _session?.removeListener(_onSessionChange);
      return;
    }
    final session = _session;
    if (session != null && session.economyHydrated) {
      session.removeListener(_onSessionChange);
      ref.read(dailyLoopProvider.notifier).refreshEconomyState();
      ref.read(dailyRewardsProvider.notifier).reload();
      ref.read(tierUpScrollProvider.notifier).reload();
    }
  }

  /// Gets out of the way when the app navigates somewhere else while the
  /// day-open is up (W4 Wave 4 review, F2).
  ///
  /// The push site checks the location immediately before presenting, which
  /// catches a widget deep link that has ALREADY landed. It cannot catch one
  /// that lands a moment later: `parseWidgetDeepLink` maps the duʿā widget to
  /// `/duas`, which lives inside the `ShellRoute`, so `.go('/duas')` swaps the
  /// shell's child *underneath* this opaque root-navigator route and leaves it
  /// sitting on top. The user asked for their duʿā times and got a full-screen
  /// prompt about their heart, with one obvious button on it.
  ///
  /// It is not enough that dismissing costs only a tap. That tap is the
  /// likeliest thing a person does when an unexpected full-screen overlay
  /// appears, and the button routes into the muḥāsabah — so "they consented,
  /// their finger moved" is not a defence. Auto-entry must never become a
  /// hijacking: if the user has gone somewhere else, the day-open has missed
  /// its moment and waits for the home CTA.
  void _onLocationChanged() {
    if (_leaving || !mounted) return;
    final path = _router?.routerDelegate.currentConfiguration.uri.path;
    if (path == null || path == '/') return;
    _leaving = true;
    // Deferred because this fires from inside the router's own notification,
    // where popping would mutate the navigator mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // `mounted` is NOT sufficient, and assuming it was cost a real bug in
      // review: go_router removes an imperatively-pushed root route by itself
      // when the app `.go()`s to another ROOT route (`/muhasabah`), but not to
      // one inside the ShellRoute (`/duas`). In the root case this route is
      // already on its way out — still mounted, animating — so a bare `pop()`
      // here lands on the route UNDERNEATH and destroys the destination the
      // user was navigating to. Popping the question route is a worse bug than
      // the one this listener exists to fix.
      //
      // `isCurrent` is the precise question: pop only if we are still the route
      // on top. Pinned both ways in `day_open_routing_test.dart`.
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) return;
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChange);
    _router?.routerDelegate.removeListener(_onLocationChanged);
    super.dispose();
  }

  /// Hands off into the day's question (W4 Wave 4 — spec M1).
  ///
  /// **Pops before it routes, and the order is load-bearing.** This route is
  /// pushed `opaque: true` on the ROOT navigator, so a bare `go('/muhasabah')`
  /// would leave the day-open mounted *underneath* the muḥāsabah route — and a
  /// back gesture from the question would land the user right back in the
  /// day-open they just left. The router is captured before the pop because
  /// [context] is defunct immediately after it.
  void _beginMuhasabah() {
    HapticFeedback.lightImpact();
    // Flagged before either navigation so [_onLocationChanged] does not treat
    // our own `go('/muhasabah')` as somebody else navigating away and pop a
    // second time.
    _leaving = true;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go('/muhasabah');
  }

  /// The escape hatch (plan §2 rule 7). Someone who opened the app for their
  /// duʿā times must be able to get past the day-open without declaring
  /// anything about their heart.
  void _dismiss() {
    HapticFeedback.lightImpact();
    _leaving = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _AmbientFrame(
          onBegin: _beginMuhasabah,
          onDismiss: _dismiss,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The ambient frame — streak state, glanceable, then into the question
// ─────────────────────────────────────────────────────────────────────────────

/// The whole day-open (W4 Wave 4 — spec M1).
///
/// **Streak state before, quiet and glanceable; ceremony after the work.** This
/// used to be step 0 of a two-step gate whose step 1 was the reward claim; the
/// claim moved to answer-submit (Wave 3) and the celebration moved behind
/// "Ameen", so what is left is not a ceremony at all. It is a frame: where the
/// user stands, and one tap into the day's question.
///
/// **It shows no Name, and that is the point** (founder, 2026-07-30). It used to
/// render `getTodaysName()` — a date rotation of its own — in a gold card
/// labelled "Today's Name". While the overlay merely dismissed to home that was
/// an inconsistency you had to go looking for; now that it hands straight into
/// the question, it would read *"Today's Name: As-Salam"* → answer → **a
/// different Name from the queue**, seconds apart, in one unbroken flow. That is
/// the app contradicting itself inside a single interaction. The day-0 branch
/// went with it even though `starterNameProvider` is honest data, because
/// framing any Name as the day's immediately before a different reveal is the
/// same broken promise.
///
/// So: the Name stops being something we show on the way in, and becomes the
/// thing the user is about to earn. (This also removes one of the three
/// disagreeing "today's Name" notions outright rather than reconciling it —
/// spec §9a.)
class _AmbientFrame extends ConsumerWidget {
  const _AmbientFrame({required this.onBegin, required this.onDismiss});

  final VoidCallback onBegin;

  /// The way past the day-open for someone who opened the app for something
  /// else entirely. Never a dead end (plan §2 rule 7).
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(dailyLoopProvider).streakCount;
    final companion = ref.watch(companionStateProvider);
    final greeting = _timeGreeting();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The living companion — arrives at the current streak state; the
          // muḥāsabah completed later lights it. Replaces the static flame.
          SizedBox(
            height: 96,
            child: companion == null
                ? const SizedBox(width: 96)
                : Center(
                    child: CompanionMedallion(
                      state: companion,
                      size: 96,
                      skin: ref.watch(renderableLanternSkinProvider),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Streak count
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              children: [
                TextSpan(
                  text: '$streak',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.streakAmber,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: '\nday streak'),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 150.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          Text(
            greeting,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

          const SizedBox(height: 48),

          // The hand-off. Named for the job, not the jargon — muḥāsabah is
          // taught as a gloss on the question surface itself, never as a button
          // (plan §4).
          _PrimaryButton(
            label: 'Begin today',
            onTap: onBegin,
          ).animate().fadeIn(duration: 400.ms, delay: 450.ms),

          const SizedBox(height: 8),

          // The escape hatch, quiet but present and a full 44pt target. Someone
          // who opened the app for their duʿā times has to be able to get past
          // this without declaring anything about their heart.
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: AppColors.textTertiaryLight,
            ),
            child: Text(
              'Not now',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
        ],
      ),
    );
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Assalamu Alaykum. Allah is with you.';
    // Not "take a moment to reflect" — Reflect is a distinct feature tab, and
    // the day-open must not look like it is pointing there.
    if (h < 17) return 'Assalamu Alaykum. Take a moment.';
    return 'Assalamu Alaykum. End the day with remembrance.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared — Primary button
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
