import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/widget_promo/widget_install_nudge_gate.dart';

void main() {
  test('hidden once dismissed, regardless of streak', () {
    expect(
      resolveWidgetInstallNudge(dismissed: true, currentStreak: 50),
      WidgetInstallNudgeDecision.hidden,
    );
  });

  test('hidden before the user has a streak (not engaged yet)', () {
    expect(
      resolveWidgetInstallNudge(dismissed: false, currentStreak: 0),
      WidgetInstallNudgeDecision.hidden,
    );
  });

  test('shows at the aha moment: first streak, not dismissed', () {
    expect(
      resolveWidgetInstallNudge(dismissed: false, currentStreak: 1),
      WidgetInstallNudgeDecision.show,
    );
  });

  test('minStreak is configurable', () {
    expect(
      resolveWidgetInstallNudge(
          dismissed: false, currentStreak: 2, minStreak: 3),
      WidgetInstallNudgeDecision.hidden,
    );
    expect(
      resolveWidgetInstallNudge(
          dismissed: false, currentStreak: 3, minStreak: 3),
      WidgetInstallNudgeDecision.show,
    );
  });
}
