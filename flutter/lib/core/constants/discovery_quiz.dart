/// "Which Names of Allah are your anchors?" quiz
/// 6 scenario-based questions. Each answer scores 1 point toward specific Names.
/// Top 3 scored Names become the user's spiritual anchors.
library;

class QuizOption {
  final String text;
  final Map<String, int> scores; // Name key -> points

  const QuizOption({
    required this.text,
    required this.scores,
  });
}

class QuizQuestion {
  final String id;
  final String prompt;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });
}

class AnchorResult {
  final String nameKey;
  final String name;
  final String arabic;
  final int score;
  final String anchor; // One sentence - what this Name means for you
  final String detail; // 2 sentences - how to carry it

  const AnchorResult({
    required this.nameKey,
    required this.name,
    required this.arabic,
    required this.score,
    required this.anchor,
    required this.detail,
  });
}

class NameAnchorInfo {
  final String name;
  final String arabic;
  final String anchor;
  final String detail;

  const NameAnchorInfo({
    required this.name,
    required this.arabic,
    required this.anchor,
    required this.detail,
  });
}

const List<QuizQuestion> discoveryQuizQuestions = [
  QuizQuestion(
    id: 'q1',
    prompt: 'When life feels heavy, what do you find yourself reaching for?',
    options: [
      QuizOption(
        text: 'A reminder that this pain has a purpose',
        scores: {'as-sabur': 2, 'al-hakim': 1, 'al-latif': 1},
      ),
      QuizOption(
        text: "Someone to hear me \u2014 even if I can't explain it",
        scores: {'as-sami': 2, 'al-qarib': 2, 'al-wadud': 1},
      ),
      QuizOption(
        text: "The feeling that I'm not alone in this",
        scores: {'ar-rahman': 2, 'al-wadud': 2, 'as-salam': 1},
      ),
      QuizOption(
        text: "A sense that someone is in control when I'm not",
        scores: {'al-wakil': 2, 'ar-rabb': 2, 'al-qayyum': 1},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q2',
    prompt:
        'When you think about your relationship with Allah, what feels most true?',
    options: [
      QuizOption(
        text: "I worry I've strayed too far to come back",
        scores: {'at-tawwab': 2, 'al-ghaffar': 2, 'ar-rahman': 1},
      ),
      QuizOption(
        text: 'I feel His presence in the small, quiet moments',
        scores: {'al-latif': 2, 'al-khabir': 1, 'as-sami': 1},
      ),
      QuizOption(
        text: "I trust Him even when I don't understand His plan",
        scores: {'al-hakim': 2, 'al-wakil': 2, 'al-ali': 1},
      ),
      QuizOption(
        text: 'I long for a deeper, more loving connection',
        scores: {'al-wadud': 2, 'ar-rahim': 2, 'al-qarib': 1},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q3',
    prompt: 'Which struggle resonates with you most right now?',
    options: [
      QuizOption(
        text: 'Waiting \u2014 for an answer, a change, a sign',
        scores: {'as-sabur': 2, 'al-mujib': 2, 'al-fattah': 1},
      ),
      QuizOption(
        text: 'Feeling unseen or misunderstood by others',
        scores: {'al-basir': 2, 'ash-shahid': 1, 'al-khabir': 1},
      ),
      QuizOption(
        text: "Carrying guilt or shame I can't seem to shake",
        scores: {'al-ghaffar': 2, 'al-afuw': 2, 'at-tawwab': 1},
      ),
      QuizOption(
        text: 'Feeling scattered, lost, or without direction',
        scores: {'al-hadi': 2, 'an-nur': 2, 'ar-rabb': 1},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q4',
    prompt: 'A moment of genuine peace for you looks like:',
    options: [
      QuizOption(
        text: 'Quiet stillness \u2014 no noise, no pressure',
        scores: {'as-salam': 2, 'al-quddus': 1, 'as-samad': 1},
      ),
      QuizOption(
        text: 'Feeling completely known and still loved',
        scores: {'al-wadud': 2, 'al-khabir': 1, 'ar-rahim': 1},
      ),
      QuizOption(
        text: 'Knowing my provision and future are taken care of',
        scores: {'ar-razzaq': 2, 'al-wakil': 1, 'al-qayyum': 1},
      ),
      QuizOption(
        text: 'A breakthrough \u2014 something finally opening up',
        scores: {'al-fattah': 2, 'al-latif': 1, 'al-mujib': 1},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q5',
    prompt: 'When you pray, what are you most often asking for?',
    options: [
      QuizOption(
        text: 'Healing \u2014 for my heart, body, or relationships',
        scores: {'ash-shafi': 2, 'ar-rahman': 1, 'al-latif': 1},
      ),
      QuizOption(
        text: 'Strength to keep going when I want to give up',
        scores: {'al-qawi': 2, 'as-sabur': 1, 'al-matin': 1},
      ),
      QuizOption(
        text: 'Guidance \u2014 to know the right path',
        scores: {'al-hadi': 2, 'al-hakim': 1, 'an-nur': 1},
      ),
      QuizOption(
        text: 'Forgiveness \u2014 more than anything else',
        scores: {'al-afuw': 2, 'al-ghaffar': 1, 'at-tawwab': 1},
      ),
    ],
  ),
  QuizQuestion(
    id: 'q6',
    prompt: 'How do you most naturally connect with Allah?',
    options: [
      QuizOption(
        text: 'Through difficulty \u2014 hardship brings me closer',
        scores: {'as-sabur': 1, 'al-mujib': 1, 'ar-rabb': 2},
      ),
      QuizOption(
        text: 'Through beauty \u2014 nature, art, the world around me',
        scores: {'al-latif': 2, 'an-nur': 1, 'al-jamil': 1},
      ),
      QuizOption(
        text: 'Through gratitude \u2014 counting what I have',
        scores: {'ar-razzaq': 2, 'ash-shakur': 2, 'al-karim': 1},
      ),
      QuizOption(
        text: 'Through dua \u2014 just talking to Him',
        scores: {'al-qarib': 2, 'as-sami': 1, 'al-mujib': 2},
      ),
    ],
  ),
];

/// Metadata for each Name key used in the quiz.
const Map<String, NameAnchorInfo> nameAnchors = {
  'ar-rahman': NameAnchorInfo(
    name: 'Ar-Rahman',
    arabic: '\u0627\u0644\u0631\u064E\u0651\u062D\u0652\u0645\u064E\u0670\u0646\u064F',
    anchor: 'You are held by infinite mercy.',
    detail:
        'Ar-Rahman is the name Allah chose for Himself above all others. Return to it whenever you feel unworthy \u2014 His mercy is not earned, it simply is.',
  ),
  'ar-rahim': NameAnchorInfo(
    name: 'Ar-Rahim',
    arabic: '\u0627\u0644\u0631\u064E\u0651\u062D\u0650\u064A\u0645\u064F',
    anchor: 'You are intimately, personally loved.',
    detail:
        'Where Ar-Rahman is mercy for all creation, Ar-Rahim is the mercy He reserves especially for believers. You are not just tolerated \u2014 you are treasured.',
  ),
  'al-wadud': NameAnchorInfo(
    name: 'Al-Wadud',
    arabic: '\u0627\u0644\u0652\u0648\u064E\u062F\u064F\u0648\u062F\u064F',
    anchor: 'You are wired for deep, lasting love.',
    detail:
        'Al-Wadud means Allah loves with a love that does not waver or cool. The ache for real connection in you is a reflection of how He made you to be loved by Him.',
  ),
  'as-sami': NameAnchorInfo(
    name: "As-Sami'",
    arabic: '\u0627\u0644\u0633\u064E\u0651\u0645\u0650\u064A\u0639\u064F',
    anchor: 'Every word you speak to Him lands.',
    detail:
        "As-Sami' \u2014 the All-Hearing \u2014 means not a single dua is lost in the air. Even your half-formed prayers, your silent ones, the ones that are just feelings \u2014 He hears them all.",
  ),
  'al-qarib': NameAnchorInfo(
    name: 'Al-Qarib',
    arabic: '\u0627\u0644\u0652\u0642\u064E\u0631\u0650\u064A\u0628\u064F',
    anchor: 'He is closer to you than you think.',
    detail:
        'Al-Qarib means the Near One. The distance you feel is not real \u2014 it is a feeling, not a fact. He is nearer to you than your own jugular vein.',
  ),
  'al-mujib': NameAnchorInfo(
    name: 'Al-Mujib',
    arabic: '\u0627\u0644\u0652\u0645\u064F\u062C\u0650\u064A\u0628\u064F',
    anchor: 'Your duas are being answered.',
    detail:
        'Al-Mujib is the Responsive One. Every sincere call is met \u2014 sometimes immediately, sometimes in a way you do not yet see. Keep asking.',
  ),
  'al-latif': NameAnchorInfo(
    name: 'Al-Latif',
    arabic: '\u0627\u0644\u0644\u064E\u0651\u0637\u0650\u064A\u0641\u064F',
    anchor: 'He works in the details you cannot see.',
    detail:
        "Al-Latif is the Subtly Kind \u2014 the One who arranges things through small mercies and unseen movements. What looks like coincidence is often Al-Latif's hand.",
  ),
  'al-hakim': NameAnchorInfo(
    name: 'Al-Hakim',
    arabic: '\u0627\u0644\u0652\u062D\u064E\u0643\u0650\u064A\u0645\u064F',
    anchor: 'Nothing in your life is wasted.',
    detail:
        'Al-Hakim means every decree has been placed with perfect wisdom. The things that make no sense to you now are woven with a purpose that will one day be clear.',
  ),
  'al-wakil': NameAnchorInfo(
    name: 'Al-Wakil',
    arabic: '\u0627\u0644\u0652\u0648\u064E\u0643\u0650\u064A\u0644\u064F',
    anchor: 'You can let go \u2014 He has it.',
    detail:
        "Al-Wakil is the Trustee, the One you hand your affairs over to completely. Hasbunallahu wa ni'mal wakil \u2014 Allah is enough for us, and He is the best Disposer of affairs.",
  ),
  'as-sabur': NameAnchorInfo(
    name: 'As-Sabur',
    arabic: '\u0627\u0644\u0635\u064E\u0651\u0628\u064F\u0648\u0631\u064F',
    anchor: 'The wait is not a sign that He has forgotten you.',
    detail:
        'As-Sabur \u2014 the Patient One \u2014 never rushes His decree out of frustration. His timing is not delay; it is precision. And He gives you the strength to endure it.',
  ),
  'al-fattah': NameAnchorInfo(
    name: 'Al-Fattah',
    arabic: '\u0627\u0644\u0652\u0641\u064E\u062A\u064E\u0651\u0627\u062D\u064F',
    anchor: 'Doors will open that you cannot open yourself.',
    detail:
        'Al-Fattah is the Opener of all things. No door is permanently shut to the one who returns to Him. The breakthrough you are waiting for is in His hands.',
  ),
  'al-ghaffar': NameAnchorInfo(
    name: 'Al-Ghaffar',
    arabic: '\u0627\u0644\u0652\u063A\u064E\u0641\u064E\u0651\u0627\u0631\u064F',
    anchor: 'You are not defined by your worst moments.',
    detail:
        'Al-Ghaffar means the One who forgives repeatedly, without limit. The same sin brought back with a sincere heart is forgiven again. He does not keep a tally against you.',
  ),
  'al-afuw': NameAnchorInfo(
    name: "Al-'Afuw",
    arabic: '\u0627\u0644\u0652\u0639\u064E\u0641\u064F\u0648\u064F',
    anchor: "His forgiveness erases \u2014 it doesn't just cover.",
    detail:
        "Al-'Afuw goes further than forgiveness: it means to completely wipe away, as if it never happened. Ask for it often. It is what the Prophet \uFDFA taught us to seek on Laylatul Qadr.",
  ),
  'at-tawwab': NameAnchorInfo(
    name: 'At-Tawwab',
    arabic: '\u0627\u0644\u062A\u064E\u0651\u0648\u064E\u0651\u0627\u0628\u064F',
    anchor: 'The door of return is always open.',
    detail:
        'At-Tawwab means Allah turns to His servant the moment the servant turns to Him. You do not have to earn your way back \u2014 the turning itself is the beginning.',
  ),
  'al-hadi': NameAnchorInfo(
    name: 'Al-Hadi',
    arabic: '\u0627\u0644\u0652\u0647\u064E\u0627\u062F\u0650\u064A',
    anchor: 'You will be guided to where you need to be.',
    detail:
        'Al-Hadi is the Guide \u2014 the One who places clarity in hearts that ask for it. If you feel lost, ask Him directly: "Guide me." He answers that prayer.',
  ),
  'an-nur': NameAnchorInfo(
    name: 'An-Nur',
    arabic: '\u0627\u0644\u0646\u064F\u0651\u0648\u0631\u064F',
    anchor: 'His light finds you even in the dark.',
    detail:
        'An-Nur is the Light of the heavens and the earth. When you feel spiritually dim, it is not permanent \u2014 the same source of light that created the stars is available to your heart.',
  ),
  'ar-rabb': NameAnchorInfo(
    name: 'Ar-Rabb',
    arabic: '\u0627\u0644\u0631\u064E\u0651\u0628\u064F',
    anchor: 'You are being tended to, not just observed.',
    detail:
        'Ar-Rabb is the Lord who nurtures, sustains, and tends \u2014 like a gardener to a plant. Every hardship in your life has been shaped by One who knows exactly what you need to grow.',
  ),
  'al-qayyum': NameAnchorInfo(
    name: 'Al-Qayyum',
    arabic: '\u0627\u0644\u0652\u0642\u064E\u064A\u064F\u0651\u0648\u0645\u064F',
    anchor: 'He is the only constant when everything shifts.',
    detail:
        'Al-Qayyum means self-subsisting and sustaining all things. When everything you lean on feels unstable, He is the one ground that cannot give way.',
  ),
  'as-salam': NameAnchorInfo(
    name: 'As-Salam',
    arabic: '\u0627\u0644\u0633\u064E\u0651\u0644\u064E\u0627\u0645\u064F',
    anchor: 'Peace is a person you can return to.',
    detail:
        'As-Salam is not just a greeting \u2014 it is a Name. Allah Himself is the source of all peace. The stillness you are searching for lives in closeness to Him.',
  ),
  'ar-razzaq': NameAnchorInfo(
    name: 'Ar-Razzaq',
    arabic: '\u0627\u0644\u0631\u064E\u0651\u0632\u064E\u0651\u0627\u0642\u064F',
    anchor: 'Your provision has already been written.',
    detail:
        'Ar-Razzaq \u2014 the Provider \u2014 has already decreed every provision that will ever reach you. Work, but release the grip of anxiety: what is yours will not pass you by.',
  ),
  'ash-shafi': NameAnchorInfo(
    name: 'Ash-Shafi',
    arabic: '\u0627\u0644\u0634\u064E\u0651\u0627\u0641\u0650\u064A',
    anchor: 'Healing \u2014 of every kind \u2014 is in His hands.',
    detail:
        'Ash-Shafi is the Healer. No wound is beyond Him \u2014 physical, emotional, spiritual. The Prophet \uFDFA said: there is no disease He created except He also created its cure.',
  ),
  'al-basir': NameAnchorInfo(
    name: 'Al-Basir',
    arabic: '\u0627\u0644\u0652\u0628\u064E\u0635\u0650\u064A\u0631\u064F',
    anchor: 'He sees everything others overlook in you.',
    detail:
        'Al-Basir is the All-Seeing. No effort you make, no hidden sacrifice, no quiet struggle goes unseen by Him. He witnesses what no one else does.',
  ),
  'al-khabir': NameAnchorInfo(
    name: 'Al-Khabir',
    arabic: '\u0627\u0644\u0652\u062E\u064E\u0628\u0650\u064A\u0631\u064F',
    anchor: 'He knows your interior life completely.',
    detail:
        "Al-Khabir means He is aware of the subtlest movements of your heart \u2014 the feelings you can't name, the doubts you're ashamed of. He knows, and He is not alarmed.",
  ),
  'al-qawi': NameAnchorInfo(
    name: 'Al-Qawi',
    arabic: '\u0627\u0644\u0652\u0642\u064E\u0648\u0650\u064A\u064F\u0651',
    anchor: 'His strength is available to you.',
    detail:
        'Al-Qawi \u2014 the All-Strong \u2014 does not deplete. When your strength runs out, you are invited to draw from an inexhaustible source. Ask Him for it.',
  ),
  'al-matin': NameAnchorInfo(
    name: 'Al-Matin',
    arabic: '\u0627\u0644\u0652\u0645\u064E\u062A\u0650\u064A\u0646\u064F',
    anchor: 'There is a steadiness beneath your feet.',
    detail:
        'Al-Matin is the Firm, the Steadfast. Nothing shakes Him. And those who hold to Him find that same firmness enters their own hearts.',
  ),
  'al-karim': NameAnchorInfo(
    name: 'Al-Karim',
    arabic: '\u0627\u0644\u0652\u0643\u064E\u0631\u0650\u064A\u0645\u064F',
    anchor: 'He gives generously, without you having to deserve it.',
    detail:
        'Al-Karim is the Generous One who gives before you even ask, and gives more than you expected. His generosity is not proportional to your worthiness.',
  ),
  'ash-shakur': NameAnchorInfo(
    name: 'Ash-Shakur',
    arabic: '\u0627\u0644\u0634\u064E\u0651\u0643\u064F\u0648\u0631\u064F',
    anchor: 'Every act of gratitude multiplies what you have.',
    detail:
        'Ash-Shakur means Allah Himself is grateful \u2014 He amplifies and rewards the smallest good deeds beyond what they deserve. Gratitude is one of the most powerful postures you can take.',
  ),
  'al-quddus': NameAnchorInfo(
    name: 'Al-Quddus',
    arabic: '\u0627\u0644\u0652\u0642\u064F\u062F\u064F\u0651\u0648\u0633\u064F',
    anchor: 'There is a purity available to your heart.',
    detail:
        'Al-Quddus is the Most Holy, free of all imperfection. Connecting to Him is how the heart gets cleansed \u2014 not by your effort alone, but by proximity to the One who is pure.',
  ),
  'as-samad': NameAnchorInfo(
    name: 'As-Samad',
    arabic: '\u0627\u0644\u0635\u064E\u0651\u0645\u064E\u062F\u064F',
    anchor: 'He is the only One who can truly fill what is empty.',
    detail:
        'As-Samad means the Self-Sufficient Master whom all depend on. Every longing, every unfilled place in you \u2014 it points toward the One it was designed for.',
  ),
  'al-ali': NameAnchorInfo(
    name: "Al-'Ali",
    arabic: '\u0627\u0644\u0652\u0639\u064E\u0644\u0650\u064A\u064F\u0651',
    anchor: 'He sees your situation from above \u2014 all of it.',
    detail:
        "Al-'Ali is the Most High. His perspective encompasses what you cannot see from where you stand. Trust that He sees the full picture when you can only see a fragment.",
  ),
  'al-jamil': NameAnchorInfo(
    name: 'Al-Jamil',
    arabic: '\u0627\u0644\u0652\u062C\u064E\u0645\u0650\u064A\u0644\u064F',
    anchor: 'Beauty in this world is a trace of Him.',
    detail:
        'Al-Jamil \u2014 the Beautiful \u2014 loves beauty. The moments of beauty that stop you in your tracks are whispers from the One whose beauty is infinite. Let them draw you to Him.',
  ),
  'ash-shahid': NameAnchorInfo(
    name: 'Ash-Shahid',
    arabic: '\u0627\u0644\u0634\u064E\u0651\u0647\u0650\u064A\u062F\u064F',
    anchor: 'He is a witness to everything you endure.',
    detail:
        'Ash-Shahid is the Witness. Nothing you go through is unobserved. Every moment of patience, every private struggle \u2014 He sees it all and will account for it.',
  ),
};

/// Calculate quiz results from user answers.
/// [answers] is a list of selected option indices (0-based), one per question.
/// Returns the top 3 Names as [AnchorResult] sorted by score descending.
List<AnchorResult> calculateQuizResults(List<int> answers) {
  final Map<String, int> tally = {};

  for (int i = 0; i < answers.length && i < discoveryQuizQuestions.length; i++) {
    final question = discoveryQuizQuestions[i];
    final optionIndex = answers[i];
    if (optionIndex < 0 || optionIndex >= question.options.length) continue;

    final scores = question.options[optionIndex].scores;
    for (final entry in scores.entries) {
      tally[entry.key] = (tally[entry.key] ?? 0) + entry.value;
    }
  }

  // Sort by score descending, take top 3
  final sorted = tally.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top3 = sorted.take(3).toList();

  return top3.map((entry) {
    final info = nameAnchors[entry.key];
    return AnchorResult(
      nameKey: entry.key,
      name: info?.name ?? entry.key,
      arabic: info?.arabic ?? '',
      score: entry.value,
      anchor: info?.anchor ?? '',
      detail: info?.detail ?? '',
    );
  }).toList();
}
