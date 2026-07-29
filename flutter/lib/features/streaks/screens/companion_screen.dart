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
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_name_sheet.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_share_card.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/noor_balance_chip.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/first_visit_hint_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/widgets/first_visit_hint/first_visit_hint_banner.dart';

/// The Companion "stage": the equipped backdrop + the live equipped-skin
/// medallion as the hero, a Noor chip, and entry to the wardrobe + share.
/// Reached by tapping the Home medallion (`/companion`).
class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  /// E3 — client-only today (OQ-D2). Falls back to [defaultLanternName] while
  /// loading and whenever the pref store is unavailable.
  String _lanternName = defaultLanternName;

  /// Premium, resolved ONCE per screen open (never per build — an async read in
  /// a build would refire forever). Feeds [renderableSkinId]: a premium-
  /// exclusive skin is equippable-not-owned, so ownership alone cannot decide
  /// what to draw.
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadLanternName();
    _resolvePremium();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CosmeticsAnalytics.emit(AnalyticsEvents.companionScreenOpened, const {});
    });
  }

  Future<void> _resolvePremium() async {
    var premium = false;
    try {
      premium = await PurchaseService().isPremium();
    } catch (_) {
      // Unresolvable premium reads as NOT premium — the conservative default
      // (it can only cost an active subscriber one frame of classic gold).
    }
    if (mounted) setState(() => _isPremium = premium);
  }

  Future<void> _loadLanternName() async {
    final saved = await readLanternName();
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _lanternName = saved);
    }
  }

  Future<void> _rename() async {
    final saved = await showLanternNameSheet(
      context,
      current: _lanternName == defaultLanternName ? null : _lanternName,
    );
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _lanternName = saved);
    }
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

  /// The skin the stage actually draws: owned, or premium-exclusive while
  /// premium is active. See [renderableSkinId] — shared with the wardrobe so
  /// the two stages can never disagree.
  String _renderableSkinId(CosmeticsState cs) =>
      renderableSkinId(cs, isPremium: _isPremium);

  Widget _buildStage(
      BuildContext context, CosmeticsState cs, CompanionState? companion) {
    final skin = resolveSkin(_renderableSkinId(cs));
    final backdrop = resolveBackdrop(cs.equippedBackdrop);
    final state = companion ??
        const CompanionState(
            brightness: CompanionBrightness.glowing, protected: false);

    // The chrome inverts with the backdrop: cream ink reads on the emerald and
    // night scenes but vanishes on the plain cream surface (and vice versa).
    final onCanvas = !backdrop.isLightSurface;

    return CompanionStage(
      backdrop: backdrop,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(context, cs, onCanvas),
            const Spacer(),
            SizedBox(
              width: 220,
              height: 220,
              child: CompanionMedallion(state: state, size: 220, skin: skin),
            ),
            const SizedBox(height: AppSpacing.md),
            _lanternNameLabel(onCanvas),
            // First-visit hint (F3): the stage is reached by tapping the Home
            // medallion — an unguessable gesture — and the lamp's brightness
            // has no on-screen explanation. Sits under the lantern it
            // describes; blocks nothing, and Customize stays live behind it.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: FirstVisitHintBanner(
                hint: FirstVisitHintId.companion,
                padding: EdgeInsets.only(top: AppSpacing.md),
              ),
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
                    // A cream fill disappears on the cream surface, so invert
                    // to the emerald fill there.
                    backgroundColor:
                        onCanvas ? AppColors.sacredInk : AppColors.primary,
                    foregroundColor:
                        onCanvas ? AppColors.primary : AppColors.sacredInk,
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

  /// The lantern's name, tappable to rename (E3).
  ///
  /// The name itself IS the affordance — the explicit pencil glyph was removed
  /// because it broke the stillness of the scene. Renaming is unchanged: the
  /// InkWell has always wrapped the whole label (the icon was decoration, never
  /// the button).
  ///
  /// The 44×44 minimum is enforced explicitly rather than left to the text's
  /// intrinsic size. `headlineMedium` is 20px on a 1.3 line box = 26pt, and the
  /// old `AppSpacing.xs` padding brought that to only 34pt tall — under the
  /// minimum both before and after the glyph was dropped (the 18pt icon sat
  /// BESIDE the text and never drove the row's height, so removing it cost
  /// width, not height). Width was never at risk: names cap at 20 characters
  /// (`lantern_name_sheet.dart`), but a 1–2 character name would shrink-wrap
  /// below 44pt too, so the minimum is applied on both axes.
  Widget _lanternNameLabel(bool onCanvas) {
    return InkWell(
      onTap: _rename,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              _lanternName,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headlineMedium.copyWith(
                  color: onCanvas
                      ? AppColors.sacredInk
                      : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, CosmeticsState cs, bool onCanvas) {
    final ink = onCanvas ? AppColors.sacredInk : AppColors.textPrimaryLight;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.close_rounded, color: ink),
          ),
          const Spacer(),
          NoorBalanceChip(balance: cs.noorBalance, onCanvas: onCanvas),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () => shareLanternCard(
              context: context,
              skinId: _renderableSkinId(cs),
              backdropId: cs.equippedBackdrop,
              lanternName: _lanternName,
              streak: ref.read(companionStreakProvider),
            ),
            icon: Icon(Icons.share_rounded, color: ink),
          ),
        ],
      ),
    );
  }
}
