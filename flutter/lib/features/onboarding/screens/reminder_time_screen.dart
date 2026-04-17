import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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

  Future<void> _pick() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionScaffold(
      progressSegment: 18,
      headline: 'When should we check in with you?',
      subtitle: 'A gentle reminder, once a day.',
      onBack: widget.onBack,
      continueEnabled: true,
      onContinue: () {
        final hhmm = _format(_time);
        ref.read(onboardingProvider.notifier).setReminderTime(hhmm);
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswer('reminder_time', hhmm);
        widget.onNext();
      },
      body: GestureDetector(
        onTap: _pick,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            _time.format(context),
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
