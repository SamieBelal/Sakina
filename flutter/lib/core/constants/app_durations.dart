/// Shared motion / timing constants.
library;

/// How long a transient confirmation snackbar stays on screen.
///
/// Flutter's built-in default is 4000 ms (`_snackBarDisplayDuration` in
/// `material/snack_bar.dart`), which reads as sluggish for the one-word
/// confirmations this app shows — "Equipped", "Copied", "Saved". There is no
/// theme hook for it: `SnackBarThemeData` carries 15 properties and duration is
/// not among them, so the only way to change it globally is to pass `duration`
/// at every call site. Hence this constant — every `SnackBar` in `lib/` takes
/// it, so the value is tuned in ONE place instead of drifting back to 4 s each
/// time someone adds a snackbar.
///
/// 1800 ms is not arbitrary: it is what the two call sites whose authors
/// actually tuned the value independently converged on (`related_dua_heart.dart`
/// at 1800 ms, `my_referrals_screen.dart` at 2000 ms), while the other 32
/// inherited 4 s purely by omission.
///
/// Applied to ALL 32 previously-untuned snackbars, including error messages.
/// That is the deliberate call, but it is the part most worth revisiting: a
/// confirmation only needs to be glimpsed, whereas an error the user has to read
/// and act on may warrant longer. The three call sites that already passed an
/// explicit duration keep their own values and are untouched. Any snackbar that
/// later carries a `SnackBarAction` should pass a longer duration explicitly —
/// 1800 ms is not enough time to notice a button, let alone press it.
const Duration kSnackBarDuration = Duration(milliseconds: 1800);
