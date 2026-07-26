import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/providers/companion_inputs_provider.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_share_card.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/noor_balance_chip.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/cosmetics_service.dart';

/// The Companion "stage": the equipped backdrop + the live equipped-skin
/// medallion as the hero, a Noor chip, and entry to the wardrobe + share.
/// Reached by tapping the Home medallion (`/companion`).
class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CosmeticsAnalytics.emit(AnalyticsEvents.companionScreenOpened, const {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final companion = ref.watch(companionStateProvider);
    final asyncState = ref.watch(cosmeticsStateProvider);

    return Scaffold(
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Could not load your companion')),
        data: (cs) => _buildStage(context, cs, companion),
      ),
    );
  }

  /// DEP-D2 (premium lapse): the equipped id is only RENDERED when it is owned.
  /// A premium-exclusive skin that was equipped while premium was active is not
  /// owned, so once premium lapses the stage falls back to the always-owned
  /// classic gold. The server slot is left untouched — that is a sync concern.
  String _renderableSkinId(CosmeticsState cs) =>
      cs.owns(itemTypeLanternSkin, cs.equippedLanternSkin)
          ? cs.equippedLanternSkin
          : defaultLanternSkin;

  Widget _buildStage(
      BuildContext context, CosmeticsState cs, CompanionState? companion) {
    final skin = resolveSkin(_renderableSkinId(cs));
    final backdrop = resolveBackdrop(cs.equippedBackdrop);
    final state = companion ??
        const CompanionState(
            brightness: CompanionBrightness.glowing, protected: false);

    return CompanionStage(
      backdrop: backdrop,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(context, cs),
            const Spacer(),
            SizedBox(
              width: 220,
              height: 220,
              child: CompanionMedallion(state: state, size: 220, skin: skin),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your lantern',
              style: AppTypography.headlineMedium
                  .copyWith(color: AppColors.sacredInk),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => context.push('/wardrobe'),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Customize'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sacredInk,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, CosmeticsState cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: AppColors.sacredInk),
          ),
          const Spacer(),
          NoorBalanceChip(balance: cs.noorBalance, onCanvas: true),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () => shareLanternCard(
              context: context,
              skinId: _renderableSkinId(cs),
              backdropId: cs.equippedBackdrop,
              lanternName: 'Your lantern',
            ),
            icon: const Icon(Icons.share_rounded, color: AppColors.sacredInk),
          ),
        ],
      ),
    );
  }
}
