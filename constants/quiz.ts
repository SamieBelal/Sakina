/**
 * "Which Names of Allah are your anchors?" quiz
 * 6 scenario-based questions. Each answer scores 1 point toward specific Names.
 * Top 3 scored Names become the user's spiritual anchors.
 */

export interface QuizOption {
  text: string;
  scores: Record<string, number>; // Name key → points
}

export interface QuizQuestion {
  id: string;
  prompt: string;
  options: QuizOption[];
}

export interface AnchorResult {
  nameKey: string;
  name: string;
  arabic: string;
  score: number;
  anchor: string; // One sentence — what this Name means for you
  detail: string; // 2 sentences — how to carry it
}

export const QUIZ_QUESTIONS: QuizQuestion[] = [
  {
    id: 'q1',
    prompt: 'When life feels heavy, what do you find yourself reaching for?',
    options: [
      {
        text: 'A reminder that this pain has a purpose',
        scores: { 'as-sabur': 2, 'al-hakim': 1, 'al-latif': 1 },
      },
      {
        text: 'Someone to hear me — even if I can\'t explain it',
        scores: { 'as-sami': 2, 'al-qarib': 2, 'al-wadud': 1 },
      },
      {
        text: 'The feeling that I\'m not alone in this',
        scores: { 'ar-rahman': 2, 'al-wadud': 2, 'as-salam': 1 },
      },
      {
        text: 'A sense that someone is in control when I\'m not',
        scores: { 'al-wakil': 2, 'ar-rabb': 2, 'al-qayyum': 1 },
      },
    ],
  },
  {
    id: 'q2',
    prompt: 'When you think about your relationship with Allah, what feels most true?',
    options: [
      {
        text: 'I worry I\'ve strayed too far to come back',
        scores: { 'at-tawwab': 2, 'al-ghaffar': 2, 'ar-rahman': 1 },
      },
      {
        text: 'I feel His presence in the small, quiet moments',
        scores: { 'al-latif': 2, 'al-khabir': 1, 'as-sami': 1 },
      },
      {
        text: 'I trust Him even when I don\'t understand His plan',
        scores: { 'al-hakim': 2, 'al-wakil': 2, 'al-ali': 1 },
      },
      {
        text: 'I long for a deeper, more loving connection',
        scores: { 'al-wadud': 2, 'ar-rahim': 2, 'al-qarib': 1 },
      },
    ],
  },
  {
    id: 'q3',
    prompt: 'Which struggle resonates with you most right now?',
    options: [
      {
        text: 'Waiting — for an answer, a change, a sign',
        scores: { 'as-sabur': 2, 'al-mujib': 2, 'al-fattah': 1 },
      },
      {
        text: 'Feeling unseen or misunderstood by others',
        scores: { 'al-basir': 2, 'ash-shahid': 1, 'al-khabir': 1 },
      },
      {
        text: 'Carrying guilt or shame I can\'t seem to shake',
        scores: { 'al-ghaffar': 2, 'al-afuw': 2, 'at-tawwab': 1 },
      },
      {
        text: 'Feeling scattered, lost, or without direction',
        scores: { 'al-hadi': 2, 'an-nur': 2, 'ar-rabb': 1 },
      },
    ],
  },
  {
    id: 'q4',
    prompt: 'A moment of genuine peace for you looks like:',
    options: [
      {
        text: 'Quiet stillness — no noise, no pressure',
        scores: { 'as-salam': 2, 'al-quddus': 1, 'as-samad': 1 },
      },
      {
        text: 'Feeling completely known and still loved',
        scores: { 'al-wadud': 2, 'al-khabir': 1, 'ar-rahim': 1 },
      },
      {
        text: 'Knowing my provision and future are taken care of',
        scores: { 'ar-razzaq': 2, 'al-wakil': 1, 'al-qayyum': 1 },
      },
      {
        text: 'A breakthrough — something finally opening up',
        scores: { 'al-fattah': 2, 'al-latif': 1, 'al-mujib': 1 },
      },
    ],
  },
  {
    id: 'q5',
    prompt: 'When you pray, what are you most often asking for?',
    options: [
      {
        text: 'Healing — for my heart, body, or relationships',
        scores: { 'ash-shafi': 2, 'ar-rahman': 1, 'al-latif': 1 },
      },
      {
        text: 'Strength to keep going when I want to give up',
        scores: { 'al-qawi': 2, 'as-sabur': 1, 'al-matin': 1 },
      },
      {
        text: 'Guidance — to know the right path',
        scores: { 'al-hadi': 2, 'al-hakim': 1, 'an-nur': 1 },
      },
      {
        text: 'Forgiveness — more than anything else',
        scores: { 'al-afuw': 2, 'al-ghaffar': 1, 'at-tawwab': 1 },
      },
    ],
  },
  {
    id: 'q6',
    prompt: 'How do you most naturally connect with Allah?',
    options: [
      {
        text: 'Through difficulty — hardship brings me closer',
        scores: { 'as-sabur': 1, 'al-mujib': 1, 'ar-rabb': 2 },
      },
      {
        text: 'Through beauty — nature, art, the world around me',
        scores: { 'al-latif': 2, 'an-nur': 1, 'al-jamil': 1 },
      },
      {
        text: 'Through gratitude — counting what I have',
        scores: { 'ar-razzaq': 2, 'ash-shakur': 2, 'al-karim': 1 },
      },
      {
        text: 'Through dua — just talking to Him',
        scores: { 'al-qarib': 2, 'as-sami': 1, 'al-mujib': 2 },
      },
    ],
  },
];

