/// The Journal's *new reflection* composer (2026-08-07).
///
/// **What this replaces.** The Reflect tab. That surface owned the same engine
/// this one does — `reflectWithOpenAI` → `ReflectResponse` → `BeatRevealFlow`,
/// saved through `buildSavedReflection` into `user_reflections` — but wore a
/// cream-surface form-and-button chrome from before the sacred canvas existed,
/// and sat in the bottom nav promising a daily habit that 55% of the people who
/// tried it performed exactly once. The capability was never the problem; the
/// second front door was.
///
/// **What it is now.** A pushed, full-screen route reached from the Journal's
/// `+`. Emerald from the first frame, the same question shape as the muḥāsabah,
/// the same seven `problemChips`, and the same beat flow at the end — so a
/// reflection written on a Tuesday afternoon and the muḥāsabah written that
/// night are visibly the same act, which is what they have always been in the
/// database.
///
/// **The one thing that genuinely differs from `/muhasabah`, and why this is
/// not simply that route.** The muḥāsabah's Name comes from the queue and is
/// pinned with `forceName` *before* the user writes; here the model picks the
/// Name that answers what was written. Routing "New reflection" at `/muhasabah`
/// would also collide with `uniq_muhasabah_per_local_day` and silently replay
/// the day's existing entry.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/widgets/daily_question_chip_list.dart';
import 'package:sakina/features/daily/widgets/daily_question_field.dart';
import 'package:sakina/features/daily/widgets/daily_question_header.dart';
import 'package:sakina/features/journal/content/new_reflection_copy.dart';
import 'package:sakina/features/journal/providers/reflection_allowance_provider.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/paywall/paywall_navigation.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/features/paywall/upgrade_callback.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/first_visit_hint_service.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';
import 'package:sakina/widgets/first_visit_hint/first_visit_hint_banner.dart';
import 'package:sakina/widgets/share_card.dart';

/// Route path. Under the root navigator, so the bottom nav is absent for the
/// duration — the same treatment `/muhasabah` gets, and for the same reason:
/// the canvas is the whole screen or it is not the canvas.
const String newReflectionRoutePath = '/journal/new-reflection';

class NewReflectionScreen extends ConsumerStatefulWidget {
  const NewReflectionScreen({super.key});

  @override
  ConsumerState<NewReflectionScreen> createState() =>
      _NewReflectionScreenState();
}

class _NewReflectionScreenState extends ConsumerState<NewReflectionScreen> {
  final TextEditingController _controller = TextEditingController();

  /// Latches on send so a double-tap cannot fire two submits before the state
  /// flips to `loading`. Released when the provider reports an error, which is
  /// the only path back to the input state — `submit()` catches its own
  /// failures and returns normally, so without the release the field would stay
  /// dead after a network blip. Mirrors `DailyQuestionPrompt._committing`.
  bool _committing = false;

  /// The chip whose commit is in flight; every other chip recedes.
  String? _selectedChipKey;

  bool _achievementChecked = false;

  /// Whether the result currently on the provider was produced by THIS visit.
  ///
  /// `reflectProvider` is app-scoped, and `_close()` — the only thing that
  /// resets it — is wired to Ameen and Return-home. A system back gesture out
  /// of the beat flow pops the route without either, leaving the provider at
  /// `screenState: result`.
  ///
  /// [initState]'s reset runs in a post-frame callback, which is one frame too
  /// late to stop the FIRST build seeing that stale result. Without this flag
  /// that build both painted the previous reflection's reveal for a frame and
  /// scheduled `checkAchievements` + `onReflectCompleted` for a reflection
  /// nobody had written. The quest is id-guarded per local day, so within a day
  /// that was a no-op — but the id embeds the date, so an app alive past
  /// midnight credited the next day's reflect quest for nothing.
  ///
  /// Found in review, 2026-08-07.
  bool _ownsResult = false;

  /// Guards the two sheet listeners against re-entry inside a single frame.
  bool _sheetShowing = false;

  /// Short screens take the compacted rhythm — `DailyQuestionPrompt`'s
  /// breakpoint verbatim, because this surface is its twin and the two drifting
  /// apart is exactly what a shared constant prevents.
  static const double _compactHeightThreshold = 700;

