import 'package:flutter/material.dart';

class OnboardingAutofocusTextField extends StatefulWidget {
  const OnboardingAutofocusTextField({
    required this.controller,
    required this.decoration,
    required this.shouldRequestFocus,
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onSubmitted,
    this.autofocusDelay = const Duration(milliseconds: 350),
    super.key,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final bool shouldRequestFocus;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final ValueChanged<String>? onSubmitted;
  final Duration autofocusDelay;

  @override
  State<OnboardingAutofocusTextField> createState() =>
      _OnboardingAutofocusTextFieldState();
}

class _OnboardingAutofocusTextFieldState
    extends State<OnboardingAutofocusTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scheduleFocusIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OnboardingAutofocusTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shouldRequestFocus && widget.shouldRequestFocus) {
      _scheduleFocusIfNeeded();
    }
  }

  void _scheduleFocusIfNeeded() {
    if (!widget.shouldRequestFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(widget.autofocusDelay, () {
        if (mounted && widget.shouldRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      onSubmitted: widget.onSubmitted,
      decoration: widget.decoration,
      style: widget.style,
    );
  }
}
