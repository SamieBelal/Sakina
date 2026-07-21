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
  // ⚠️ SHIPPED AHEAD OF MECHANIC (owner-approved 2026-07-20): benefit5
  // (streak protection) is NOT premium-exclusive (free users get the same
  // freeze), so the claim is still unbacked. Must be backed before/at the
  // next App Store submission — tracked in TODO.md ("Back the paywall's
  // premium-benefit claims"). 3.1.1 exposure until then. (benefit3, Emerald
  // cards, is now backed: premium tier ceiling + server-side grant RPC.)
  static const paywallPremiumBenefitsHeader = 'Everything premium unlocks';
  static const paywallPremiumBenefit1 =
      'Unlimited reflections, duʿās & Name discoveries';
  static const paywallPremiumBenefit2 = '5× daily rewards, every single day';
  static const paywallPremiumBenefit3 =
      'Exclusive Emerald cards for every Name';
  static const paywallPremiumBenefit4 = 'A monthly gift of tokens & scrolls';
  static const paywallPremiumBenefit5 =
      'Streak protection so you never lose progress';
  static const paywallAnnualPrice = '\$49.99';
  static const paywallAnnualPeriod = '/year';
  static const paywallAnnualLabel = 'Yearly';
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

  // Honest trial timeline strip (above pricing cards). Labels stay one
  // word each so the strip reads at a glance instead of as paragraph copy.
  //
  // DEPRECATED 2026-05-14 (paywall rebuild): the strip itself has been
  // removed in favour of the single-line `paywallHonestBilling*` footer
  // below. These constants are intentionally left in place to avoid
  // breaking unrelated tests / search results during the rebuild — they
  // will be cleaned up in a separate string-hygiene pass.
  static const paywallTimelineTodayHeading = 'Today';
  static const paywallTimelineTodayLabel = 'Free';
  static const paywallTimelineDay2Heading = 'Day 2';
  static const paywallTimelineDay2Label = 'Reminder';
  static const paywallTimelineDay3Heading = 'Day 3';
  static const paywallTimelineDay3Label = 'Charged';

  // Honest-billing footer copy (paywall rebuild, 2026-05-14).
  // Templates accept a {price} placeholder rendered from
  // `package.storeProduct.priceString`. The "Day N" reminder references
  // Apple's automatic trial-ending notification (24h before charge),
  // NOT a Sakina-side email — we don't send those. Reviewer-compliant
  // and factually accurate. Per Blinkist's public case study, this
  // single-line explicit billing copy lifts conversion ~23% and reduces
  // refund complaints ~55%.
  static const paywallHonestBillingAnnual =
      'Today: full access. Day 6: Apple sends a trial-ending reminder. Day 7: {price}/year unless cancelled. Cancel anytime in Settings.';
  static const paywallHonestBillingWeekly =
      'Today: full access. Day 2: Apple sends a trial-ending reminder. Day 3: {price}/week unless cancelled. Cancel anytime in Settings.';

  // Exit offer bottom sheet (shown when user taps X on annual selection).
  static const paywallExitOfferTitle = 'Wait — try weekly first?';
  static const paywallExitOfferBody =
      'Not ready for a year? Start with the weekly plan and your 3-day free trial. Cancel anytime.';
  static const paywallExitOfferAccept = 'Start 3-day free trial';
  static const paywallExitOfferDecline = 'No thanks';

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
  // {price} replaced at render time with annual price string from RevenueCat.
  static const paywallTrialMicrocopyTemplate =
      '3 days free, then {price}/year. Cancel anytime.';
  static const paywallNoPaymentTodayLine = 'No payment due today.';
  // CTA copy upgrade (OV9) — brand-name in CTA lifts conversion.
  static const paywallCtaTrial = 'Try Sakina Free for 3 days';
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
