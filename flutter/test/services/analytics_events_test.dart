import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/analytics_events.dart';

class TrackingSpy extends AnalyticsService {
  final List<(String event, Map<String, dynamic>? props)> tracked = [];
  final List<String> timedEvents = [];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }

  @override
  void timeEvent(String event) {
    timedEvents.add(event);
  }
}

void main() {
  late TrackingSpy spy;

  setUp(() {
    spy = TrackingSpy();
  });

  group('trackStepViewed', () {
    test('legacy flow: fires timeEvent and track with correct properties', () {
      spy.trackStepViewed(3, trimmed: false);

      expect(spy.timedEvents, [AnalyticsEvents.onboardingStepCompleted]);
      expect(spy.tracked.length, 1);
      expect(spy.tracked[0].$1, AnalyticsEvents.onboardingStepViewed);
      expect(spy.tracked[0].$2, {'step_index': 3, 'step_name': 'intention'});
    });

    test('trimmed flow: index 5 maps to familiarity (legacy=quran_connection)',
        () {
      spy.trackStepViewed(5, trimmed: true);
      expect(spy.tracked[0].$2, {'step_index': 5, 'step_name': 'familiarity'});
      // Same raw index under legacy would have mislabeled it.
      expect(AnalyticsEvents.stepNames[5], 'quran_connection');
    });

    test('trimmed flow: index 16 maps to paywall_flow_loader', () {
      spy.trackStepViewed(16, trimmed: true);
      expect(spy.tracked[0].$2,
          {'step_index': 16, 'step_name': 'paywall_flow_loader'});
    });

    test('uses unknown for unmapped index', () {
      spy.trackStepViewed(99, trimmed: true);
      expect(spy.tracked[0].$2?['step_name'], 'unknown');
    });
  });

  group('trackStepCompleted', () {
    test('legacy flow: fires track with correct properties', () {
      spy.trackStepCompleted(0, trimmed: false);
      expect(spy.tracked[0].$1, AnalyticsEvents.onboardingStepCompleted);
      expect(spy.tracked[0].$2, {'step_index': 0, 'step_name': 'first_checkin'});
    });

    test('trimmed flow: index 13 maps to save_progress', () {
      spy.trackStepCompleted(13, trimmed: true);
      expect(spy.tracked[0].$2,
          {'step_index': 13, 'step_name': 'save_progress'});
    });
  });

  group('trackSurveyAnswered', () {
    test('passes String answer directly', () {
      spy.trackSurveyAnswered('intention', 'Spiritual Growth');
      expect(spy.tracked[0].$2, {
        'question': 'intention',
        'answer': 'Spiritual Growth',
      });
    });

    test('converts Set answer to List', () {
      spy.trackSurveyAnswered('common_emotions', {'anxious', 'grief'});
      final answer = spy.tracked[0].$2?['answer'];
      expect(answer, isA<List>());
      expect(answer, containsAll(['anxious', 'grief']));
    });

    test('handles null answer', () {
      spy.trackSurveyAnswered('familiarity', null);
      expect(spy.tracked[0].$2?['answer'], isNull);
    });
  });

  group('trackOnboardingAnswer', () {
    test('fires onboarding_answer_captured with key + value', () {
      spy.trackOnboardingAnswer('age_range', '25_34');
      expect(spy.tracked.length, 1);
      expect(spy.tracked[0].$1, AnalyticsEvents.onboardingAnswerCaptured);
      expect(spy.tracked[0].$2, {'key': 'age_range', 'value': '25_34'});
    });

    test('converts Set value to List', () {
      spy.trackOnboardingAnswer('common_emotions', {'anxious', 'hopeful'});
      final value = spy.tracked[0].$2?['value'];
      expect(value, isA<List>());
      expect(value, containsAll(['anxious', 'hopeful']));
    });

    test('handles null value', () {
      spy.trackOnboardingAnswer('reminder_time', null);
      expect(spy.tracked[0].$2, {'key': 'reminder_time', 'value': null});
    });

    test('passes int value through', () {
      spy.trackOnboardingAnswer('daily_commitment_minutes', 5);
      expect(spy.tracked[0].$2, {
        'key': 'daily_commitment_minutes',
        'value': 5,
      });
    });
  });

  group('Day-1 first-bypass event + reason constants (plan 2026-05-23, PR 4)',
      () {
    // Pins for the Day-1 freebie funnel:
    //   daily_cap_hit → first_bypass_offered → first_bypass_claimed
    // Mixpanel dashboards key off these exact strings. Renames must
    // coordinate with analytics, not happen silently.
    test('event names', () {
      expect(AnalyticsEvents.firstBypassOffered, 'first_bypass_offered');
      expect(AnalyticsEvents.firstBypassClaimed, 'first_bypass_claimed');
      expect(AnalyticsEvents.firstBypassRejected, 'first_bypass_rejected');
    });

    test('rejection reason values match server RPC + client fallback', () {
      // `already_consumed`, `window_expired`, `no_signup_at`,
      // `invalid_feature` returned by claim_first_bypass RPC; `network`
      // is the client-side fallback for transport failure.
      expect(AnalyticsEvents.firstBypassRejectedReasonAlreadyConsumed,
          'already_consumed');
      expect(AnalyticsEvents.firstBypassRejectedReasonWindowExpired,
          'window_expired');
      expect(AnalyticsEvents.firstBypassRejectedReasonNoSignupAt,
          'no_signup_at');
      expect(AnalyticsEvents.firstBypassRejectedReasonInvalidFeature,
          'invalid_feature');
      expect(AnalyticsEvents.firstBypassRejectedReasonNetwork, 'network');
    });
  });

  group('AI bypass event + reason constants (plan 2026-05-23, PR 3)', () {
    // Pin the wire-protocol strings. The Mixpanel funnel
    //   daily_cap_hit → ai_bypass_offered → ai_bypass_purchased
    // and the dashboards that read it are keyed off these exact names.
    // Renaming either constant in Dart MUST be a deliberate analytics-team
    // coordination, not a silent refactor — these tests are the tripwire.
    test('event names match Mixpanel funnel + dashboard contract', () {
      expect(AnalyticsEvents.aiBypassOffered, 'ai_bypass_offered');
      expect(AnalyticsEvents.aiBypassPurchased, 'ai_bypass_purchased');
      expect(AnalyticsEvents.aiBypassRejected, 'ai_bypass_rejected');
    });

    test('rejection reason values match server RPC + client fallback', () {
      // `no_tokens` and `bypass_cap` are returned by the server RPC
      // `reserve_ai_bypass`; `network` is the client-side fallback for an
      // RPC that returns null (transport failure). Server SQL test pins
      // the same strings on the backend side.
      expect(AnalyticsEvents.aiBypassRejectedReasonNoTokens, 'no_tokens');
      expect(AnalyticsEvents.aiBypassRejectedReasonBypassCap, 'bypass_cap');
      expect(AnalyticsEvents.aiBypassRejectedReasonNetwork, 'network');
    });
  });

  group('IAP→sub upsell banner constants (plan 2026-05-23, PR 5)', () {
    // Pins the wire-protocol strings for the EXP-3 banner.
    //   iap_to_sub_banner_shown   — fires once per home-visit-session when
    //                               the banner first renders (handled by the
    //                               provider's autoDispose lifecycle).
    //   iap_to_sub_banner_tapped  — user tapped the banner body (routes to
    //                               paywall + emits paywall_viewed too).
    //   iap_to_sub_banner_dismissed — user tapped the close icon. Server
    //                                  records dismissed_at; banner re-shows
    //                                  after the 14-day suppression window.
    test('event names', () {
      expect(AnalyticsEvents.iapToSubBannerShown, 'iap_to_sub_banner_shown');
      expect(AnalyticsEvents.iapToSubBannerTapped, 'iap_to_sub_banner_tapped');
      expect(
          AnalyticsEvents.iapToSubBannerDismissed,
          'iap_to_sub_banner_dismissed');
    });

    test('paywall_viewed.trigger value', () {
      // The banner-tap path fires paywall_viewed with trigger='iap_to_sub_upsell'
      // so the funnel can attribute trial starts from this surface separately
      // from the onboarding paywall (no trigger property) and the daily-cap
      // sheet (trigger='daily_cap_with_bypass_option').
      expect(
          AnalyticsEvents.paywallTriggerIapToSubUpsell, 'iap_to_sub_upsell');
    });
  });

  group('signup_failed reason constants', () {
    // The sign-up password screen's session-race branch (previously a silent
    // SnackBar+return) now fires signup_failed with this exact reason — pin
    // the contract so a rename in either side surfaces as a test failure.
    test('exposes session_race + unknown as typed constants', () {
      expect(AnalyticsEvents.signupFailedReasonSessionRace, 'session_race');
      expect(AnalyticsEvents.signupFailedReasonUnknown, 'unknown');
    });

    test('exposes the bounded recovery/auth reason constants', () {
      expect(AnalyticsEvents.signupFailedReasonEmailTaken, 'email_taken');
      expect(AnalyticsEvents.signupFailedReasonInvalidCredentials,
          'invalid_credentials');
      expect(AnalyticsEvents.signupFailedReasonWeakPassword, 'weak_password');
      expect(AnalyticsEvents.signupFailedReasonRateLimited, 'rate_limited');
      expect(AnalyticsEvents.signupFailedReasonAuthError, 'auth_error');
    });

    test('signupFailedReasonForCode maps gotrue codes to the bounded set', () {
      // Keeps signup_failed.error low-cardinality: raw gotrue messages must
      // never reach Mixpanel. Every code collapses to one of the constants.
      expect(AnalyticsEvents.signupFailedReasonForCode('user_already_exists'),
          'email_taken');
      expect(AnalyticsEvents.signupFailedReasonForCode('email_exists'),
          'email_taken');
      expect(AnalyticsEvents.signupFailedReasonForCode('invalid_credentials'),
          'invalid_credentials');
      expect(AnalyticsEvents.signupFailedReasonForCode('weak_password'),
          'weak_password');
      expect(AnalyticsEvents.signupFailedReasonForCode('over_request_rate_limit'),
          'rate_limited');
      expect(
          AnalyticsEvents.signupFailedReasonForCode('over_email_send_rate_limit'),
          'rate_limited');
      // Null code (error before any HTTP response) → unknown.
      expect(AnalyticsEvents.signupFailedReasonForCode(null), 'unknown');
      // Any unmapped code collapses to the auth_error bucket, never raw.
      expect(AnalyticsEvents.signupFailedReasonForCode('some_new_code'),
          'auth_error');
    });
  });

  group('Retention monetization/notification analytics constants (PR #34)', () {
    // Pins the EXACT wire-protocol strings the Mixpanel dashboards key off.
    // Renaming any of these constants in Dart MUST be a deliberate
    // analytics-team coordination, not a silent refactor — these assertions
    // are the tripwire.
    test('notification_opened re-engagement event', () {
      expect(AnalyticsEvents.notificationOpened, 'notification_opened');
    });

    test('paywall_flow_* funnel event names', () {
      // The paywall-flow funnel (loader → plan → journey) and the dropoff
      // event power the multi-step onboarding-paywall conversion dashboards.
      expect(
          AnalyticsEvents.paywallFlowLoaderShown, 'paywall_flow_loader_shown');
      expect(AnalyticsEvents.paywallFlowLoaderAdvanced,
          'paywall_flow_loader_advanced');
      expect(AnalyticsEvents.paywallFlowPlanShown, 'paywall_flow_plan_shown');
      expect(AnalyticsEvents.paywallFlowPlanContinued,
          'paywall_flow_plan_continued');
      expect(AnalyticsEvents.paywallFlowJourneyShown,
          'paywall_flow_journey_shown');
      expect(AnalyticsEvents.paywallFlowJourneyContinued,
          'paywall_flow_journey_continued');
      expect(AnalyticsEvents.paywallFlowDropoff, 'paywall_flow_dropoff');
    });
  });

  group('AnalyticsEvents.stepNames', () {
    test('covers all 27 onboarding pages (rating gate at 25, paywall at 26)', () {
      // Updated 2026-05-14 by rating-gate insertion. The map carries entries
      // for indices 0..26; the rating gate is always present at index 25.
      for (int i = 0; i <= 26; i++) {
        expect(AnalyticsEvents.stepNames[i], isNotNull,
            reason: 'Missing step name for index $i');
      }
      expect(AnalyticsEvents.stepNames[25], 'rating_gate');
      expect(AnalyticsEvents.stepNames[26], 'paywall');
      expect(AnalyticsEvents.stepNames[27], isNull,
          reason: 'No step at index 27 after rating-gate insertion');
    });

    test('does not include the removed social_proof_interstitial step', () {
      expect(
        AnalyticsEvents.stepNames.values,
        isNot(contains('social_proof_interstitial')),
      );
    });

    test('does not include the removed resonant_name step', () {
      expect(
        AnalyticsEvents.stepNames.values,
        isNot(contains('resonant_name')),
      );
    });
  });

  group('AnalyticsEvents.trimmedStepNames (20-page trimmed flow)', () {
    test('covers indices 0..19 with no gaps', () {
      for (int i = 0; i <= 19; i++) {
        expect(AnalyticsEvents.trimmedStepNames[i], isNotNull,
            reason: 'Missing trimmed step name for index $i');
      }
      expect(AnalyticsEvents.trimmedStepNames[20], isNull,
          reason: 'No trimmed step beyond paywall at 19');
    });

    test('matches the canonical trimmed page order', () {
      expect(AnalyticsEvents.trimmedStepNames[5], 'familiarity');
      expect(AnalyticsEvents.trimmedStepNames[6], 'dua_topics');
      expect(AnalyticsEvents.trimmedStepNames[7], 'daily_commitment');
      expect(AnalyticsEvents.trimmedStepNames[8], 'attribution');
      expect(AnalyticsEvents.trimmedStepNames[16], 'paywall_flow_loader');
      expect(AnalyticsEvents.trimmedStepNames[17], 'paywall_flow_plan');
      expect(AnalyticsEvents.trimmedStepNames[18], 'rating_gate');
      expect(AnalyticsEvents.trimmedStepNames[19], 'paywall');
    });

    test('drops legacy-only steps removed by the trim', () {
      expect(
        AnalyticsEvents.trimmedStepNames.values,
        isNot(anyElement(isIn([
          'quran_connection',
          'common_emotions',
          'aspirations',
          'struggle_support_interstitial',
          'value_prop',
          'encouragement',
          'paywall_flow_journey',
        ]))),
      );
    });
  });

  group('AnalyticsEvents.stepNamesFor', () {
    test('trimmed:true returns the trimmed map', () {
      expect(AnalyticsEvents.stepNamesFor(trimmed: true),
          same(AnalyticsEvents.trimmedStepNames));
    });

    test('trimmed:false returns the legacy map', () {
      expect(AnalyticsEvents.stepNamesFor(trimmed: false),
          same(AnalyticsEvents.stepNames));
    });
  });

  group('Engagement & economy analytics constants (retention audit 2026-06-01)',
      () {
    // Pin the Mixpanel dashboard contract for the three dark core-loop
    // surfaces (Store, collection/gacha, streak/quest/XP economy). Renaming
    // any of these in Dart MUST be a deliberate analytics-team coordination —
    // these tests are the tripwire. See
    // docs/superpowers/plans/2026-06-01-engagement-economy-analytics.md.
    test('store event names', () {
      expect(AnalyticsEvents.storeViewed, 'store_viewed');
      expect(AnalyticsEvents.packSelected, 'pack_selected');
      expect(AnalyticsEvents.storePurchaseSucceeded, 'store_purchase_succeeded');
      expect(AnalyticsEvents.storePurchaseFailed, 'store_purchase_failed');
      expect(AnalyticsEvents.storePurchaseCancelled, 'store_purchase_cancelled');
    });

    test('store_purchase_failed reason values', () {
      expect(AnalyticsEvents.storePurchaseFailedReasonUnavailable,
          'unavailable');
      expect(AnalyticsEvents.storePurchaseFailedReasonPlatform, 'platform');
      expect(AnalyticsEvents.storePurchaseFailedReasonUnknown, 'unknown');
    });

    test('collection / gacha event names', () {
      expect(AnalyticsEvents.cardRevealed, 'card_revealed');
      expect(AnalyticsEvents.tierUp, 'tier_up');
      expect(AnalyticsEvents.collectionCompleted, 'collection_completed');
    });

    test('streak / quest / XP / level event names', () {
      expect(AnalyticsEvents.streakExtended, 'streak_extended');
      expect(AnalyticsEvents.streakMilestone, 'streak_milestone');
      expect(AnalyticsEvents.streakFreezeConsumed, 'streak_freeze_consumed');
      expect(AnalyticsEvents.questCompleted, 'quest_completed');
      expect(AnalyticsEvents.xpAwarded, 'xp_awarded');
      expect(AnalyticsEvents.levelUp, 'level_up');
    });

    test('quest_type values', () {
      expect(AnalyticsEvents.questTypeStandard, 'standard');
      expect(AnalyticsEvents.questTypeBeginner, 'beginner');
    });
  });
}
