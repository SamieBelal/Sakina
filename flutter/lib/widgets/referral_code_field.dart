import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../services/referral_service.dart';

/// State machine for [ReferralCodeField].
///
/// - [empty]: input cleared — no chip rendered, no RPC fires.
/// - [tooShort]: 1-7 chars typed — no chip rendered, no RPC fires.
/// - [validating]: 8+ chars settled past the 300ms debounce — RPC in-flight.
/// - [valid]: server confirmed the code matches another user.
/// - [invalid]: server returned false (no match, self-code, etc.) — soft-fail UX.
/// - [networkError]: RPC threw — also soft-fail; the actual apply happens
///   server-side at signup so a transient verification failure here is OK.
enum ReferralCodeValidationState {
  empty,
  tooShort,
  validating,
  valid,
  invalid,
  networkError,
}

/// Shared input widget for entering a referral code with debounced live
/// validation.
///
/// Used by:
///   * `SaveProgressScreen` (onboarding page 18) — "Did a friend send you
///      a gift?" optional collapsible field.
///   * `ReferralRedeemSheet` (Settings → Redeem a Code) — post-signup entry
///      for users who already finished onboarding without a code.
///
/// Behavior contract (pinned by `test/widgets/referral_code_field_test.dart`):
///   * Coerces input to uppercase + filters to the
///     `[A-HJ-NP-Z2-9]` alphabet (excludes I, O, 0, 1).
///   * Hard caps input at 16 chars; reports state=tooShort below 8.
///   * Debounces RPC calls by 300ms (cancel + restart on each keystroke).
///   * Clearing the field bypasses debounce — state flips to empty
///     immediately so the user sees the chip disappear.
///   * `onCodeChanged` only fires on the SETTLED state (debounce trailing
///     edge), NOT per keystroke. Saves the parent from re-rendering on
///     every character.
///   * Soft-fail on invalid/networkError — never red error styling, never
///     blocks the parent's continue button. The server is the source of
///     truth at signup.
class ReferralCodeField extends ConsumerStatefulWidget {
  const ReferralCodeField({
    super.key,
    required this.onCodeChanged,
    this.initialValue,
    this.autofocus = false,
  });

  /// Fires on the debounced trailing edge with the most-recent settled
  /// code + validation state. Does NOT fire per keystroke.
  final void Function(String code, ReferralCodeValidationState state)
      onCodeChanged;

  /// Optional initial value to seed the controller (e.g. when re-entering
  /// the field after backing out of a later onboarding page).
  final String? initialValue;

  /// If true, request focus in a post-frame callback after mount. Use false
  /// when embedding inside a collapsible card so the parent controls focus.
  final bool autofocus;

  @override
  ConsumerState<ReferralCodeField> createState() => _ReferralCodeFieldState();
}

class _ReferralCodeFieldState extends ConsumerState<ReferralCodeField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  ReferralCodeValidationState _state = ReferralCodeValidationState.empty;

  // Monotonic counter so a slow in-flight RPC for an older code can't
  // overwrite the state for a newer one (race guard).
  int _validationToken = 0;

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    // Clearing should feel snappy — bypass debounce so the chip vanishes
    // immediately rather than 300ms later.
    if (raw.isEmpty) {
      _debounce?.cancel();
      // Bump the token so any in-flight validation is invalidated.
      _validationToken++;
      _setState(ReferralCodeValidationState.empty);
      widget.onCodeChanged('', ReferralCodeValidationState.empty);
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _settle(raw));
  }

  Future<void> _settle(String code) async {
    if (!mounted) return;
    if (code.length < 8) {
      _setState(ReferralCodeValidationState.tooShort);
      widget.onCodeChanged(code, ReferralCodeValidationState.tooShort);
      return;
    }

    final token = ++_validationToken;
    _setState(ReferralCodeValidationState.validating);
    widget.onCodeChanged(code, ReferralCodeValidationState.validating);

    ReferralCodeValidationState next;
    try {
      final ok = await ref.read(referralServiceProvider).validateCode(code);
      next = ok
          ? ReferralCodeValidationState.valid
          : ReferralCodeValidationState.invalid;
    } catch (_) {
      // ReferralService.validateCode rethrows on RPC failure (2026-05-25
      // change) so we can distinguish "server said no" (invalid) from
      // "couldn't reach the server" (networkError). This catch is the
      // canonical handler for the network-error branch.
      next = ReferralCodeValidationState.networkError;
    }

    // Race guard: a newer keystroke superseded us, or the widget was
    // disposed mid-await — drop this result.
    if (!mounted || token != _validationToken) return;
    _setState(next);
    widget.onCodeChanged(code, next);
  }

  void _setState(ReferralCodeValidationState next) {
    if (_state == next) return;
    setState(() => _state = next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            // Inline uppercase coercion (don't extract — keeps the
            // formatter list locally auditable).
            TextInputFormatter.withFunction((old, newVal) =>
                newVal.copyWith(text: newVal.text.toUpperCase())),
            FilteringTextInputFormatter.allow(RegExp(r'[A-HJ-NP-Z2-9]')),
            LengthLimitingTextInputFormatter(16),
          ],
          onChanged: _onChanged,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimaryLight,
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'Enter their code',
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textTertiaryLight,
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        if (_buildChip() case final Widget chip) ...[
          const SizedBox(height: AppSpacing.sm),
          chip,
        ],
      ],
    );
  }

  Widget? _buildChip() {
    switch (_state) {
      case ReferralCodeValidationState.empty:
      case ReferralCodeValidationState.tooShort:
        return null;
      case ReferralCodeValidationState.validating:
        return const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        );
      case ReferralCodeValidationState.valid:
        return Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Valid gift code',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
          ],
        );
      case ReferralCodeValidationState.invalid:
        return Row(
          children: [
            const Icon(Icons.help_outline_rounded,
                color: AppColors.textTertiaryLight, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                "We didn't find that code",
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiaryLight),
              ),
            ),
          ],
        );
      case ReferralCodeValidationState.networkError:
        return Row(
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textTertiaryLight, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                "Couldn't check right now — we'll verify when you sign up.",
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiaryLight),
              ),
            ),
          ],
        );
    }
  }
}
