import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class AnalyticsService {
  Mixpanel? _mixpanel;

  Future<void> initialize(String token) async {
    if (token.isEmpty) return;
    _mixpanel = await Mixpanel.init(token, trackAutomaticEvents: false);
  }

  void track(String event, {Map<String, dynamic>? properties}) {
    _mixpanel?.track(event, properties: properties);
  }

  void identify(String userId) {
    _mixpanel?.identify(userId);
  }

  void reset() {
    _mixpanel?.reset();
  }
}
