import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/keyboard.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_autofocus_text_field.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class SignUpEmailScreen extends ConsumerStatefulWidget {
  const SignUpEmailScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  // Pragmatic RFC-5322 subset: local-part, `@`, dot-separated domain labels,
  // TLD ≥ 2 letters. Rejects the garbage the old `contains('@') && contains('.')`
  // check waved through (`a@.`, `me@@x.com`, `test@.com`) that then failed at
  // the Supabase auth layer with no analytics trail.
  //
  // Unicode-aware (`\p{L}` letters + `\p{N}` digits + `\p{M}` combining marks,
  // with `unicode: true`): Supabase auth accepts internationalized addresses, so
  // we do too — `josé@example.com` (precomposed U+00E9 OR NFD `e`+U+0301),
  // `用户@例え.jp`, `çağrı@example.com.tr`. The ASCII-only predecessor
  // (`[a-zA-Z0-9]`) bounced Turkish/French/CJK users out of signup with a
  // misleading "valid email" error. `\p{M}` is what makes the NFD
  // (decomposed-diacritic) forms many keyboards / paste sources emit pass —
  // without it `josé` typed as `e`+combining-acute is rejected.
  //
  // Strictness scope: DOMAIN labels forbid leading/trailing/double dots and a
  // <2-letter or digit-bearing TLD. The LOCAL-part is intentionally lenient on
  // dots (Supabase accepts it; tightening risks false-rejects). Homograph /
  // confusable letters (e.g. Cyrillic `а`) are accepted — that's the cost of
  // i18n email, and it's the user's OWN address received at signup, not a
  // trust anchor shown to others.
  static final RegExp emailRegex = RegExp(
    r'^[\p{L}\p{N}\p{M}._%+\-]+@[\p{L}\p{N}](?:[\p{L}\p{N}\p{M}\-]*[\p{L}\p{N}\p{M}])?'
    r'(?:\.[\p{L}\p{N}](?:[\p{L}\p{N}\p{M}\-]*[\p{L}\p{N}\p{M}])?)*\.[\p{L}\p{M}]{2,}$',
    unicode: true,
  );

  static bool isValidEmail(String text) => emailRegex.hasMatch(text.trim());

  @override
  ConsumerState<SignUpEmailScreen> createState() => _SignUpEmailScreenState();
}

class _SignUpEmailScreenState extends ConsumerState<SignUpEmailScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingProvider).signUpEmail;
    if (existing != null) _controller.text = existing;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValidEmail => SignUpEmailScreen.isValidEmail(_controller.text);

  void _submit() {
    if (!_isValidEmail) return;
    dismissKeyboard(context);
    ref
        .read(onboardingProvider.notifier)
        .setSignUpEmail(_controller.text.trim());
    // Auth sub-flow (2026-06-15 audit, A2): the email screen advanced with a
    // valid address. Lets the funnel distinguish an email-screen drop from a
    // password-screen drop. NO PII — we emit the event only, never the address.
    ref.read(analyticsProvider).track(AnalyticsEvents.signupEmailSubmitted);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    // Email screen sits at PageView index 19. Autofocus only when actually
    // displayed. (progressSegment is the visual segment number = 21, which
    // is offset from PageView index by +2 due to removed Generating/PersonalPlan
    // pages — keep that value.)
    final isActive = ref.watch(
      onboardingProvider.select(
        (state) => state.currentPage == onboardingEmailPageIndex,
      ),
    );

    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      behavior: HitTestBehavior.translucent,
      child: OnboardingPageWrapper(
        progressSegment: 21,
        onBack: () {
          dismissKeyboard(context);
          widget.onBack();
        },
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.signUpEmailTitle,
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.03, end: 0),
                    const Spacer(),
                    OnboardingAutofocusTextField(
                      controller: _controller,
                      shouldRequestFocus: isActive,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      // Keyboard's return key only dismisses — matches the
                      // dominant pattern across the app (dua_topics,
                      // first_checkin, reflect, etc.). Continue button is the
                      // single source of truth for advancing.
                      onSubmitted: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      decoration: InputDecoration(
                        hintText: AppStrings.signUpEmailHint,
                        hintStyle: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    if (_controller.text.trim().isNotEmpty && !_isValidEmail) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Please enter a valid email',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    OnboardingContinueButton(
                      label: AppStrings.continueButton,
                      onPressed: _submit,
                      enabled: _isValidEmail,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
