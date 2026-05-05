import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The Name surfaced on the first check-in screen. Becomes the user's
/// permanent "starting Name" — persisted as `user_profiles.starter_name_id`
/// and seeded into `user_card_collection` at onboarding completion.
///
/// `catalogId` references `collectible_names(id)` (see
/// `lib/services/card_collection_service.dart` for the canonical list).
class StarterNameData {
  const StarterNameData({
    required this.catalogId,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameTransliteration,
    required this.verseArabic,
    required this.verseTranslation,
    required this.verseReference,
  });

  final int catalogId;
  final String nameArabic;
  final String nameEnglish;
  final String nameTransliteration;
  final String verseArabic;
  final String verseTranslation;
  final String verseReference;

  static const asSalam = StarterNameData(
    catalogId: 6,
    nameArabic: 'السلام',
    nameEnglish: 'The Source of Peace',
    nameTransliteration: 'As-Salam',
    verseArabic:
        'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    verseTranslation:
        'Verily, in the remembrance of Allah do hearts find rest.',
    verseReference: 'Ar-Ra\'d 13:28',
  );

  static const alJabbar = StarterNameData(
    catalogId: 9,
    nameArabic: 'الجبّار',
    nameEnglish: 'The Restorer',
    nameTransliteration: 'Al-Jabbar',
    verseArabic:
        'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ‎﴿٥﴾‏ إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    verseTranslation:
        'For indeed, with hardship comes ease. Indeed, with hardship comes ease.',
    verseReference: 'Ash-Sharh 94:5-6',
  );

  static const ashShakur = StarterNameData(
    catalogId: 28,
    nameArabic: 'الشكور',
    nameEnglish: 'The Most Appreciative',
    nameTransliteration: 'Ash-Shakur',
    verseArabic:
        'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ',
    verseTranslation:
        'If you are grateful, I will surely increase you in favor.',
    verseReference: 'Ibrahim 14:7',
  );

  static const asSabur = StarterNameData(
    catalogId: 32,
    nameArabic: 'الصبور',
    nameEnglish: 'The Most Patient',
    nameTransliteration: 'As-Sabur',
    verseArabic:
        'وَالْكَاظِمِينَ الْغَيْظَ وَالْعَافِينَ عَنِ النَّاسِ',
    verseTranslation:
        'Those who restrain anger and pardon the people — and Allah loves the doers of good.',
    verseReference: 'Al-Imran 3:134',
  );

  static const alHadi = StarterNameData(
    catalogId: 33,
    nameArabic: 'الهادي',
    nameEnglish: 'The Guide',
    nameTransliteration: 'Al-Hadi',
    verseArabic:
        'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
    verseTranslation:
        'Allah does not burden a soul beyond that it can bear.',
    verseReference: 'Al-Baqarah 2:286',
  );

  static const alWakeel = StarterNameData(
    catalogId: 35,
    nameArabic: 'الوكيل',
    nameEnglish: 'The Trustee',
    nameTransliteration: 'Al-Wakeel',
    verseArabic:
        'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
    verseTranslation:
        'And whoever relies upon Allah — then He is sufficient for him.',
    verseReference: 'At-Talaq 65:3',
  );

  static const arRahman = StarterNameData(
    catalogId: 2,
    nameArabic: 'الرحمن',
    nameEnglish: 'The Most Merciful',
    nameTransliteration: 'Ar-Rahman',
    verseArabic:
        'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
    verseTranslation:
        'So which of the favors of your Lord would you deny?',
    verseReference: 'Ar-Rahman 55:13',
  );

  /// All starter Names — used for catalog-id sanity tests.
  static const all = <StarterNameData>[
    asSalam,
    alJabbar,
    ashShakur,
    asSabur,
    alHadi,
    alWakeel,
    arRahman,
  ];

  /// Maps free-text or chip emotion input to a starter Name. Each branch is
  /// generous with synonyms so most natural inputs land on a non-default
  /// Name; truly unmatched input falls through to Ar-Rahman (warmth/mercy)
  /// as the universal default.
  static StarterNameData forEmotion(String emotion) {
    final lower = emotion.toLowerCase();
    bool any(List<String> words) => words.any(lower.contains);

    if (any(const [
      'anxious', 'anxiety', 'overwhelm', 'panic',
      'worried', 'worry', 'scared', 'fear', 'afraid', 'restless', 'nervous',
    ])) {
      return asSalam;
    }
    if (any(const [
      'sad', 'sadness', 'grief', 'grieving', 'depressed',
      'down', 'low', 'hurt', 'broken', 'heartbroken', 'crying',
    ])) {
      return alJabbar;
    }
    if (any(const [
      'grateful', 'gratitude', 'thankful', 'blessed', 'content',
    ])) {
      return ashShakur;
    }
    if (any(const [
      'angry', 'anger', 'frustrated', 'frustration', 'irritated',
      'annoyed', 'mad', 'furious', 'rage',
    ])) {
      return asSabur;
    }
    if (any(const [
      'lost', 'lonely', 'loneliness', 'alone', 'isolated',
      'disconnected', 'confused', 'directionless',
    ])) {
      return alHadi;
    }
    if (any(const [
      'hopeful', 'hope', 'optimistic', 'looking forward',
    ])) {
      return alWakeel;
    }
    return arRahman;
  }
}

class DemoResultCard extends StatelessWidget {
  const DemoResultCard({
    required this.data,
    super.key,
  });

  final StarterNameData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name of Allah
          Text(
            data.nameArabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              color: AppColors.secondary,
              fontSize: 40,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                ),
              ],
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.nameTransliteration,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          Text(
            data.nameEnglish,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Divider
          Container(
            height: 1,
            color: AppColors.dividerLight,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Verse
          Text(
            data.verseArabic,
            style: AppTypography.quranArabic.copyWith(
              color: AppColors.textPrimaryLight,
              fontSize: 22,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                ),
              ],
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.verseTranslation,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.verseReference,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
