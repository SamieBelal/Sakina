import 'package:freezed_annotation/freezed_annotation.dart';
import 'name_of_allah.dart';
import 'verse.dart';
import 'dua.dart';

part 'feeling_result.freezed.dart';
part 'feeling_result.g.dart';

@freezed
class FeelingResult with _$FeelingResult {
  const factory FeelingResult({
    required String id,
    @JsonKey(name: 'user_input') required String userInput,
    @JsonKey(name: 'name_of_allah') required NameOfAllah nameOfAllah,
    @Default([]) List<Verse> verses,
    Dua? dua,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _FeelingResult;

  factory FeelingResult.fromJson(Map<String, dynamic> json) =>
      _$FeelingResultFromJson(json);
}
