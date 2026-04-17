import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_autofocus_text_field.dart';
import '../widgets/onboarding_question_scaffold.dart';

class NameInputScreen extends ConsumerStatefulWidget {
  const NameInputScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends ConsumerState<NameInputScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(onboardingProvider).signUpName ?? '',
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _controller.text.trim();
    return OnboardingQuestionScaffold(
      progressSegment: 3,
      headline: 'What should we call you?',
      subtitle: 'Just your first name.',
      onBack: widget.onBack,
      continueEnabled: name.isNotEmpty,
      onContinue: () {
        ref.read(onboardingProvider.notifier).setSignUpName(name);
        widget.onNext();
      },
      body: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: OnboardingAutofocusTextField(
          controller: _controller,
          shouldRequestFocus: true,
          decoration: const InputDecoration(
            hintText: 'Your first name',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (name.isNotEmpty) {
              ref.read(onboardingProvider.notifier).setSignUpName(name);
              widget.onNext();
            }
          },
        ),
      ),
    );
  }
}
