import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class ReminderTimeScreen extends ConsumerStatefulWidget {
  const ReminderTimeScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<ReminderTimeScreen> createState() => _ReminderTimeScreenState();
}

class _ReminderTimeScreenState extends ConsumerState<ReminderTimeScreen> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingProvider).reminderTime;
    _time = existing != null
        ? _parse(existing)
        : const TimeOfDay(hour: 8, minute: 0);
  }

  TimeOfDay _parse(String hhmm) {
    try {
      final p = hhmm.split(':');
      if (p.length < 2) return const TimeOfDay(hour: 8, minute: 0);
      final h = int.parse(p[0]);
      final m = int.parse(p[1]);
      if (h < 0 || h > 23 || m < 0 || m > 59) {
        return const TimeOfDay(hour: 8, minute: 0);
      }
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      // Corrupt prefs or future schema drift — fall back to 08:00 default.
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _periodLabel(TimeOfDay t) {
    final h = t.hour;
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 21) return 'Evening';
    return 'Night';
  }

  IconData _periodIcon(TimeOfDay t) {
    final h = t.hour;
    if (h >= 5 && h < 12) return Icons.wb_twilight_rounded;
    if (h >= 12 && h < 17) return Icons.wb_sunny_rounded;
    if (h >= 17 && h < 21) return Icons.brightness_4_rounded;
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionScaffold(
      progressSegment: 14,
      headline: 'When should we check in with you?',
      subtitle: 'A gentle reminder, once a day.',
      onBack: widget.onBack,
      continueEnabled: true,
      onContinue: () {
        final hhmm = _format(_time);
        ref.read(onboardingProvider.notifier).setReminderTime(hhmm);
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswerWithRef(ref, 'reminder_time', hhmm);
        widget.onNext();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  _periodIcon(_time),
                  size: 32,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _time.format(context),
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _periodLabel(_time),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: AppTypography.headlineMedium
                      .copyWith(color: AppColors.textPrimaryLight),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2026,
                  1,
                  1,
                  _time.hour,
                  _time.minute,
                ),
                use24hFormat: false,
                minuteInterval: 5,
                onDateTimeChanged: (dt) {
                  setState(
                    () => _time = TimeOfDay(hour: dt.hour, minute: dt.minute),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
