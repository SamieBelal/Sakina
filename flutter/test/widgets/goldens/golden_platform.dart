import 'dart:io';

/// True when the golden suites must be skipped: they only mean something on
/// the platform their reference PNGs were rendered on.
///
/// A golden is a byte-for-byte bitmap comparison, so it is only meaningful on
/// the platform its reference PNG was rendered on. macOS and Linux rasterise
/// text and antialias curves through different engines, so the SAME correct
/// painter produces different bytes on each. The references in
/// `test/widgets/goldens/**` are macOS-authored; CI runs Linux, where all 13
/// compared 97–100% different — not because the artwork regressed, but because
/// the question "do these bytes match?" has no cross-platform answer.
///
/// Skipping off-platform rather than DELETING is deliberate. These suites guard
/// the lantern skins, the backdrop scenes, and their composition — the artwork
/// this feature exists to ship, and the only automated check that would catch
/// someone silently altering a metal ramp or knocking the lantern off its
/// anchor. Deleting them to make CI green would trade real coverage for a
/// checkmark. Gated, they still run for every developer on macOS, which is
/// where the art is actually authored and reviewed.
///
/// The cost is honest and worth stating: these do not protect the Linux CI
/// lane. Closing that needs Linux-rendered references generated in the same
/// container CI uses (`--update-goldens` inside the runner image), committed
/// alongside the macOS set. That is the proper fix; this is the correct
/// behaviour until someone does it.
/// `testWidgets` takes `skip: bool?` — it has no string-reason form, so the
/// rationale lives in this doc rather than in the test runner's output.
final bool skipGoldensOffPlatform = !Platform.isMacOS;