// Metadata for each Name key used in the quiz
export const NAME_ANCHORS: Record<string, Omit<AnchorResult, 'score' | 'nameKey'>> = {
  'ar-rahman': {
    name: 'Ar-Rahman',
    arabic: 'الرَّحْمَٰنُ',
    anchor: 'You are held by infinite mercy.',
    detail: 'Ar-Rahman is the name Allah chose for Himself above all others. Return to it whenever you feel unworthy — His mercy is not earned, it simply is.',
  },
  'ar-rahim': {
    name: 'Ar-Rahim',
    arabic: 'الرَّحِيمُ',
    anchor: 'You are intimately, personally loved.',
    detail: 'Where Ar-Rahman is mercy for all creation, Ar-Rahim is the mercy He reserves especially for believers. You are not just tolerated — you are treasured.',
  },
  'al-wadud': {
    name: 'Al-Wadud',
    arabic: 'الْوَدُودُ',
    anchor: 'You are wired for deep, lasting love.',
    detail: 'Al-Wadud means Allah loves with a love that does not waver or cool. The ache for real connection in you is a reflection of how He made you to be loved by Him.',
  },
  'as-sami': {
    name: "As-Sami'",
    arabic: 'السَّمِيعُ',
    anchor: 'Every word you speak to Him lands.',
    detail: "As-Sami' — the All-Hearing — means not a single dua is lost in the air. Even your half-formed prayers, your silent ones, the ones that are just feelings — He hears them all.",
  },
  'al-qarib': {
    name: 'Al-Qarib',
    arabic: 'الْقَرِيبُ',
    anchor: 'He is closer to you than you think.',
    detail: 'Al-Qarib means the Near One. The distance you feel is not real — it is a feeling, not a fact. He is nearer to you than your own jugular vein.',
  },
  'al-mujib': {
    name: 'Al-Mujib',
    arabic: 'الْمُجِيبُ',
    anchor: 'Your duas are being answered.',
    detail: 'Al-Mujib is the Responsive One. Every sincere call is met — sometimes immediately, sometimes in a way you do not yet see. Keep asking.',
  },
  'al-latif': {
    name: 'Al-Latif',
    arabic: 'اللَّطِيفُ',
    anchor: 'He works in the details you cannot see.',
    detail: "Al-Latif is the Subtly Kind — the One who arranges things through small mercies and unseen movements. What looks like coincidence is often Al-Latif's hand.",
  },
  'al-hakim': {
    name: 'Al-Hakim',
    arabic: 'الْحَكِيمُ',
    anchor: 'Nothing in your life is wasted.',
    detail: 'Al-Hakim means every decree has been placed with perfect wisdom. The things that make no sense to you now are woven with a purpose that will one day be clear.',
  },
  'al-wakil': {
    name: 'Al-Wakil',
    arabic: 'الْوَكِيلُ',
    anchor: 'You can let go — He has it.',
    detail: 'Al-Wakil is the Trustee, the One you hand your affairs over to completely. Hasbunallahu wa ni\'mal wakil — Allah is enough for us, and He is the best Disposer of affairs.',
  },
  'as-sabur': {
    name: 'As-Sabur',
    arabic: 'الصَّبُورُ',
    anchor: 'The wait is not a sign that He has forgotten you.',
    detail: 'As-Sabur — the Patient One — never rushes His decree out of frustration. His timing is not delay; it is precision. And He gives you the strength to endure it.',
  },
  'al-fattah': {
    name: 'Al-Fattah',
    arabic: 'الْفَتَّاحُ',
    anchor: 'Doors will open that you cannot open yourself.',
    detail: 'Al-Fattah is the Opener of all things. No door is permanently shut to the one who returns to Him. The breakthrough you are waiting for is in His hands.',
  },
  'al-ghaffar': {
    name: 'Al-Ghaffar',
    arabic: 'الْغَفَّارُ',
    anchor: 'You are not defined by your worst moments.',
    detail: 'Al-Ghaffar means the One who forgives repeatedly, without limit. The same sin brought back with a sincere heart is forgiven again. He does not keep a tally against you.',
  },
  'al-afuw': {
    name: "Al-'Afuw",
    arabic: 'الْعَفُوُّ',
    anchor: "His forgiveness erases — it doesn't just cover.",
    detail: "Al-'Afuw goes further than forgiveness: it means to completely wipe away, as if it never happened. Ask for it often. It is what the Prophet ﷺ taught us to seek on Laylatul Qadr.",
  },
  'at-tawwab': {
    name: 'At-Tawwab',
    arabic: 'التَّوَّابُ',
    anchor: 'The door of return is always open.',
    detail: 'At-Tawwab means Allah turns to His servant the moment the servant turns to Him. You do not have to earn your way back — the turning itself is the beginning.',
  },
  'al-hadi': {
    name: 'Al-Hadi',
    arabic: 'الْهَادِي',
    anchor: 'You will be guided to where you need to be.',
    detail: 'Al-Hadi is the Guide — the One who places clarity in hearts that ask for it. If you feel lost, ask Him directly: "Guide me." He answers that prayer.',
  },
  'an-nur': {
    name: 'An-Nur',
    arabic: 'النُّورُ',
    anchor: 'His light finds you even in the dark.',
    detail: 'An-Nur is the Light of the heavens and the earth. When you feel spiritually dim, it is not permanent — the same source of light that created the stars is available to your heart.',
  },
  'ar-rabb': {
    name: 'Ar-Rabb',
    arabic: 'الرَّبُّ',
    anchor: 'You are being tended to, not just observed.',
    detail: 'Ar-Rabb is the Lord who nurtures, sustains, and tends — like a gardener to a plant. Every hardship in your life has been shaped by One who knows exactly what you need to grow.',
  },
  'al-qayyum': {
    name: 'Al-Qayyum',
    arabic: 'الْقَيُّومُ',
    anchor: 'He is the only constant when everything shifts.',
    detail: 'Al-Qayyum means self-subsisting and sustaining all things. When everything you lean on feels unstable, He is the one ground that cannot give way.',
  },
  'as-salam': {
    name: 'As-Salam',
    arabic: 'السَّلَامُ',
    anchor: 'Peace is a person you can return to.',
    detail: 'As-Salam is not just a greeting — it is a Name. Allah Himself is the source of all peace. The stillness you are searching for lives in closeness to Him.',
  },
  'ar-razzaq': {
    name: 'Ar-Razzaq',
    arabic: 'الرَّزَّاقُ',
    anchor: 'Your provision has already been written.',
    detail: 'Ar-Razzaq — the Provider — has already decreed every provision that will ever reach you. Work, but release the grip of anxiety: what is yours will not pass you by.',
  },
  'ash-shafi': {
    name: 'Ash-Shafi',
    arabic: 'الشَّافِي',
    anchor: 'Healing — of every kind — is in His hands.',
    detail: 'Ash-Shafi is the Healer. No wound is beyond Him — physical, emotional, spiritual. The Prophet ﷺ said: there is no disease He created except He also created its cure.',
  },
  'al-basir': {
    name: 'Al-Basir',
    arabic: 'الْبَصِيرُ',
    anchor: 'He sees everything others overlook in you.',
    detail: 'Al-Basir is the All-Seeing. No effort you make, no hidden sacrifice, no quiet struggle goes unseen by Him. He witnesses what no one else does.',
  },
  'al-khabir': {
    name: 'Al-Khabir',
    arabic: 'الْخَبِيرُ',
    anchor: 'He knows your interior life completely.',
    detail: "Al-Khabir means He is aware of the subtlest movements of your heart — the feelings you can't name, the doubts you're ashamed of. He knows, and He is not alarmed.",
  },
  'al-qawi': {
    name: 'Al-Qawi',
    arabic: 'الْقَوِيُّ',
    anchor: 'His strength is available to you.',
    detail: 'Al-Qawi — the All-Strong — does not deplete. When your strength runs out, you are invited to draw from an inexhaustible source. Ask Him for it.',
  },
  'al-matin': {
    name: 'Al-Matin',
    arabic: 'الْمَتِينُ',
    anchor: 'There is a steadiness beneath your feet.',
    detail: 'Al-Matin is the Firm, the Steadfast. Nothing shakes Him. And those who hold to Him find that same firmness enters their own hearts.',
  },
  'al-karim': {
    name: 'Al-Karim',
    arabic: 'الْكَرِيمُ',
    anchor: 'He gives generously, without you having to deserve it.',
    detail: 'Al-Karim is the Generous One who gives before you even ask, and gives more than you expected. His generosity is not proportional to your worthiness.',
  },
  'ash-shakur': {
    name: 'Ash-Shakur',
    arabic: 'الشَّكُورُ',
    anchor: 'Every act of gratitude multiplies what you have.',
    detail: 'Ash-Shakur means Allah Himself is grateful — He amplifies and rewards the smallest good deeds beyond what they deserve. Gratitude is one of the most powerful postures you can take.',
  },
  'al-quddus': {
    name: 'Al-Quddus',
    arabic: 'الْقُدُّوسُ',
    anchor: 'There is a purity available to your heart.',
    detail: 'Al-Quddus is the Most Holy, free of all imperfection. Connecting to Him is how the heart gets cleansed — not by your effort alone, but by proximity to the One who is pure.',
  },
  'as-samad': {
    name: 'As-Samad',
    arabic: 'الصَّمَدُ',
    anchor: 'He is the only One who can truly fill what is empty.',
    detail: 'As-Samad means the Self-Sufficient Master whom all depend on. Every longing, every unfilled place in you — it points toward the One it was designed for.',
  },
  'al-ali': {
    name: "Al-'Ali",
    arabic: 'الْعَلِيُّ',
    anchor: 'He sees your situation from above — all of it.',
    detail: "Al-'Ali is the Most High. His perspective encompasses what you cannot see from where you stand. Trust that He sees the full picture when you can only see a fragment.",
  },
  'al-jamil': {
    name: 'Al-Jamil',
    arabic: 'الْجَمِيلُ',
    anchor: 'Beauty in this world is a trace of Him.',
    detail: 'Al-Jamil — the Beautiful — loves beauty. The moments of beauty that stop you in your tracks are whispers from the One whose beauty is infinite. Let them draw you to Him.',
  },
};
