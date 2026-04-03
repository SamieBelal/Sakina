import 'package:freezed_annotation/freezed_annotation.dart';

part 'name_of_allah.freezed.dart';
part 'name_of_allah.g.dart';

@freezed
class NameOfAllah with _$NameOfAllah {
  const factory NameOfAllah({
    required String id,
    @JsonKey(name: 'name_arabic') required String nameArabic,
    @JsonKey(name: 'name_transliteration') required String nameTransliteration,
    @JsonKey(name: 'name_english') required String nameEnglish,
    required String description,
    @Default([]) List<String> emotions,
  }) = _NameOfAllah;

  factory NameOfAllah.fromJson(Map<String, dynamic> json) =>
      _$NameOfAllahFromJson(json);
}
