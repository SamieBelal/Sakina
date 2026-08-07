import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';

/// Test seam shared by every gate surface: when `true`, entry motion is a
/// no-op wrapper so `pumpAndSettle` returns.
///
/// Set it through `debugDisablePaywallAnimations` in `paywall_screen.dart`,
/// which is the name every existing test already uses. Production never sets
/// either.
bool debugDisablePaywallGateMotion = false;

/// The frame every page of the W5 gate is built in: cream canvas, a top row
/// carrying the step dots and the ✕, a scrolling body, and a footer pinned to
/// the bottom.
///
/// **The CTA lives in [footer], never in [body].** On a 375×667 frame the
/// benefit checklist plus two plan rows plus terms plus the legal links do not
/// fit, and a Restore button that has scrolled out of reach is an App Store
/// review risk — so the body scrolls under a footer that cannot.
///
/// [body] is given at least the full remaining viewport height (LayoutBuilder →
/// SingleChildScrollView → ConstrainedBox → IntrinsicHeight, the same shape the
/// onboarding text screens use for keyboard overflow), so a page may use
/// `Expanded`/`Spacer` to distribute itself down the screen when there is room
/// and still scroll when there is not.
///
/// One constraint that follows: **nothing in [body] may use
/// `CrossAxisAlignment.stretch` inside a flex child.** `IntrinsicHeight` has to
/// measure the body without knowing its final height, and a stretched cross
/// axis has no measurable size until that height exists — the layout asserts
/// `RenderBox was not laid out`. Use a `Stack` with a `Positioned` fill where
/// something needs to span its sibling's height (see the timeline page's
/// rail).
class PaywallGatePage extends StatelessWidget {
  const PaywallGatePage({
    required this.body,
    required this.footer,
    this.stepCount = 0,
    this.stepIndex = 0,
    this.onClose,
    this.onBack,
    super.key,
  });

  final Widget body;
  final Widget footer;

  /// Number of dots in the progress rail. `0` hides the rail (the condensed
  /// single screen has no ceremony to track).
  final int stepCount;
  final int stepIndex;

  /// `null` renders no ✕ at all — the hard entry wall's no-dismiss contract.
  /// Otherwise the ✕ is present and tappable from frame zero: the 3-second
  /// reveal delay it replaced was a dark pattern and is deleted.
  final VoidCallback? onClose;

  /// Steps BACK one page in the ceremony. `null` on the first page (there is
  /// nowhere to go) and on any single-page surface.
  ///
  /// Deliberately NOT gated on the hard-wall contract, because moving between
  /// ceremony pages is not an escape — the ✕ is the exit; this is not. (Today
  /// the two cannot meet: `PaywallScreen` asserts `!(hardGate &&
  /// inOnboardingFlow)` and only the onboarding placement runs a ceremony. The
  /// independence is kept so that stays true by construction if a future
  /// surface pairs them.)
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Stack(
              children: [
                if (onBack != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: PaywallBackButton(onPressed: onBack!),
                    ),
                  ),
                if (stepCount > 0)
                  Center(
                    child: PaywallStepDots(
                      count: stepCount,
                      index: stepIndex,
                    ),
                  ),
                if (onClose != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PaywallCloseButton(onPressed: onClose!),
                    ),
                  ),
              ],
            ),
          ),
          // Breathing room under the chrome row. Owned by the FRAME, not by the
          // pages: every page opens on a large display headline that would
          // otherwise start hard against the back button and the ✕, and putting
          // the gap here is what keeps all three pages of the ceremony aligned
          // on the same top edge.
          //
          // Matched to [AppSpacing.pagePadding] so the headline's inset from the
          // chrome equals its inset from the sides.
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(child: body),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: footer,
          ),
        ],
      ),
    );
  }
}

/// Non-sellable state shown until both required live packages and eligibility
/// data are available. It intentionally has no plan cards, prices, billing
/// terms, or purchase CTA.
class PaywallOfferState extends StatelessWidget {
  const PaywallOfferState({
    required this.loading,
    this.message,
    this.transientError,
    super.key,
  });

  final bool loading;

  /// The body copy: why there is nothing to buy. Invariant for as long as this
  /// surface is showing.
  final String? message;

  /// A one-off failure from an action taken ON this surface — a failed Restore,
  /// say. Rendered as a SECOND line below [message] rather than replacing it.
  ///
  /// Separate slots on purpose. Restore lives on this surface, and the state it
  /// writes ("No active premium subscription was found to restore.") answers a
  /// different question from the one the body copy answers. Feeding it into
  /// [message] let one tap erase the only explanation for why the screen is
  /// empty, with nothing to put it back.
  final String? transientError;

  @override
  Widget build(BuildContext context) {
    // A transient error that has merely echoed the body copy is not a second
    // fact — dropping it keeps the same sentence from rendering twice.
    final body = message ?? AppStrings.paywallOffersUnavailable;
    final secondary = transientError == body ? null : transientError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: loading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.cloud_off_outlined,
                  size: 30,
                  color: AppColors.textTertiaryLight,
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          loading ? AppStrings.paywallOffersLoading : body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        if (!loading && secondary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            secondary,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

/// The ceremony's back chevron. Deliberately the ✕'s twin — same 44×44 hit
/// area, same circle, same weight — because the two sit in one row and a back
/// affordance that reads heavier than the exit invites the wrong tap.
class PaywallBackButton extends StatelessWidget {
  const PaywallBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textSecondaryLight,
          size: 18,
        ),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceLight,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.borderLight),
          ),
        ),
      ),
    );
  }
}

/// The ✕. A 44×44 hit area on every page — Apple's minimum, and the reason the
/// icon is smaller than the button.
class PaywallCloseButton extends StatelessWidget {
  const PaywallCloseButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        icon: const Icon(
          Icons.close_rounded,
          color: AppColors.textSecondaryLight,
          size: 22,
        ),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceLight,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.borderLight),
          ),
        ),
      ),
    );
  }
}

/// Hairline progress rail. Deliberately not a percentage bar — three pages is
/// short enough that dots read faster than a fill.
class PaywallStepDots extends StatelessWidget {
  const PaywallStepDots({required this.count, required this.index, super.key});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final on = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 28 : 20,
          height: 2,
          decoration: BoxDecoration(
            color: on ? AppColors.primary : AppColors.borderLight,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

/// The gate's entry motion: a staggered fade plus a 9px rise, 450ms
/// `easeOutCubic` — the same beat-advance rhythm as the sacred canvas
/// (DESIGN.md §5), so arriving at the gate feels like the rest of the app
/// rather than like a store page.
///
/// Honours reduced motion (and the test seam) by returning [child] untouched —
/// no content is ever gated behind an animation that can be turned off.
Widget paywallEntry(BuildContext context, int index, Widget child) {
  if (debugDisablePaywallGateMotion ||
      MediaQuery.maybeDisableAnimationsOf(context) == true) {
    return child;
  }
  final delay = Duration(milliseconds: 40 + 60 * index);
  return child
      .animate()
      .fadeIn(delay: delay, duration: 450.ms, curve: Curves.easeOutCubic)
      .slideY(
        begin: 0.045,
        end: 0,
        delay: delay,
        duration: 450.ms,
        curve: Curves.easeOutCubic,
      );
}
