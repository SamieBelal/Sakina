import 'package:freezed_annotation/freezed_annotation.dart';

part 'dua.freezed.dart';
part 'dua.g.dart';

@freezed
class Dua with _$Dua {
  const factory Dua({
    required String id,
    @JsonKey(name: 'text_arabic') required String textArabic,
    @JsonKey(name: 'text_english') required String textEnglish,
    @JsonKey(name: 'text_transliteration') required String textTransliteration,
    required String source,
  }) = _Dua;

  factory Dua.fromJson(Map<String, dynamic> json) => _$DuaFromJson(json);
}