  @override
  void initState() {
    super.initState();
    // A composer that opens holding the last visit's text (or worse, the last
    // visit's RESULT) is the shape of bug that makes an archive untrustworthy.
    // The provider is app-scoped because it owns the saved-reflection list, so
    // clearing the composer half is this screen's job on the way in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(reflectProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reflectProvider);
    final notifier = ref.read(reflectProvider.notifier);

    ref.listen<ReflectState>(reflectProvider, (prev, next) {
      // ── Releasing the "submit in flight" latch ──
      //
      // THREE edges, not one, and the two that were missing stranded the
      // screen completely (found in review, 2026-08-07).
      //
      // The latch disables the field, the chips and the ×, so whatever sets it
      // must be certain something will clear it. The original rule was "we
      // came back to `input`" — which silently assumed every failed submit
      // passes through `loading` first. Two do not:
      //
      //  * A BLOCKED GATE. `submit()` sets `gateResult` and returns without
      //    ever touching `screenState` (`reflect_provider.dart`, the
      //    `!gate.allowed` branch). `prev.screenState` is already `input`, so
      //    the edge never fires.
      //  * A REFUSED BYPASS. `submitWithBypass()` sets `error` on a null
      //    reservation and returns, same shape.
      //
      // In both cases the user met a sheet, dismissed it, and found a dead
      // screen whose only exit was the system back gesture — including after
      // upgrading through the cap sheet's own paywall.
      //
      // Expressed as "did anything arrive that means the submit did not
      // proceed", so a fourth path of the same shape is covered by default.
      final returnedToInput = next.screenState == ReflectScreenState.input &&
          prev?.screenState != ReflectScreenState.input;
      final refused = next.gateResult != null && prev?.gateResult == null;
      final failedBeforeLoading =
          next.error != null && prev?.error == null;
      if (returnedToInput || refused || failedBeforeLoading) {
        setState(() {
          _committing = false;
          _selectedChipKey = null;
          // Reset with the latch, not separately: the old Reflect tab cleared
          // this on exactly this edge and the port dropped it. It only matters
          // on `BeatRevealFlow`'s empty-screens retry, but a half-restored
          // screen is how the next bug of this shape gets in.
          if (returnedToInput) _achievementChecked = false;
        });
      }
      if (next.gateResult != null && prev?.gateResult == null) {
        _showDailyCapSheet(next.gateResult!, notifier);
      }
      if (next.warmupJustExhausted != null && prev?.warmupJustExhausted == null) {
        _showWarmupExhaustedSheet(next.warmupJustExhausted!, notifier);
      }
    });

    // `_ownsResult` is the guard: a result this visit did not produce is a
    // leftover, and neither the reveal nor the completion belongs to it.
    if (_ownsResult &&
        state.screenState == ReflectScreenState.result &&
        !_achievementChecked) {
      _achievementChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        checkAchievements(ref);
        ref.read(questsProvider.notifier).onReflectCompleted();
      });
    }

    final inFlow = _ownsResult && state.screenState != ReflectScreenState.input;

    // **The gradient wraps the Scaffold rather than being its body**, for the
    // reason spelled out in `daily_question_prompt.dart`: with the keyboard up,
    // `resizeToAvoidBottomInset` shrinks the body, and a gradient inside it
    // leaves the strip beside an iOS 26 inset keyboard showing the transparent
    // Scaffold as black.
    //
    // No `SacredCanvasThreshold` here. That widget animates the CROSSING from
    // a cream surface onto the canvas; this route is emerald from its first
    // frame, so there is no crossing to animate — the push transition is the
    // whole entrance.
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: inFlow ? _buildBeatFlow(state, notifier) : _buildComposer(state),
      ),
    );
  }

  // ── Compose ────────────────────────────────────────────────────────────────

  Widget _buildComposer(ReflectState state) {
    final compact =
        MediaQuery.sizeOf(context).height < _compactHeightThreshold;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget rise(Widget child, {required Duration delay}) => child
        .animate(delay: delay)
        .fadeIn(duration: AppMotion.entrance, curve: AppMotion.enter)
        .moveY(
          begin: reduceMotion ? 0 : AppMotion.riseMedium,
          end: 0,
          duration: AppMotion.entrance,
          curve: AppMotion.enter,
        );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCloseRow(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              // The house pattern for text-entry screens: the column may grow
              // past the viewport (Dynamic Type, a raised keyboard) without
              // overflowing. Padding outside the LayoutBuilder so
              // `constraints.maxHeight` is the height the column actually gets.
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Clearance under the ×.
                        //
                        // Measured, not guessed: the gap between the button's
                        // BOX and the headline was 4pt. The box is a 48pt tap
                        // target around a 24pt glyph, so the visual gap was
                        // about 16 — which is what "crowded" looked like. `md`
                        // takes the box gap to 12 and the visual one to ~24.
                        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                        rise(
                          DailyQuestionHeader(
                            title: NewReflectionCopy.header,
                            compact: compact,
                          ),
                          delay: Duration.zero,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        rise(
                          _buildAllowanceLine(),
                          delay: AppMotion.beat,
                        ),
                        SizedBox(
                            height: compact ? AppSpacing.md : AppSpacing.lg),
                        rise(
                          DailyQuestionField(
                            controller: _controller,
                            enabled: !_committing,
                            semanticsLabel:
                                NewReflectionCopy.answerFieldLabel,
                            onSubmitted: _submitTyped,
                          ),
                          delay: AppMotion.beat,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        rise(
                          Text(
                            NewReflectionCopy.answerSetCaption,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.sacredInkFaint,
                              height: 1.35,
                            ),
                          ),
                          delay: AppMotion.beat * 2,
                        ),
                        // Says what comes BACK — the one thing neither the
                        // header nor the caption above covers, and the thing
                        // the allowance is being spent on. Self-retiring and
                        // once-ever; see [FirstVisitHintId.reflect].
                        const FirstVisitHintBanner(
                          hint: FirstVisitHintId.reflect,
                          padding: EdgeInsets.only(top: AppSpacing.sm),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            state.error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.sacredInk,
                            ),
                          ),
                        ],
                        SizedBox(
                            height: compact ? AppSpacing.md : AppSpacing.lg),
                        DailyQuestionChipList(
                          selectedChipKey: _selectedChipKey,
                          compact: compact,
                          onChipTapped: _submitChip,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The exit.
  ///
  /// An × rather than the daily question's "Not right now" link: this is a
  /// pushed route with nothing pending, so closing it defers no ritual and must
  /// not borrow language that says it does.
  ///
  /// **Top-RIGHT, and the app decided that before this screen existed.**
  /// `BeatRevealFlow` — the view this composer turns into the moment a
  /// reflection lands — puts its own secondary controls (skip, share) top-right
  /// with the content starting below them. A top-left × meant the chrome jumped
  /// sides mid-flow, which is the kind of thing nobody names but everybody
  /// feels.
  ///
  /// Two other things it fixes, both visible on a device and neither on a
  /// Figma frame:
  ///
  ///  * The headline is left-aligned and long. An × directly above its first
  ///    word joins the title's block and reads as part of it; on the opposite
  ///    corner it is plainly chrome, and the eye starts on the question.
  ///  * It lands on the same side as the `+` the user just pressed to get here,
  ///    so the thumb does not cross the screen to leave.
  ///
  /// The gap below it is [AppSpacing.sm] rather than nothing: at 15pt of
  /// clearance the button crowded the headline it was supposed to be out of the
  /// way of.
  Widget _buildCloseRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xs, AppSpacing.xs, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Semantics(
          button: true,
          label: NewReflectionCopy.closeLabel,
          child: IconButton(
            key: const ValueKey('new-reflection-close'),
            // Disabled mid-flight for the same reason the field is: the submit
            // is already in the air, and leaving now would land a saved
            // reflection on a screen the user has left.
            onPressed: _committing ? null : _leave,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.sacredInkSoft,
            tooltip: NewReflectionCopy.closeLabel,
          ),
        ),
      ),
    );
  }

  /// The cost, before the writing rather than after the tap.
  ///
  /// Renders NOTHING for a subscriber, for a legacy-cohort user, and while the
  /// count is unresolved — see [reflectionAllowanceProvider] for why those three
  /// collapse to the same behaviour. `SizedBox.shrink` rather than a reserved
  /// slot: a line that appears when the future lands is invisible, and an empty
  /// 18pt gap that sometimes fills is not.
  Widget _buildAllowanceLine() {
    final allowance = watchReflectionAllowance(ref);
    if (allowance == null || !allowance.hasCount) return const SizedBox.shrink();
    return Text(
      // The LONG form here, unlike the menu's: this screen has a full line to
      // spend and no neighbour to collide with, so it can afford the noun.
      NewReflectionCopy.remainingLine(allowance),
      key: const ValueKey('new-reflection-allowance'),
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.sacredInkFaint,
        height: 1.35,
      ),
    );
  }

  void _submitTyped() {
    final text = _controller.text;
    if (_committing || text.trim().isEmpty) return;
    setState(() => _committing = true);
    HapticFeedback.selectionClick();
    _send(text);
  }

  Future<void> _submitChip(ProblemChip chip) async {
    if (_committing) return;
    setState(() {
      _committing = true;
      _selectedChipKey = chip.chipKey;
      // Fills, THEN submits — the chip is a shortcut through the field, not a
      // parallel input, so the text sent is the label verbatim. Identical to
      // the daily question's handling, which is what keeps `problem_category`
      // comparable across the two surfaces.
      _controller.text = chip.label;
    });
    HapticFeedback.selectionClick();
    await Future<void>.delayed(AppMotion.feedback);
    if (!mounted) return;
    _send(chip.label);
  }

  void _send(String text) {
    _ownsResult = true;
    final notifier = ref.read(reflectProvider.notifier);
    notifier.setUserText(text);
    notifier.submit();
  }

  // ── Reveal ─────────────────────────────────────────────────────────────────

  Widget _buildBeatFlow(ReflectState state, ReflectNotifier notifier) {
    return BeatRevealFlow(
      status: switch (state.screenState) {
        ReflectScreenState.loading => BeatFlowStatus.loading,
        ReflectScreenState.offtopic => BeatFlowStatus.offtopic,
        _ => BeatFlowStatus.ready,
      },
      response: state.result,
      // Reflect has always surfaced its catalog verses as their own beats, and
      // still does: unlike a deck night there is no pre-authored beat list to
      // carry them, so this is the only place they can appear.
      includeVerses: true,
      onAmeen: _close,
      onReturnHome: _close,
      // Both retries return to the composer rather than closing it. The user's
      // words are gone by then (`reset()` clears them), but the alternative —
      // dropping them back on the Journal — makes an off-topic classification
      // feel like an ejection.
      onOffTopicRetry: _backToComposer,
      onRetry: _backToComposer,
      onShare: () => _share(state),
      onBeatAdvanced: (index, kind) {
        ReflectNotifier.onAnalyticsEvent?.call(
          AnalyticsEvents.reflectBeatAdvanced,
          {
            AnalyticsEvents.propSurface: AnalyticsEvents.surfaceReflect,
            AnalyticsEvents.propBeatIndex: index,
            AnalyticsEvents.propBeatKind: kind.wireName,
          },
        );
      },
      onSkip: (from) {
        ReflectNotifier.onAnalyticsEvent?.call(
          AnalyticsEvents.reflectFlowSkipped,
          {
            AnalyticsEvents.propSurface: AnalyticsEvents.surfaceReflect,
            AnalyticsEvents.propFromBeatIndex: from,
          },
        );
      },
      // Both off-topic strings left null on purpose: this surface is Reflect's,
      // and the daily loop's softer wording exists because THAT user has
      // already been given their Name and is being asked to speak again. Here
      // the box's only job is to be reflected on, so the original line is
      // still the honest one. See `BeatRevealFlow.offTopicMessage`.
    );
  }

  void _backToComposer() {
    ref.read(reflectProvider.notifier).reset();
    _controller.clear();
    // The retry re-enters through `_send`, which re-arms this. Clearing it
    // here keeps "a result is mine" true only while one actually is.
    _ownsResult = false;
    // The spend already happened if the flow got as far as a result, so the
    // cached count is now one too high. The Journal invalidates on the way
    // back; a retry never leaves this screen, so it has to invalidate itself.
    ref.invalidate(reflectionAllowanceProvider);
    if (mounted) {
      setState(() {
        _committing = false;
        _selectedChipKey = null;
        _achievementChecked = false;
      });
    }
  }

  /// Leaves the composer and returns to the Journal.
  ///
  /// The reset is what makes the next visit a blank page — see [initState] for
  /// the belt-and-braces on the way in. It runs BEFORE the exit so the Journal
  /// never rebuilds against a state still holding this reflection's result.
  void _close() {
    ref.read(reflectProvider.notifier).reset();
    if (mounted) _leave();
  }

  /// The one way out, and it does NOT assume there is something beneath us.
  ///
  /// This route is declared with `parentNavigatorKey: rootNavigatorKey`, so how
  /// it was entered decides whether a `pop` is even legal:
  ///
  ///  * The Journal's `+` uses `context.push` — a page is added, `pop` is
  ///    correct, and the user lands back on the archive they came from.
  ///  * The First Steps quest card uses `GoRouter.go` (`quests_screen.dart`),
  ///    which REPLACES the whole match list. The root Navigator then holds
  ///    exactly one page, and popping it empties go_router's `RouteMatchList` —
  ///    *"You have popped the last page off of the stack, there are no pages
  ///    left to show"* in debug, a zero-page Navigator in release.
  ///
  /// Found in review, 2026-08-07: the quest deep-link shipped broken, and a
  /// new user tapping "write your first reflection" would have hit it on the
  /// **Ameen** at the end of their very first entry.
  ///
  /// `MuhasabahScreen` has the same route shape and solves it the other way —
  /// it only ever `context.go('/')`, never pops. Handling both here is
  /// deliberately more robust than fixing the one call site: the next deep
  /// link into this screen inherits the fix instead of re-finding the bug.
  void _leave() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go('/journal');
  }

  Future<void> _share(ReflectState state) async {
    final result = state.result;
    if (result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (result.hasBeats &&
          (result.reframeKey.isNotEmpty || result.takeaway.isNotEmpty)) {
        await shareTakeawayCard(
          context: context,
          nameArabic: result.nameArabic,
          nameEnglish: result.name,
          meaning: result.meaning,
          reframeKey: result.reframeKey,
          takeaway: result.takeaway,
        );
      } else {
        await shareReflectionCard(
          context: context,
          nameArabic: result.nameArabic,
          nameEnglish: result.name,
          verses: result.verses,
          duaArabic: result.duaArabic,
          duaTransliteration: result.duaTransliteration,
          duaTranslation: result.duaTranslation,
          duaSource: result.duaSource,
          reframe: result.reframe,
          story: result.story,
        );
      }
    } catch (e) {
      debugPrint('[SHARE ERROR] $e');
      showShareErrorSnackBar(messenger);
    }
  }

  // ── Gating sheets ──────────────────────────────────────────────────────────

  /// Ported verbatim in behaviour from the Reflect tab: the gating layer blocks
  /// a submit, the sheet explains it, and the bypass CTAs re-enter through the
  /// notifier. The async snapshot before the sheet opens is unchanged — a
  /// paywall is not a hot path, and a stale balance for ~50ms is the worst case.
  void _showDailyCapSheet(GateResult gate, ReflectNotifier notifier) {
    if (_sheetShowing) return;
    _sheetShowing = true;
    final sheetContext = context;
    () async {
      final balance = (await getTokens()).balance;
      final bypassesUsed = await daily_usage.getReflectBypassesUsedToday();
      final premium = await PurchaseService().isPremium();
      final firstBypassEligible = await GatingService().firstBypassEligible();
      final displayName = await GatingService().displayName();
      if (!sheetContext.mounted) {
        _sheetShowing = false;
        return;
      }
      DailyCapSheet.show(
        sheetContext,
        feature: GatedFeature.reflect,
        gateReason: gate.reason,
        tokenBalance: balance,
        bypassesUsedToday: bypassesUsed,
        isPremium: premium,
        onBypassRequested: (_) => notifier.submitWithBypass(),
        firstBypassAvailable: firstBypassEligible,
        userDisplayName: displayName,
        onFirstBypassRequested: (_) => notifier.submitWithFirstBypass(),
        onUpgrade: buildPaywallUpgradeCallback(
          reason: gate.reason,
          pushPaywall: () {
            if (mounted) {
              pushPaywall(
                context,
                placement: PaywallPlacement.softInApp,
                valueLine: softGateValueLine(
                  GatedFeature.reflect,
                  gate.reason,
                ),
              );
            }
          },
        ),
      ).whenComplete(() {
        _sheetShowing = false;
        notifier.dismissGate();
      });
    }();
  }

  void _showWarmupExhaustedSheet(
    GatedFeature feature,
    ReflectNotifier notifier,
  ) {
    WarmupExhaustedSheet.show(
      context,
      feature: feature,
      onUpgrade: () =>
          pushPaywall(context, placement: PaywallPlacement.softInApp),
    ).whenComplete(notifier.dismissWarmupExhausted);
  }
}
