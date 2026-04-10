import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/features/daily/providers/daily_question_provider.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService();
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetPublicCatalogs();
    await bootstrapPublicCatalogs();
  });

  tearDown(() {
    debugResetPublicCatalogs();
    SupabaseSyncService.debugReset();
  });

  test('daily question provider updates when catalog refresh succeeds',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final emittedStates = <DailyQuestionState>[];
    final subscription = container.listen<DailyQuestionState>(
      dailyQuestionProvider,
      (_, next) => emittedStates.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await Future<void>.delayed(Duration.zero);

    final currentQuestion = container.read(dailyQuestionProvider).question;
    expect(currentQuestion, isNotNull);

    fakeSync.publicRows['daily_questions'] = dailyQuestions
        .map((question) => {
              'id': question.id,
              'question': question.id == currentQuestion!.id
                  ? 'Updated question from Supabase'
                  : question.question,
              'options': question.options,
            })
        .toList();

    await refreshPublicCatalogsFromSupabase(skipClientCheck: true);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(dailyQuestionProvider).question?.question,
      'Updated question from Supabase',
    );
    expect(emittedStates.length, greaterThan(1));
  });

  test('daily answers remain readable when older sparse payloads are loaded',
      () {
    final answer = DailyAnswer.fromJson({
      'questionId': 7,
      'answer': 'Patience',
      'name': 'As-Saboor',
      'nameArabic': 'الصبور',
    });

    expect(answer.questionId, 7);
    expect(answer.answer, 'Patience');
    expect(answer.name, 'As-Saboor');
    expect(answer.nameArabic, 'الصبور');
    expect(answer.date, isNotEmpty);
    expect(answer.teaching, isEmpty);
    expect(answer.duaArabic, isEmpty);
    expect(answer.duaTransliteration, isEmpty);
    expect(answer.duaTranslation, isEmpty);
  });
}
