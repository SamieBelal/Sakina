export interface AllahName {
  id: number;
  arabic: string;
  transliteration: string;
  english: string;
  meaning: string;
  lesson: string;
}

export const ALLAH_NAMES: AllahName[] = [
  {
    id: 1,
    arabic: 'الرَّحْمَنُ',
    transliteration: 'Ar-Rahman',
    english: 'The Most Gracious',
    meaning: 'The One whose mercy encompasses all creation without condition.',
    lesson: 'His mercy precedes His wrath. Every moment you breathe is a gift from Ar-Rahman.',
  },
  {
    id: 2,
    arabic: 'الرَّحِيمُ',
    transliteration: 'Ar-Raheem',
    english: 'The Most Merciful',
    meaning: 'The One whose special mercy is reserved for the believers.',
    lesson: 'Even when you feel distant, Ar-Raheem is drawing you back with mercy.',
  },
  {
    id: 3,
    arabic: 'الْمَلِكُ',
    transliteration: 'Al-Malik',
    english: 'The King',
    meaning: 'The absolute sovereign who owns and governs all existence.',
    lesson: 'When the world\'s kings fail you, Al-Malik never abandons His servants.',
  },
  {
    id: 4,
    arabic: 'الْقُدُّوسُ',
    transliteration: 'Al-Quddus',
    english: 'The Most Holy',
    meaning: 'The One free from all imperfection, deficiency, and fault.',
    lesson: 'In a world full of imperfection, Al-Quddus is your anchor of purity.',
  },
  {
    id: 5,
    arabic: 'السَّلَامُ',
    transliteration: 'As-Salam',
    english: 'The Source of Peace',
    meaning: 'The One from whom all peace flows and in whom all peace rests.',
    lesson: 'True peace is not the absence of struggle — it is As-Salam dwelling in your heart.',
  },
  {
    id: 6,
    arabic: 'الْمُؤْمِنُ',
    transliteration: 'Al-Mumin',
    english: 'The Guardian of Faith',
    meaning: 'The One who grants safety and confirms the faith of His servants.',
    lesson: 'Al-Mumin sees your sincerity even when others doubt you.',
  },
  {
    id: 7,
    arabic: 'الْعَزِيزُ',
    transliteration: 'Al-Azeez',
    english: 'The Almighty',
    meaning: 'The One of perfect might and honor who is never overcome.',
    lesson: 'Lean on Al-Azeez. You are not weak when you call upon Him.',
  },
  {
    id: 8,
    arabic: 'الْغَفَّارُ',
    transliteration: 'Al-Ghaffar',
    english: 'The Ever-Forgiving',
    meaning: 'The One who forgives sins repeatedly and covers faults completely.',
    lesson: 'Al-Ghaffar\'s door never closes. Return as many times as you fall.',
  },
  {
    id: 9,
    arabic: 'الرَّزَّاقُ',
    transliteration: 'Ar-Razzaq',
    english: 'The Provider',
    meaning: 'The One who provides all sustenance, seen and unseen.',
    lesson: 'Worry less. Ar-Razzaq has written your provision before you were born.',
  },
  {
    id: 10,
    arabic: 'اللَّطِيفُ',
    transliteration: 'Al-Lateef',
    english: 'The Subtle',
    meaning: 'The One who is aware of the finest details and acts with gentleness.',
    lesson: 'Al-Lateef works in ways you cannot see, arranging what you cannot plan.',
  },
  {
    id: 11,
    arabic: 'الشَّكُورُ',
    transliteration: 'Ash-Shakur',
    english: 'The Most Appreciative',
    meaning: 'The One who rewards abundantly for the smallest good deed.',
    lesson: 'Even your private acts of goodness are seen and multiplied by Ash-Shakur.',
  },
  {
    id: 12,
    arabic: 'الْحَلِيمُ',
    transliteration: 'Al-Haleem',
    english: 'The Forbearing',
    meaning: 'The One who withholds punishment despite having full power to act.',
    lesson: 'That you are still here, still trying — this is Al-Haleem\'s patience with you.',
  },
  {
    id: 13,
    arabic: 'الْوَدُودُ',
    transliteration: 'Al-Wadud',
    english: 'The Most Loving',
    meaning: 'The One whose love for His servants is unconditional and constant.',
    lesson: 'Al-Wadud loves you not for your perfection but for your turning toward Him.',
  },
  {
    id: 14,
    arabic: 'الصَّبُورُ',
    transliteration: 'As-Sabur',
    english: 'The Patient',
    meaning: 'The One who is patient with the disobedience of His creation.',
    lesson: 'As-Sabur does not rush you. He waits for you with open arms.',
  },
  {
    id: 15,
    arabic: 'الْحَفِيظُ',
    transliteration: 'Al-Hafeez',
    english: 'The Preserver',
    meaning: 'The One who guards and protects all things in His care.',
    lesson: 'Everything you love is in the hands of Al-Hafeez — even when you cannot hold it.',
  },
];

export function getTodaysName(): AllahName {
  const dayOfYear = Math.floor(
    (Date.now() - new Date(new Date().getFullYear(), 0, 0).getTime()) / 86400000
  );
  return ALLAH_NAMES[dayOfYear % ALLAH_NAMES.length];
}
