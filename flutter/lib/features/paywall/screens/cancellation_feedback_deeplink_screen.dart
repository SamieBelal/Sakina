import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/features/paywall/cancellation_feedback_presenter.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/cancellation_feedback_provider.dart';
import 'package:sakina/services/cancellation_feedback_service.dart';
import 'package:sakina/widgets/sakina_loader.dart';

/// Landing screen for the `sakina://cancellation-feedback` push deep-link
/// (route `/cancellation-feedback`). A push tap is explicit intent, so unlike
/// the home-screen path this presents the survey directly — no calm-moment
/// gate — then returns home. Still deduped: if the episode was already
/// surveyed (or there's nothing to survey), it just goes home.
class CancellationFeedbackDeepLinkScreen extends ConsumerStatefulWidget {
  const CancellationFeedbackDeepLinkScreen({super.key});

  @override
  ConsumerState<CancellationFeedbackDeepLinkScreen> createState() =>
      _CancellationFeedbackDeepLinkScreenState();
}

class _CancellationFeedbackDeepLinkScreenState
    extends ConsumerState<CancellationFeedbackDeepLinkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final service = ref.read(cancellationFeedbackServiceProvider);
    final reactive = await service.resolveReactiveCancellation();

    if (mounted && reactive != null) {
      // Re-tag the source as push (resolveReactiveCancellation defaults to
      // in_app_reactive); the episode/dedupe key and all other fields are
      // preserved by copyWith.
      await presentCancellationFeedback(
        context,
        cancellation: reactive.copyWith(source: CancellationSource.push),
        service: service,
        analytics: ref.read(analyticsProvider),
      );
    }

    if (!mounted) return;
    // Return whence we came. The deep-link route is PUSHED over the current
    // stack (see NotificationService._defaultRouteNavigator), so pop() reveals
    // the live screen underneath WITHOUT rebuilding the root Navigator. Using
    // go('/') here raced the entry navigation and transiently double-mounted the
    // root Navigator (duplicate GlobalObjectKey → "Multiple widgets used the
    // same GlobalKey" crash / blank screen), especially in the no-survey fast
    // path where this fires immediately after entry.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(child: SakinaLoader()),
    );
  }
}
