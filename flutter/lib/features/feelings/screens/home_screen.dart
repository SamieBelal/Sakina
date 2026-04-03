import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                AppStrings.howAreYouFeeling,
                style: AppTypography.displayMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.typeYourFeeling,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Submit feeling to AI service
                  },
                  child: const Text('Reflect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
