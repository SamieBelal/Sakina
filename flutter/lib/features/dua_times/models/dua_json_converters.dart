import 'package:freezed_annotation/freezed_annotation.dart';

/// Serializes a UTC [DateTime] as **epoch milliseconds** (an `int`) in JSON.
///
/// The duʿā-times schedule crosses the App Group boundary to a Swift widget
/// extension (spec §7). Epoch-millis is the least-ambiguous instant encoding for
/// the Swift decoder — `Date(timeIntervalSince1970: millis / 1000)` — avoiding
/// ISO-8601 timezone-suffix parsing quirks. Always emitted/parsed as UTC.
class EpochMillisConverter implements JsonConverter<DateTime, int> {
  const EpochMillisConverter();

  @override
  DateTime fromJson(int json) =>
      DateTime.fromMillisecondsSinceEpoch(json, isUtc: true);

  @override
  int toJson(DateTime object) => object.toUtc().millisecondsSinceEpoch;
}

/// Nullable variant of [EpochMillisConverter]: serializes a nullable UTC
/// [DateTime] as **epoch milliseconds** (`int?`), emitting/parsing `null` when
/// the instant is unknown. Used for optional provenance fields (e.g. the
/// build-instant staleness stamp) that must stay absent/null rather than
/// defaulting to a bogus epoch.
class NullableEpochMillisConverter implements JsonConverter<DateTime?, int?> {
  const NullableEpochMillisConverter();

  @override
  DateTime? fromJson(int? json) => json == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(json, isUtc: true);

  @override
  int? toJson(DateTime? object) => object?.toUtc().millisecondsSinceEpoch;
}
