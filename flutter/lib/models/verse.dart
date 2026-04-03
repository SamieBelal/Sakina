import 'package:freezed_annotation/freezed_annotation.dart';

part 'verse.freezed.dart';
part 'verse.g.dart';

@freezed
class Verse with _$Verse {
  const factory Verse({
    required String id,
    @JsonKey(name: 'text_arabic') required String textArabic,
    @JsonKey(name: 'text_english') required String textEnglish,
    @JsonKey(name: 'surah_name') required String surahName,
    @JsonKey(name: 'surah_number') required int surahNumber,
    @JsonKey(name: 'ayah_number') required int ayahNumber,
  }) = _Verse;

  factory Verse.fromJson(Map<String, dynamic> json) => _$VerseFromJson(json);
}
