import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';

/// Where a widget "precise times are off" tap lands, and where the Settings row
/// links to.
///
/// **This is the app's first OS-settings walkthrough.** Until now the only
/// `openAppSettings()` call jumped straight to iOS with no explanation, which
/// is fine for someone who knows what they are looking for and useless for
/// everyone else. The home-screen widget can state the problem in about 28
/// characters and cannot say more — so the explaining has to happen here.
///
/// Steps are per-state: the fix for a lapsed permission and the fix for a
/// device-wide Location Services switch are in different places.
class PreciseTimesScreen extends ConsumerWidget {
  const PreciseTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duaWindowProvider).preciseState;
    final working = state == PreciseTimesState.working ||
        state == PreciseTimesState.unresolved;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
        title: Text('Precise duʿā times',
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.textPrimaryLight)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                working ? 'Precise times are on.' : 'Precise times are paused.',
                style: AppTypography.displaySmall
                    .copyWith(color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _blurb(state),
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondaryLight, height: 1.5),
              ),
              if (!working) ...[
                const SizedBox(height: AppSpacing.lg),
                _Steps(steps: _stepsFor(state)),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    onPressed: () => _prompt(ref, state),
                    child: Text(
                        state == PreciseTimesState.servicesOff
                            ? 'Open Settings'
                            : 'Turn on',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.textOnPrimary)),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sakina only ever uses an approximate location, only to work out '
                'prayer times on your device. It never leaves your phone.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The single "opens the system alert" button, and now the only place the
  /// location funnel is emitted from on this path.
  ///
  /// The paused notice used to prompt directly and fire these itself; it now
  /// navigates here instead (so it can carry a ✕ without tripping Apple's
  /// pre-alert rules). Without this the notice→grant funnel would have gone
  /// dark — the tap would be counted nowhere.
  static Future<void> _prompt(WidgetRef ref, PreciseTimesState stateAtTap) async {
    final analytics = ref.read(analyticsProvider);
    analytics.track(
      AnalyticsEvents.duaTimesLocationPrompt,
      properties: {AnalyticsEvents.propPreciseState: stateAtTap.wireName},
    );
    final outcome = await ref.read(duaWindowProvider.notifier).promptLocation();
    // The Settings round-trip is NOT a denial — same honesty rule as the card.
    final event = switch (outcome) {
      LocationPromptOutcome.granted => AnalyticsEvents.duaTimesLocationGranted,
      LocationPromptOutcome.denied => AnalyticsEvents.duaTimesLocationDenied,
      LocationPromptOutcome.openedSettings ||
      LocationPromptOutcome.servicesOff =>
        AnalyticsEvents.duaTimesLocationSettingsOpened,
    };
    analytics.track(
      event,
      properties: {AnalyticsEvents.propPreciseState: stateAtTap.wireName},
    );
  }

  static String _blurb(PreciseTimesState state) => switch (state) {
        PreciseTimesState.working =>
          'Your duʿā windows are being worked out from prayer times where you '
              'are, so the countdown and reminders are exact.',
        PreciseTimesState.unresolved =>
          'Everything is granted — the times are being worked out now.',
        PreciseTimesState.servicesOff =>
          'Location Services are switched off for this device, so prayer times '
              'cannot be worked out. Friday and the sacred days still show.',
        _ =>
          'Without a location Sakina cannot work out prayer times, so the live '
              'countdown and the precise reminders stop. Friday and the sacred '
              'days still show.',
      };

  static List<String> _stepsFor(PreciseTimesState state) =>
      state == PreciseTimesState.servicesOff
          ? const [
              'Open the Settings app.',
              'Go to Privacy & Security › Location Services.',
              'Turn Location Services on.',
              'Come back to Sakina — the times return on their own.',
            ]
          : const [
              // Deliberately vague about WHICH surface appears: the button below
              // shows the system dialog when the permission is still askable,
              // and jumps to Settings only once iOS has stopped offering it.
              // Naming one would be wrong half the time.
              'Tap Turn on below.',
              // The whole point. "Allow Once" is what lapses on the next launch,
              // and choosing it is what put most people here.
              'Choose “While Using the App” — not “Allow Once”.',
              'Come back to Sakina — the times return on their own.',
            ];
}

/// Numbered-circle step list, matching `_HowToSteps` in the widget-install nudge
/// so the app has one visual language for "here is how to do a thing in iOS".
class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  bottom: i == steps.length - 1 ? 0 : AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(steps[i],
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          )),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
