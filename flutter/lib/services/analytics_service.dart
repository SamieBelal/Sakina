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

  void timeEvent(String event) {
    _mixpanel?.timeEvent(event);
  }

  void identify(String userId) {
    _mixpanel?.identify(userId);
  }

  void reset() {
    _mixpanel?.reset();
  }

  void setSuperProperties(Map<String, dynamic> props) {
    _mixpanel?.registerSuperProperties(props);
  }

  void setSuperPropertiesOnce(Map<String, dynamic> props) {
    _mixpanel?.registerSuperPropertiesOnce(props);
  }

  void setUserProperties(Map<String, dynamic> props) {
    final people = _mixpanel?.getPeople();
    if (people == null) return;
    props.forEach(people.set);
  }

  void setUserPropertyOnce(String key, dynamic value) {
    _mixpanel?.getPeople().setOnce(key, value);
  }

  void flush() {
    _mixpanel?.flush();
  }
}
