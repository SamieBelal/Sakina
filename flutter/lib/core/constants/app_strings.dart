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
  static const intentionSubtitle = 'This helps us personalize your experience';
  static const intentionSpiritualGrowth = 'Spiritual Growth';
  static const intentionSpiritualGrowthDesc = 'Deepen my connection with Allah';
  static const intentionDifficultTime = 'Difficult Time';
  static const intentionDifficultTimeDesc = 'Find comfort in Allah\'s words';
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
  static const checkinSubtitle = 'Tell us how you\'re feeling right now';
  static const checkinReflectButton = 'Reflect';
  static const checkinLoadingTitle = 'Finding your reflection...';
  static const checkinLoadingSubtitle = 'Searching Allah\'s names and Quran';
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

  // W5 paywall — the five canonical Premium entitlements. These strings are
  // rendered verbatim by the complete checklist on page 3 and may be reused
  // by separate condensed purchase surfaces.
  static const paywallPremiumBenefit1 =
      'Unlimited reflections, duʿās & Name discoveries';
  static const paywallPremiumBenefit2 = '5× daily rewards, every single day';
  static const paywallPremiumBenefit3 =
      'Exclusive Emerald cards for every Name of Allah';
  static const paywallPremiumBenefit4 = 'A monthly gift of tokens & scrolls';
  static const paywallPremiumBenefit5 =
      '3 streak freezes so you never lose progress';
  static const paywallAnnualPeriod = '/year';
  static const paywallAnnualLabel = 'Yearly';
  static const paywallWeeklyPeriod = '/week';
  static const paywallWeeklyLabel = 'Weekly';
  static const paywallCtaSubscribe = 'Subscribe';
  static const paywallRestore = 'Restore Purchase';
  static const paywallTerms = 'Terms';
  static const paywallPrivacy = 'Privacy';

  // Offer-state and purchase-flow copy. Keeping these here prevents one
  // surface from inventing a different failure or loading message.
  static const paywallOffersLoading = 'Loading subscription options…';
  static const paywallOffersUnavailable =
      'Unable to load subscription options right now. Please try again.';
  static const paywallPurchaseFailed =
      'We couldn\'t complete your purchase. Please try again.';
  static const paywallRestoreFailed =
      'We couldn\'t restore your purchase. Please try again.';
  static const paywallPremiumNotActive =
      'Premium access is not active yet. Please try restoring your purchase.';
  static const paywallRestoreNotFound =
      'No active premium subscription was found to restore.';
  static const paywallLegalPageUnavailable =
      'Could not open the page. Try again.';
  static const paywallRestoring = 'Restoring…';
  static const paywallExitOfferNoTrialBodyTemplate =
      'Not ready for a year? Try the weekly plan — {price}/week, cancel anytime.';
  static const paywallExitOfferAfterTrialTemplate =
      '{price} / week after trial';
  static const paywallExitOfferTryWeekly = 'Try weekly';

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
  // The duration is a `{trial}` placeholder (W5 Wave B.4) so this can never
  // promise a duration the store will not grant.
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

  // Page 1 — `value_depth`. The headline is personalized with the Name the
  // reveal awarded. Its three claims are deliberately distinct from the
  // complete Premium entitlement checklist on page 3.
  static const paywallValueDepthHeadlineFallback = 'Made for this moment.';
  static const paywallValueDepthHeadlineTemplate = 'You\'ve met {name}.';
  static const paywallValueDepthHeadlineSignTemplate =
      'You\'ve met {name} — the first Name of your journey.';
  static const paywallValueDepthSubline =
      'Premium goes deeper into what you named:';
  static const paywallValueDepthSublineSign = 'Premium goes deeper, every day:';
  static const paywallValueDepthBullet1 =
      'Reflections that meet you where you are.';
  static const paywallValueDepthBullet1Sign = paywallValueDepthBullet1;
  static const paywallValueDepthBullet2 =
      'Space for the duʿā you\'re carrying.';
  static const paywallValueDepthBullet2Sign = paywallValueDepthBullet2;
  static const paywallValueDepthBullet3 =
      'A Name of Allah to return to when you need one.';
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
      'Your trial starts today with full Premium access.';
  static const paywallTrialTimelineDayHeadingTemplate = 'Day {day}';
  static const paywallTrialTimelineReminderBody =
      'Apple reminds you before your trial ends.';
  static const paywallTrialTimelineChargeBody =
      'Your selected plan begins after the trial. Cancel anytime before renewal.';
  static const paywallTrialTimelineFootnote = 'No charge today.';

  // Page 3 — `plan_select`. The benefit checklist reuses the five shipped
  // `paywallPremiumBenefit1-5` strings verbatim.
  static const paywallPlanSelectHeadline = 'Choose how you continue.';
  // `{percent}` is computed at runtime (`_annualSavingsLabel`) from the two
  // live packages. Apple's price tiers are not proportional across territories,
  // so a frozen percentage can be arithmetically false beside localised prices.
  // There is deliberately no static fallback: when packages will not load, the
  // sticker is not rendered because a wrong saving is worse than none.
  static const paywallPlanAnnualSavingsTemplate = 'Save {percent}% vs weekly';
  static const paywallPlanAnnualPriceTemplate =
      '{price}/year · {perWeek} a week';
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
  static const familiarityVeryFamiliarDesc = 'I study them regularly';

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
  static const encouragementHeadlineDefault = 'Something beautiful awaits you';
  static const encouragementSubtitleBeginner =
      'Sakina will gently introduce you to the Names of Allah through your everyday emotions.';
  static const encouragementSubtitleSomewhat =
      'Sakina will deepen your understanding by connecting the Names to how you feel each day.';
  static const encouragementSubtitleVeryFamiliar =
      'Sakina will bring fresh perspective to the Names you already know through emotional reflection.';
  static const encouragementSubtitleDefault =
      'Sakina will guide you to the perfect reflection for every moment.';
  static const encouragementBismillah =
      '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650';

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
  static const paywallFlowJourneyDay30Line2 = 'A growing collection of Names';
  static const paywallFlowJourneyDay30Line3 = 'A journal of how Allah met you';
  static const paywallFlowJourneyDay30Line4 = 'Closer to Allah, every day';
  // {minutes} replaced at render time with state.dailyCommitmentMinutes.
  static const paywallFlowJourneyFooterTemplate =
      'Built on {minutes} minutes a day.';
  static const paywallFlowJourneyCta = 'Begin my 30 days';

  // ───── Personalized Plan screen (page 23) ─────
  static const personalizedPlanRibbon = '✨ Crafted for you';
  static const personalizedPlanFallbackName = 'Ar-Rahman';
  static const personalizedPlanDefaultReminder = '08:00';
  static const personalizedPlanDefaultName = 'friend';
  static const personalizedPlanDefaultIntention = 'growing closer to Allah';
  static const personalizedPlanTitleTemplate = 'Your plan, {name}.';
  static const personalizedPlanSubtitle = 'Everything you need, one tap away.';
  static const personalizedPlanFirstNameLabel = 'First Name in your collection';
  static const personalizedPlanDailyCheckInLabel = 'Your daily check-in';
  static const personalizedPlanWhyHereLabel = 'Why you\'re here';
  static const personalizedPlanMinutesTemplate = '{minutes} min  ·  {time}';

  // ───── Value prop screen (legacy paywall-flow step) ─────
  static const valuePropAspirationMorePatient = 'more patient';
  static const valuePropAspirationMoreGrateful = 'more grateful';
  static const valuePropAspirationCloserToAllah = 'closer to Allah';
  static const valuePropAspirationMorePresent = 'more present';
  static const valuePropAspirationStrongerFaith = 'stronger in faith';
  static const valuePropAspirationMoreConsistent = 'more consistent';
  static const valuePropAspirationDefault = 'who you want to be';
  static const valuePropHeadlineTemplate =
      'Sakina helps you become {aspiration}.';
  static const valuePropFlowSubtitle =
      'In the time you already have — even 1 minute a day.';
  static const valuePropDailyCheckInTitle = 'Daily check-in';
  static const valuePropDailyCheckInBody =
      'Name your feeling, meet it with Qur\'an.';
  static const valuePropNamesTitle = '99 Names';
  static const valuePropNamesBody = 'Collect, study, and reflect.';
  static const valuePropJournalTitle = 'Your journal';
  static const valuePropJournalBody = 'Every reflection saved.';

  // ───── Encouragement #2 tease (page 21) — OV4 mitigation ─────
  static const encouragementPlanReadyTease =
      'Your plan is ready, just past the gate.';
  static const generatingBismillah =
      '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 \u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0646\u0650 \u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650';

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
