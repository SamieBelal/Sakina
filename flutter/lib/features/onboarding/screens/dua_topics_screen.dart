import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';
import '../widgets/struggle_chip.dart';

class DuaTopicsScreen extends ConsumerStatefulWidget {
  const DuaTopicsScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<DuaTopicsScreen> createState() => _DuaTopicsScreenState();
}

class _DuaTopicsScreenState extends ConsumerState<DuaTopicsScreen> {
  static const _topics = <(String, String)>[
    ('health', 'Health'),
    ('family', 'Family'),
    ('forgiveness', 'Forgiveness'),
    ('guidance', 'Guidance'),
    ('peace', 'Peace'),
    ('success', 'Success'),
    ('provision', 'Provision'),
  ];

  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(
      text: ref.read(onboardingProvider).duaTopicsOther ?? '',
    );
    _otherController.addListener(_onOtherChanged);
  }

  void _onOtherChanged() {
    // Rebuild so continueEnabled reflects free-text presence.
    setState(() {});
  }

  @override
  void dispose() {
    _otherController.removeListener(_onOtherChanged);
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final hasFreeText = _otherController.text.trim().isNotEmpty;
    final canContinue = state.duaTopics.isNotEmpty || hasFreeText;

    return OnboardingQuestionScaffold(
      progressSegment: 10,
      headline: 'What would you most want to dua for?',
      subtitle: 'Pick as many as feel true.',
      onBack: widget.onBack,
      continueEnabled: canContinue,
      onContinue: () {
        ref
            .read(onboardingProvider.notifier)
            .setDuaTopicsOther(_otherController.text);
        widget.onNext();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _topics
                .map(
                  (t) => StruggleChip(
                    label: t.$2,
                    isSelected: state.duaTopics.contains(t.$1),
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleDuaTopic(t.$1),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _otherController,
            maxLength: 280,
            decoration: const InputDecoration(
              labelText: 'Anything else? (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
