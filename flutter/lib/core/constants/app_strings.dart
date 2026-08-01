abstract final class AppStrings {
  static const appName = 'Sakina';

  // Home
  static const howAreYouFeeling = 'How are you feeling?';
  static const typeYourFeeling = 'Type how you\'re feeling...';

  // Tabs
  static const home = 'Home';
  static const names = 'Names';
  static const journal = 'Journal';
  static const settings = 'Settings';

  // ── Onboarding ──

  // Screen 1: Hook
  static const sakinaArabic = 'سكينة';
  static const sakinaTagline = 'Peace for your soul';
  static const hookAyahArabic = 'فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا';
  static const hookAyahEnglish = 'Indeed, with hardship comes ease.';
  static const hookSubtitle2 = 'Make sense of life through Allah\'s Names.';
  static const hookCta = 'Get Started';
  static const hookLoginLink = 'I Already Have an Account';
  static const hookDemoFeeling = 'I feel anxious and overwhelmed';
  static const hookReflectButton = 'Reflect';

  // Screen 2: Intention
  static const intentionTitle = 'What brings you here?';
  static const intentionSubtitle =
      'This helps us personalize your experience';
  static const intentionSpiritualGrowth = 'Spiritual Growth';
  static const intentionSpiritualGrowthDesc =
      'Deepen my connection with Allah';
  static const intentionDifficultTime = 'Difficult Time';
  static const intentionDifficultTimeDesc =
      'Find comfort in Allah\'s words';
  static const intentionBuildHabit = 'Build a Daily Habit';
  static const intentionBuildHabitDesc = 'Consistent spiritual reflection';
  static const intentionCurious = 'Just Curious';
  static const intentionCuriousDesc = 'Explore what Sakina offers';

  // Screen 2: Intention affirmations
  static const affirmSpiritualGrowth = 'A beautiful intention';
  static const affirmDifficultTime = 'You\'re in the right place';
  static const affirmBuildHabit = 'Consistency is everything';
  static const affirmCurious = 'Let\'s explore together';

  // Screen 4: Social Proof
  static const socialProofTitle = 'Sakina was made for\nhearts like yours';
  static const socialProofUserCount = '10,000';
  static const socialProofUserCountLabel = 'Muslims finding peace';
  static const socialProofRating = '4.9';
  static const socialProofRatingLabel = 'on the App Store';
  static const socialProofTestimonial1 =
      'I opened Sakina during a panic attack and the verse it showed me brought me to tears. It was exactly what I needed to hear.';
  static const socialProofTestimonial1Author = 'Amira, 24';
  static const socialProofTestimonial1Location = 'London';
  static const socialProofTestimonial2 =
      'I use Sakina every morning before Fajr. It helps me start the day with the right Name of Allah on my heart.';
  static const socialProofTestimonial2Author = 'Yusuf, 31';
  static const socialProofTestimonial2Location = 'Toronto';

  // Screen 5: Notifications
  static const notificationTitle = 'Stay connected to your practice';
  static const notificationSubtitle =
      'A gentle daily reminder to reflect on how you\'re feeling and find peace in Allah\'s words.';
  static const notificationBenefit1 = 'Daily reflection reminder';
  static const notificationBenefit2 = 'Streak protection alerts';
  static const notificationBenefit3 = 'New content notifications';
  static const notificationCta = 'Enable Notifications';
  static const notificationSkip = 'Not now';
  static const notificationFooter = 'You can change this anytime in Settings';

  // Screen 6: First Check-in
  static const checkinTitle = 'Let\'s try it';
  static const checkinSubtitle =
      'Tell us how you\'re feeling right now';
  static const checkinReflectButton = 'Reflect';
  static const checkinLoadingTitle = 'Finding your reflection...';
  static const checkinLoadingSubtitle =
      'Searching Allah\'s names and Quran';
  static const checkinResultLabel = 'Your Starting Name';
  static const checkinResultFooter = 'This is just the beginning';
  static const checkinResultUnlockCopy =
      'Personalized reflections, Quran verses, and duas — crafted just for you.';

  // Quick emotion chips (screen 6)
  static const chipAnxious = 'Anxious';
  static const chipSad = 'Sad';
  static const chipGrateful = 'Grateful';
  static const chipFrustrated = 'Frustrated';
  static const chipLost = 'Lost';
  static const chipHopeful = 'Hopeful';

  // Screen 7: Paywall
  static const paywallTitle = 'Your personal path\nto peace';
  static const paywallSubtitle =
      'Unlimited spiritual guidance from the Quran, just for you.';
  static const paywallBenefit1 = 'Connect with Allah whenever you need Him';
  static const paywallBenefit2 =
      'Beautiful audio recitation for every reflection';
  static const paywallBenefit3 = 'Never lose your spiritual streak';
  static const paywallBenefit4 = 'Revisit every moment of your journey';
  // Concrete premium unlocks shown on the paywall benefit list (2026-07-20).
  // These name the *tangible* things premium grants — unlike the older
  // emotional benefit1/3/4 copy which never said what you actually get.
  // "Unlimited" is the established term for the 30/day fair-use ceiling
  // (see gating_service.dart); benefit2's 5× applies to token/scroll daily
  // rewards (daily_rewards_service.dart), not the streak-freeze day.
  //
  // benefit5 (streak protection) is now BACKED (2026-07-22): the streak freeze
  // is a per-tier HOLD cap — free holds 1, premium holds up to
  // premiumStreakFreezeCap (3) and is topped up each month by
  // grant_premium_monthly. Enforced server-side in claim_daily_reward /
  // grant_premium_monthly via has_active_premium_entitlement (see
  // 20260722000000_streak_freeze_premium_tier.sql + daily_rewards_service.dart).
  // (benefit3, Emerald cards, is likewise backed: premium tier ceiling +
  // server-side grant RPC.)
  static const paywallPremiumBenefitsHeader = 'Everything premium unlocks';
  static const paywallPremiumBenefit1 =
      'Unlimited reflections, duʿās & Name discoveries';
  static const paywallPremiumBenefit2 = '5× daily rewards, every single day';
  static const paywallPremiumBenefit3 =
      'Exclusive Emerald cards for every Name of Allah';
  static const paywallPremiumBenefit4 = 'A monthly gift of tokens & scrolls';
  // Kept tight to match the sibling benefits' length (they wrap poorly on the
  // paywall). Keeps both value hooks: the concrete premium differentiator (3,
  // vs free's 1) and the "never lose progress" promise.
  static const paywallPremiumBenefit5 =
      '3 streak freezes so you never lose progress';
  static const paywallAnnualPrice = '\$49.99';
  static const paywallAnnualPeriod = '/year';
  static const paywallAnnualLabel = 'Yearly';
  // UNUSED since the W5 gate rebuild (2026-07-31). It was the floating badge on
  // the old side-by-side pricing cards, which the 3-page gate replaced. Left in
  // place rather than deleted because its claim now lives on as
  // `paywallPlanAnnualSavingsTemplate` — but note the two disagreed: this said 50%,
  // computed against a fabricated 2x anchor, while the real saving against the
  // weekly SKU is ~80%. If anything ever renders this again, fix the number
  // first.
  static const paywallAnnualBadge = 'SAVE 50%';
  static const paywallAnnualPerWeek = '\$0.96';
  static const paywallAnnualPerWeekLabel = 'Per Week';
  static const paywallAnnualTotal = '\$49.99 Total';
  // No static anchor string. The annual strikethrough is computed at
  // runtime from `_annualPackage.storeProduct.price` in paywall_screen.dart
  // (`_annualAnchorPrice`) so it's always in the user's storefront currency
  // (e.g. £79.99 in UK, ¥15,600 in JP, ₹6,999 in IN). A USD-only static
  // fallback would render "$99.99" next to a "£39.99" price — strictly
  // worse than no anchor at all.
  static const paywallWeeklyPrice = '\$4.99';
  static const paywallWeeklyPeriod = '/week';
  static const paywallWeeklyLabel = 'Weekly';
  static const paywallWeeklyPerWeekLabel = 'Per Week';
  static const paywallSocialProof = '4.9 \u00B7 Loved by 10,000+ Muslims';
  static const paywallStarsLabel = '4.9';
  static const paywallReviewsCount = 'from 10,000+ reviews';
  static const paywallCta = 'Start Free Trial';
  // Used when the selected plan has no introductory free trial configured
  // (or when the user is no longer eligible for one). The honest-trial
  // timeline strip hides in that mode and we billed-today copy below the
  // cards instead. Keeps the paywall from claiming a trial that StoreKit
  // won't actually grant.
  static const paywallCtaSubscribe = 'Subscribe';
  static const paywallNoTrialNote = 'Billed today \u00B7 Cancel anytime';
  static const paywallRestore = 'Restore Purchase';
  static const paywallTerms = 'Terms';
  static const paywallPrivacy = 'Privacy';

  // REMOVED 2026-08-01 (string-hygiene pass): the deprecated timeline-strip
  // constants (`paywallTimeline*`, dead since the 2026-05-14 rebuild) and the
  // `paywallHonestBilling{Annual,Weekly}` footer templates. Both blocks wrote a
  // trial length into Dart — "Day 2 / Day 3" is only correct for a 3-day offer —
  // and both had been dead on this branch since the W5 gate replaced the
  // paywall. They are gone rather than left for search-hygiene because a
  // hardcoded duration sitting in this file is what someone reaches for next.
  //
  // Every duration now derives from the store's introductory offer via
  // `TrialOffer` (lib/features/paywall/trial_offer.dart) and renders through a
  // `{trial}` placeholder — see the W5 gate block below. Nothing in paywall copy
  // may hardcode a trial length again.

  // Exit offer bottom sheet — shown when the user taps ✕ with the annual plan
  // selected, offering weekly as a price alternative (Apple guideline 5.6: a
  // different price, never a different product, and never a second full
  // paywall).
  //
  // KNOWN DIVERGENCE FROM THE APPROVED DRAFT, taken deliberately by the founder
  // on 2026-07-31. The draft's Dismissal section reads "✕ → home directly" and
  // its firewall self-check reads "scarcity: none (no offers in v1)" — by the
  // letter of both, this sheet should not exist. It is kept because it has been
  // shipping and nobody knows what it earns: deleting an unmeasured conversion
  // mechanic is a revenue decision made blind. It is now fully instrumented
  // (shown / accepted / declined, plus origin tagging through the purchase
  // chain) so the next call on it is made with data. Recorded in the W5 plan
  // doc so the two artefacts do not silently disagree.
  //
  // The hardcoded "3-day" is a `{trial}` placeholder (W5 Wave B.4) so this can
  // never again promise a duration the store will not grant.
  static const paywallExitOfferTitle = 'Wait — try weekly first?';
  static const paywallExitOfferBodyTemplate =
      'Not ready for a year? Start with the weekly plan and your {trial} free trial. Cancel anytime.';
  static const paywallExitOfferAcceptTemplate = 'Start {trial} free trial';
  static const paywallExitOfferDecline = 'No thanks';

  // ───── W5 gate — the approved 3-page paywall ─────
  // Copy is the founder-approved draft
  // (docs/superpowers/content/2026-07-25-paywall-DRAFT.md) as rendered by the
  // approved visual mock (docs/superpowers/mocks/2026-07-31-paywall-visual-mock.html).
  // It is LOCKED. Every duration is a `{trial}` placeholder filled from the
  // store's introductory offer (`TrialOffer.label`) — never a literal, so copy
  // can no longer disagree with what StoreKit will actually grant.

  // Page 1 — `value_depth`. Two variants keyed by the hook contract the user
  // chose: `problem` (they named something) and `sign` (they could not put it
  // into words). {name} is the transliteration of the Name the reveal awarded.
  static const paywallValueDepthHeadlineTemplate = 'You\'ve met {name}.';
  static const paywallValueDepthHeadlineSignTemplate =
      'You\'ve met {name} — the first Name of your journey.';
  static const paywallValueDepthSubline =
      'Premium goes deeper into what you named:';
  static const paywallValueDepthSublineSign = 'Premium goes deeper, every day:';
  // The draft writes bullet 1 as "A personal reflection on {chip phrase}" and
  // defines {chip phrase} as "canonical chip phrasing only, never raw free
  // text". No canonical noun-phrase form of a chip exists in the taxonomy —
  // the labels are first-person clauses ("My mind won't stop racing") that do
  // not fit the slot — and the approved mock resolves the slot to this one
  // constant. Rendering the mock's literal is the only reading that invents no
  // copy; a per-chip phrase map would be six new marketing strings.
  // Rewritten 2026-08-01 (founder). The three gains carried the entire
  // premium argument and, checked against the live free tier, two of them did
  // not differentiate anything:
  //
  //  * Bullet 2 named no frequency at all, and Build-a-Duʿā is a FREE feature
  //    — so it described the product rather than the upgrade.
  //  * Bullet 3 promised the journal. `lib/features/journal/` contains no
  //    GatingService reference, no premium check, and no row cap: the journal
  //    is unlimited for everyone. Listing it under "Premium goes deeper"
  //    implied a gain that does not exist.
  //
  // What is actually behind the paywall is a FREQUENCY ceiling, so each line
  // now names one. Bullet 3 moves to the second daily Name, which is a real
  // gate (`discoverName` is 1/day free) and ties back to the card above it.
  //
  // **Stated as what PREMIUM gives, never as what free withholds** (founder,
  // 2026-08-01). An interim draft read "Unlimited reflections — free gives
  // you three a week". It differentiated well but was wrong for THIS surface:
  // the ceremony is a user's first exposure, before they have hit any cap, so
  // naming the free allowance advertises the free tier at the moment the
  // screen asks for money and teaches a limit they had not yet met. The
  // contrast still gets delivered — by `DailyCapSheet` ("Your reflections for
  // this week are used — Premium is unlimited"), at the moment it is actually
  // felt.
  //
  // It also removes a real trap: a number here would have been
  // `app_config.weekly_pool_size`, a runtime dial, so tuning it would have
  // turned a shipped purchase surface into a false claim with no code change.
  // Do not reintroduce a free-tier quantity on this page — pinned by
  // `test/features/paywall/paywall_copy_matches_dials_test.dart`.
  static const paywallValueDepthBullet1 =
      'Unlimited reflections, day or night';
  static const paywallValueDepthBullet1Sign = paywallValueDepthBullet1;
  static const paywallValueDepthBullet2 =
      'Your own duʿā, whenever you need one';
  static const paywallValueDepthBullet2Sign =
      'Your own duʿā, even when the words won\'t come';
  static const paywallValueDepthBullet3 =
      'A new Name of Allah whenever you want one';
  static const paywallGateContinue = 'Continue';

  // Page 2 — `trial_timeline`. The middle beat rides Apple's SYSTEM
  // trial-ending notice (24h before charge), which is the plan's "one allowed
  // clock": no app-scheduled second reminder, and true regardless of the
  // user's notification permission. {day} values are derived from the trial's
  // day count, so a 3-day trial reads "Day 2 / Day 3" and a 7-day one reads
  // "Day 6 / Day 7" with no copy change.
  static const paywallTrialTimelineHeadlineTemplate =
      'Try everything free for {trial}.';
  static const paywallTrialTimelineTodayHeading = 'Today';
  static const paywallTrialTimelineTodayBody =
      'Everything unlocks: daily reflections and your own duʿās, saved to your journal.';
  static const paywallTrialTimelineDayHeadingTemplate = 'Day {day}';
  static const paywallTrialTimelineReminderBody =
      'Apple reminds you before your trial ends.';
  static const paywallTrialTimelineChargeBody =
      'Your plan begins. Cancel anytime before — no charge.';
  static const paywallTrialTimelineFootnote = 'No charge today.';

  // Page 3 — `plan_select`. The benefit checklist reuses the five shipped
  // `paywallPremiumBenefit1-5` strings verbatim.
  static const paywallPlanSelectHeadline = 'Choose how you continue.';
  // Checkable against the weekly row directly below it, which is the whole
  // point of stating it this way: \$49.99/year against \$4.99/week × 52
  // (\$259.48) is an 80.7% saving. The shipped `paywallAnnualBadge` said 50%,
  // computed against a fabricated 2x anchor rather than against the plan we
  // actually sell beside it — founder corrected this to 80% on 2026-07-31.
  //
  // `{percent}` IS COMPUTED AT RUNTIME (`_annualSavingsLabel`) from the two
  // live packages, for the same reason the annual strikethrough anchor is
  // (see `paywallAnnualPerWeek` above). Apple's price tiers are not
  // proportional across territories, so a frozen "80%" can be arithmetically
  // false in a storefront where both numbers beside it are localised — on the
  // one screen whose layout invites the user to check the subtraction. There
  // is deliberately NO static fallback: when the packages will not load the
  // sticker is not rendered, because a wrong saving is worse than none.
  static const paywallPlanAnnualSavingsTemplate = 'Save {percent}% vs weekly';
  static const paywallPlanAnnualPriceTemplate = '{price}/year · {perWeek} a week';
  static const paywallPlanWeeklyRowTemplate = 'Weekly — {price}/week';
  static const paywallGateCtaTrialTemplate = 'Start my {trial} free';
  // Plain terms under the CTA. `textSecondaryLight` minimum, never tertiary —
  // billing terms must stay legible (draft build rule S4-S6).
  static const paywallGateTermsTrialTemplate =
      'Free for {trial}, then {price}. Cancel anytime in Settings.';
  static const paywallGateTermsNoTrialTemplate =
      '{price}. Cancel anytime in Settings.';

  // The one-time reverent card shown after ✕ on any page, before home.
  static const paywallAlwaysFreeCardBody =
      'The 99 Names, your daily Name and its story, and your streak are yours — always free.';

  // Condensed `soft_inapp` surface. The draft's example value line names a
  // weekly pool ("Your reflections for this week are used"), which is only
  // true once W5 Wave D lands the weekly allowance — under today's daily cap
  // it would ship false. So the default states what premium GIVES and makes no
  // period claim; `PaywallScreen.softValueLine` is the seam for Wave D to pass
  // the trigger-specific line once the pool is authoritative.
  static const paywallSoftGateDefaultLine =
      'Premium is unlimited — every reflection, every duʿā, '
      'every Name of Allah.';

  // ── Legal URLs ──
  // Hosted on GitHub Pages via the public `ibrahim7860/sakina-legal` repo.
  // Update when the legal repo moves to a custom domain (e.g. legal.sakina.app).
  static const privacyPolicyUrl =
      'https://ibrahim7860.github.io/sakina-legal/privacy.html';
  static const termsOfServiceUrl =
      'https://ibrahim7860.github.io/sakina-legal/terms.html';

  // ── New Onboarding Screens ──

  // Screen 3: Value Prop
  static const valuePropHeadline =
      'Sakina connects your emotions to divine wisdom';
  static const valuePropSubtitle =
      'A personalized spiritual reflection in seconds';
  static const valuePropStep1 = 'How you feel';
  static const valuePropStep2 = 'Name of Allah';
  static const valuePropStep3 = 'Quran verse & dua';

  // Screen 4: Familiarity
  static const familiarityTitle =
      'How familiar are you with the 99 Names of Allah?';
  static const familiaritySubtitle = 'No wrong answers here';
  static const familiarityBeginner = 'Just Getting Started';
  static const familiarityBeginnerDesc = 'I know a few, want to learn more';
  static const familiaritySomewhat = 'Somewhat Familiar';
  static const familiaritySomewhatDesc = 'I know many and their meanings';
  static const familiarityVeryFamiliar = 'Very Familiar';
  static const familiarityVeryFamiliarDesc =
      'I study them regularly';

  // Screen 5: Quran Connection
  static const quranConnectionTitle =
      'How often do you connect with the Quran?';
  static const quranConnectionSubtitle =
      'This helps us tailor your reflections';
  static const quranDaily = 'Daily';
  static const quranDailyDesc = 'Part of my daily routine';
  static const quranWeekly = 'Weekly';
  static const quranWeeklyDesc = 'A few times a week';
  static const quranOccasionally = 'Occasionally';
  static const quranOccasionallyDesc = 'When I feel the need';
  static const quranRarely = 'Rarely';
  static const quranRarelyDesc = 'I want to reconnect';

  // Screen 6: Attribution
  static const attributionTitle = 'Where did you hear about Sakina?';
  static const attributionSubtitle = 'Select all that apply';
  static const attributionTikTok = 'TikTok';
  static const attributionInstagram = 'Instagram';
  static const attributionYouTube = 'YouTube';
  static const attributionFriend = 'Friend / Family';
  static const attributionAppStore = 'App Store';
  static const attributionMosque = 'Mosque';
  static const attributionTwitter = 'Twitter / X';
  static const attributionOther = 'Other';

  // Screen 7: Encouragement
  static const encouragementHeadlineSpiritualGrowth =
      'Your journey to deeper faith starts now';
  static const encouragementHeadlineDifficultTime =
      'Allah is closer to you than you think';
  static const encouragementHeadlineBuildHabit =
      'Small daily steps lead to lasting change';
  static const encouragementHeadlineCurious =
      'You\'re about to discover something beautiful';
  static const encouragementHeadlineDefault =
      'Something beautiful awaits you';
  static const encouragementSubtitleBeginner =
      'Sakina will gently introduce you to the Names of Allah through your everyday emotions.';
  static const encouragementSubtitleSomewhat =
      'Sakina will deepen your understanding by connecting the Names to how you feel each day.';
  static const encouragementSubtitleVeryFamiliar =
      'Sakina will bring fresh perspective to the Names you already know through emotional reflection.';
  static const encouragementSubtitleDefault =
      'Sakina will guide you to the perfect reflection for every moment.';
  static const encouragementBismillah = '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650';

  // Screen 10: Generating
  static const generatingTitle = 'Preparing your reflection\u2026';
  static const generatingStep1 = 'Analyzing your feelings';
  static const generatingStep2 = 'Finding the right Name of Allah';
  static const generatingStep3 = 'Selecting your verse & dua';

  /// 4th step added 2026-05-05 — paywall flow loader uses 4 steps over 3.5s.
  /// Earlier steps (1-3) keep their existing copy when reused mid-flow; the
  /// onboarding-loader role uses paywallFlowGeneratingStep1..4 below.
  static const paywallFlowGeneratingStep1 = 'Reading your reflections';
  static const paywallFlowGeneratingStep2 = 'Mapping you to Allah\'s Names';
  static const paywallFlowGeneratingStep3 = 'Curating verses for your heart';
  static const paywallFlowGeneratingStep4 = 'Setting your daily rhythm';

  // ───── Paywall flow — Your Journey screen (page 24) ─────
  // Copy is qualitative, not quantified — the gacha + streak system can't
  // guarantee specific Name/reflection counts (OV8 in eng review).
  static const paywallFlowJourneyHeadlineTemplate =
      'Where you\'ll be in 30 days, {name}.';
  static const paywallFlowJourneySubtitle = 'Your habit, mapped out.';
  static const paywallFlowJourneyDay1Heading = 'Day 1 — Today';
  static const paywallFlowJourneyDay1Line1 = 'Your first reflection, saved';
  // {name} placeholder filled at render time with the user's starter Name translit.
  static const paywallFlowJourneyDay1Line2Template =
      '{name} — your first Name in the collection';
  static const paywallFlowJourneyDay7Heading = 'Day 7 — One week in';
  static const paywallFlowJourneyDay7Line1 = 'A streak you\'re proud of';
  static const paywallFlowJourneyDay7Line2 =
      'New Names of Allah in your collection';
  static const paywallFlowJourneyDay7Line3 = 'Reflections to look back on';
  static const paywallFlowJourneyDay30Heading = 'Day 30 — One month';
  static const paywallFlowJourneyDay30Line1 =
      'A habit that holds — no missed days';
  static const paywallFlowJourneyDay30Line2 =
      'A growing collection of Names';
  static const paywallFlowJourneyDay30Line3 = 'A journal of how Allah met you';
  static const paywallFlowJourneyDay30Line4 = 'Closer to Allah, every day';
  // {minutes} replaced at render time with state.dailyCommitmentMinutes.
  static const paywallFlowJourneyFooterTemplate =
      'Built on {minutes} minutes a day.';
  static const paywallFlowJourneyCta = 'Begin my 30 days';

  // ───── Paywall additions (page 25) ─────
  // {name} replaced at render time with state.signUpName (or "friend").
  static const paywallPersonalizedHeaderTemplate = 'YOU\'RE 1 STEP AWAY, {name}';
  // REMOVED 2026-08-01 (string-hygiene pass): `paywallTrialMicrocopyTemplate`,
  // `paywallTrialMicrocopyWeeklyTemplate` and `paywallCtaTrial` — all three
  // hardcoded "3 days". Dead on this branch since the W5 gate; their live
  // equivalents are `paywallGateTermsTrialTemplate` and
  // `paywallGateCtaTrialTemplate`, whose `{trial}` slot is filled from
  // `TrialOffer.label` (the store's actual introductory offer).
  static const paywallNoPaymentTodayLine = 'No payment due today.';
  static const paywallCtaSubscribeRevised = 'Start your subscription';

  // ───── Personalized Plan screen (page 23) ─────
  static const personalizedPlanRibbon = '✨ Crafted for you';

  // ───── Encouragement #2 tease (page 21) — OV4 mitigation ─────
  static const encouragementPlanReadyTease =
      'Your plan is ready, just past the gate.';
  static const generatingBismillah = '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 \u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0646\u0650 \u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650';

  // Screen 12: Sign-Up Choice
  static const signUpChoiceTitle = 'Save your progress';
  static const signUpChoiceSubtitle =
      'Keep your reflections, streaks, and progress safe across devices.';
  static const signUpChoiceApple = 'Sign in with Apple';
  static const signUpChoiceGoogle = 'Sign in with Google';
  static const signUpChoiceEmail = 'Continue with Email';
  static const signUpChoiceOrDivider = 'or';

  // Screen 13: Name
  static const signUpNameTitle = "What's your name?";
  static const signUpNameHint = 'Full name';

  // Screen 14: Email
  static const signUpEmailTitle = "What's your email?";
  static const signUpEmailHint = 'Email address';

  // Screen 15: Password
  static const signUpPasswordTitle = 'Create a password';
  static const signUpPasswordHint = 'Password';
  static const signUpPasswordSubtitle = 'At least 6 characters';
  static const signUpPasswordCta = 'Create Account';

  // Sign In screen
  static const signInTitle = 'Welcome back';
  static const signInSubtitle = 'Sign in to continue your journey';
  static const signInApple = 'Sign in with Apple';
  static const signInGoogle = 'Sign in with Google';
  static const signInEmailLabel = 'Email';
  static const signInPasswordLabel = 'Password';
  static const signInButton = 'Sign In';
  static const signInForgotPassword = 'Forgot password?';
  static const signInBackToOnboarding = 'Back to onboarding';

  // Shared
  static const continueButton = 'Continue';
  static const encouragementButton = 'Discover a Name of Allah';
}
