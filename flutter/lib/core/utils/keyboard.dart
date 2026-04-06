import 'package:flutter/widgets.dart';

/// Dismiss the soft keyboard by unfocusing the current focus node.
void dismissKeyboard(BuildContext context) {
  FocusScope.of(context).unfocus();
}
