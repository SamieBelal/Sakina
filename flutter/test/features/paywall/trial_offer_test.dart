import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sakina/features/paywall/trial_offer.dart';

/// W5 Wave B.4 — the trial duration is DERIVED from the store.
///
/// Before this, "3 days" was written down in five Dart strings, so a change in
/// App Store Connect turned the paywall into a false promise at the moment of
/// payment. These tests are the guarantee that cannot happen again.
StoreProduct _product({
  IntroductoryPrice? intro,
  String id = 'sakina_sub_annual',
}) =>
    StoreProduct(
      id,
      'desc',
      'title',
      49.99,
      '\$49.99',
      'USD',
      introductoryPrice: intro,
    );

void main() {
  group('TrialOffer.fromProduct', () {
    test('reads periodNumberOfUnits + periodUnit', () {
      final offer = TrialOffer.fromProduct(
        _product(
          intro: const IntroductoryPrice(0, 'Free', 'P7D', 1, PeriodUnit.day, 7),
        ),
      );
      expect(offer, isNotNull);
      expect(offer!.label, '7 days');
      expect(offer.days, 7);
    });

    test('the store is the source: P3D renders "3 days", not a constant', () {
      final offer = TrialOffer.fromProduct(
        _product(
          intro: const IntroductoryPrice(0, 'Free', 'P3D', 1, PeriodUnit.day, 3),
        ),
      );
      expect(offer!.label, '3 days');
    });

    test('a one-week period is counted in days — the copy says days', () {
      final offer = TrialOffer.fromProduct(
        _product(
          intro:
              const IntroductoryPrice(0, 'Free', 'P1W', 1, PeriodUnit.week, 1),
        ),
      );
      expect(offer!.label, '7 days');
      expect(offer.days, 7);
    });

    test('falls back to the ISO period when the SDK fields are unusable', () {
      final offer = TrialOffer.fromProduct(
        _product(
          // periodNumberOfUnits 0 + an unknown unit: observed on some
          // storefronts. The ISO string still carries the truth.
          intro: const IntroductoryPrice(
              0, 'Free', 'P14D', 1, PeriodUnit.unknown, 0),
        ),
      );
      expect(offer!.label, '14 days');
    });

    test('a month has no honest day count, so the timeline gets none', () {
      final offer = TrialOffer.fromProduct(
        _product(
          intro:
              const IntroductoryPrice(0, 'Free', 'P1M', 1, PeriodUnit.month, 1),
        ),
      );
      expect(offer!.label, '1 month');
      expect(offer.days, isNull);
    });

    test('a PAID introductory price is not a trial', () {
      final offer = TrialOffer.fromProduct(
        _product(
          intro: const IntroductoryPrice(
              9.99, '\$9.99', 'P7D', 1, PeriodUnit.day, 7),
        ),
      );
      expect(offer, isNull);
    });

    test('no introductory offer at all', () {
      expect(TrialOffer.fromProduct(_product()), isNull);
      expect(TrialOffer.fromProduct(null), isNull);
    });

    test('an unparseable period yields nothing rather than a guess', () {
      final offer = TrialOffer.fromProduct(
        _product(
          intro:
              const IntroductoryPrice(0, 'Free', '', 1, PeriodUnit.unknown, 0),
        ),
      );
      expect(offer, isNull);
    });
  });

  group('resolveTrialEligibility', () {
    const id = 'sakina_sub_annual';

    TrialEligibility resolve(
      IntroEligibilityStatus? status, {
      bool hasTrial = true,
      TargetPlatform platform = TargetPlatform.iOS,
      bool statusesFetched = true,
    }) =>
        resolveTrialEligibility(
          productId: id,
          productHasFreeTrial: hasTrial,
          statuses: statusesFetched
              ? (status == null ? const {} : {id: status})
              : null,
          platform: platform,
        );

    test('eligible', () {
      expect(
        resolve(IntroEligibilityStatus.introEligibilityStatusEligible),
        TrialEligibility.eligible,
      );
    });

    test('ineligible — the user already burned their one grant', () {
      expect(
        resolve(IntroEligibilityStatus.introEligibilityStatusIneligible),
        TrialEligibility.ineligible,
      );
    });

    test('no intro offer exists for this product', () {
      expect(
        resolve(
            IntroEligibilityStatus.introEligibilityStatusNoIntroOfferExists),
        TrialEligibility.ineligible,
      );
    });

    test('unknown on iOS is ineligible — never promise what we cannot verify',
        () {
      expect(
        resolve(IntroEligibilityStatus.introEligibilityStatusUnknown),
        TrialEligibility.ineligible,
      );
      expect(resolve(null), TrialEligibility.ineligible);
    });

    test('unknown on Android keeps the product-level signal', () {
      // Play evaluates eligibility itself at purchase time and RevenueCat
      // answers unknown for EVERY Android user, so being strict here would
      // hide trial copy from the whole platform.
      expect(
        resolve(
          IntroEligibilityStatus.introEligibilityStatusUnknown,
          platform: TargetPlatform.android,
        ),
        TrialEligibility.eligible,
      );
    });

    test('a product with no free trial is ineligible on every platform', () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(
          resolve(
            IntroEligibilityStatus.introEligibilityStatusEligible,
            hasTrial: false,
            platform: platform,
          ),
          TrialEligibility.ineligible,
        );
      }
    });

    test('not fetched yet is unresolved, which callers treat as ineligible',
        () {
      expect(
        resolve(null, statusesFetched: false),
        TrialEligibility.unresolved,
      );
    });
  });
}
