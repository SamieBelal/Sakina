/// Shared motion / timing constants.
library;

/// How long a transient confirmation snackbar stays on screen.
///
/// Flutter's built-in default is 4000 ms (`_snackBarDisplayDuration` in
/// `material/snack_bar.dart`), which reads as sluggish for the one-word
/// confirmations this app shows — "Equipped", "Copied", "Saved". There is no
/// theme hook for it: `SnackBarThemeData` carries 15 properties and duration is
/// not among them, so the only way to change it globally is to pass `duration`
/// at every call site. Hence this constant, so the value is tuned in ONE place
/// instead of drifting back to 4 s each time someone adds a snackbar.
///
/// 1800 ms is not arbitrary: it is what the two call sites whose authors
/// actually tuned the value independently converged on (`related_dua_heart.dart`
/// at 1800 ms, `my_referrals_screen.dart` at 2000 ms), while the other 32
/// inherited 4 s purely by omission.
///
/// Applies to CONFIRMATIONS — 26 of the app's 35 snackbars. Errors take
/// [kSnackBarErrorDuration] instead, and three call sites that already passed
/// their own explicit duration are untouched.
///
/// Any snackbar that later carries a `SnackBarAction` should pass a longer
/// duration explicitly — 1800 ms is not enough time to notice a button, let
/// alone press it.
const Duration kSnackBarDuration = Duration(milliseconds: 1800);

/// How long an ERROR snackbar stays on screen.
///
/// A confirmation only has to be glimpsed — the user already knows what they
/// did, and "Equipped" merely acknowledges it. An error is different: it is
/// often the ONLY explanation of something that just went wrong, it may carry
/// an instruction the user has to act on, and they were not expecting to read
/// anything at all. At a normal on-screen ~200 wpm, and allowing ~0.5 s to
/// notice the snackbar and saccade to it, the app's longest error messages need
/// ~4 s. Concretely, at 1800 ms these were being cut off mid-sentence:
///
///   * `collection_screen.dart` — "Couldn't upgrade and your N scrolls couldn't
///     be refunded. Please contact support." This is the money-loss branch (the
///     code beside it logs `CRITICAL: refund failed ... User lost N scrolls`).
///     It is the ONLY surface that tells a user their currency is gone and that
///     they must contact support; nothing repeats it.
///   * `settings_premium_card.dart` — "Could not open subscription management.
///     Open the App Store directly to manage your subscription." The second
///     clause is the entire point, and it was the half that got cut.
///   * `settings_screen.dart` — "Notifications are blocked in your device
///     settings. Enable them there to turn this on." Fires as the toggle snaps
///     back to OFF; it is the only thing explaining the snap-back.
///
/// Also used where the text is structurally UNBOUNDED, so no length assumption
/// is possible: `provider_error_listener` (`Text(err)`, an arbitrary provider
/// error), `sign_up_password_screen` (a raw GoTrue `AuthException.message`), and
/// `store_screen` (a caller-supplied message).
///
/// Accessibility: this Flutter version has no accessible-navigation exemption
/// from the dismiss timer — it was replaced by `SnackBar.persist`, which nothing
/// here sets — so a screen-reader user gets exactly this long to HEAR the
/// message announced. That alone rules out 1800 ms for a 14-word instruction.
const Duration kSnackBarErrorDuration = Duration(seconds: 4);
