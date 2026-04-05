// ---------------------------------------------------------------------------
// Adaptive 4-question check-in tree
//
// Q1 — emotional state (fixed)
// Q2 — domain, driven by Q1 answer
// Q3 — depth, driven by Q1+Q2 answers
// Q4 — need, fixed options tuned by path
// ---------------------------------------------------------------------------

class CheckInQuestion {
  final String question;
  final List<String> options;

  const CheckInQuestion({required this.question, required this.options});
}

// ─────────────────────────────────────────────────────────────────────────────
// Q1 — Always first. Broad emotional temperature check.
// ─────────────────────────────────────────────────────────────────────────────

const CheckInQuestion q1 = CheckInQuestion(
  question: 'How are you feeling right now?',
  options: [
    'Heavy — something is weighing on me',
    'Anxious — my mind won\'t settle',
    'Grateful — I want to deepen what I feel',
    'Disconnected — I feel distant from myself or Allah',
    'Hopeful — something good is unfolding',
    'Okay, but something is quietly off',
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Q2 — Domain. Options adapt to Q1 answer.
// ─────────────────────────────────────────────────────────────────────────────

CheckInQuestion getQ2(String q1Answer) {
  if (q1Answer.startsWith('Grateful')) {
    return const CheckInQuestion(
      question: 'What is the gratitude rooted in?',
      options: [
        'A blessing I didn\'t earn and can\'t explain',
        'Getting through something I thought I couldn\'t',
        'A relationship that has been a gift',
        'A feeling of Allah\'s closeness today',
      ],
    );
  }
  if (q1Answer.startsWith('Hopeful')) {
    return const CheckInQuestion(
      question: 'What is the hope about?',
      options: [
        'Something I\'ve been making du\'a for is moving',
        'A door opened after a long time closed',
        'I feel ready for something new',
        'A general sense that things are turning',
      ],
    );
  }
  if (q1Answer.startsWith('Heavy')) {
    return const CheckInQuestion(
      question: 'What is the weight coming from?',
      options: [
        'Something I did or didn\'t do',
        'A situation outside my control',
        'A relationship that is hurting me',
        'Grief or loss',
      ],
    );
  }
  if (q1Answer.startsWith('Anxious')) {
    return const CheckInQuestion(
      question: 'What is driving the anxiety?',
      options: [
        'Uncertainty about the future',
        'A decision I need to make',
        'Fear of failing or falling short',
        'Something I cannot fix or control',
      ],
    );
  }
  if (q1Answer.startsWith('Disconnected')) {
    return const CheckInQuestion(
      question: 'Where does the disconnection feel strongest?',
      options: [
        'In my relationship with Allah',
        'In my relationship with people I love',
        'From my own sense of purpose',
        'From any feeling at all — I feel numb',
      ],
    );
  }
  // "Okay, but something is quietly off"
  return const CheckInQuestion(
    question: 'What is the thing quietly bothering you?',
    options: [
      'A feeling I haven\'t named yet',
      'Something I have been avoiding',
      'Guilt or regret sitting in the background',
      'A longing I don\'t know how to meet',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Q3 — Depth. Adapts to Q1 + Q2 answer pair.
// ─────────────────────────────────────────────────────────────────────────────

CheckInQuestion getQ3(String q1Answer, String q2Answer) {
  // Grateful paths
  if (q1Answer.startsWith('Grateful')) {
    if (q2Answer.startsWith('A blessing')) {
      return const CheckInQuestion(
        question: 'How do you want to respond to this blessing?',
        options: [
          'By increasing my worship and remembrance',
          'By sharing it or giving back',
          'By truly internalizing it, not taking it for granted',
          'I\'m not sure — I just feel the weight of it',
        ],
      );
    }
    if (q2Answer.startsWith('Getting through')) {
      return const CheckInQuestion(
        question: 'What carried you through it?',
        options: [
          'Sabr — I held on even when I wanted to stop',
          'Du\'a — I kept asking even when it felt unanswered',
          'People Allah placed around me',
          'Something I can only describe as Allah\'s mercy',
        ],
      );
    }
    if (q2Answer.startsWith('A relationship')) {
      return const CheckInQuestion(
        question: 'What do you feel toward Allah about this person?',
        options: [
          'Gratitude — I know this is a gift from Him',
          'Awe — I didn\'t think I deserved this',
          'A desire to protect and not waste this',
          'Humility — He gave me what I couldn\'t give myself',
        ],
      );
    }
    // Allah's closeness
    return const CheckInQuestion(
      question: 'What is that closeness making you want to do?',
      options: [
        'Pray more, be still in it',
        'Make du\'a — I feel like He\'ll answer right now',
        'Give something — charity, time, kindness',
        'Just sit in it and not lose it',
      ],
    );
  }

  // Hopeful paths
  if (q1Answer.startsWith('Hopeful')) {
    if (q2Answer.startsWith('Something I\'ve been making du\'a')) {
      return const CheckInQuestion(
        question: 'What does this movement make you feel?',
        options: [
          'That Allah was listening the whole time',
          'Relief — I was starting to lose hope',
          'Awe — it happened in a way I didn\'t expect',
          'Urgency — I don\'t want to lose this momentum',
        ],
      );
    }
    if (q2Answer.startsWith('A door opened')) {
      return const CheckInQuestion(
        question: 'What do you need to step through it?',
        options: [
          'Courage — I\'m still hesitating',
          'Clarity that this is the right door',
          'Trust that Allah will be with me in it',
          'Nothing — I feel ready',
        ],
      );
    }
    if (q2Answer.startsWith('I feel ready')) {
      return const CheckInQuestion(
        question: 'Ready for what kind of newness?',
        options: [
          'A new chapter in my deen or spiritual life',
          'A new direction in how I live or work',
          'Letting go of something that has held me back',
          'Building something I\'ve been putting off',
        ],
      );
    }
    // General turning
    return const CheckInQuestion(
      question: 'Where is the hope strongest right now?',
      options: [
        'In my relationship with Allah',
        'In my circumstances or situation',
        'In who I am becoming',
        'In people around me',
      ],
    );
  }

  // Heavy paths
  if (q1Answer.startsWith('Heavy')) {
    if (q2Answer.startsWith('Something I did')) {
      return const CheckInQuestion(
        question: 'How are you sitting with what happened?',
        options: [
          'I keep replaying it and blaming myself',
          'I know I was wrong but don\'t know how to move forward',
          'I\'ve repented but the guilt won\'t leave',
          'I\'m still not sure what I should have done',
        ],
      );
    }
    if (q2Answer.startsWith('A situation outside')) {
      return const CheckInQuestion(
        question: 'What makes this situation hardest to bear?',
        options: [
          'I don\'t understand why it\'s happening',
          'I\'ve been patient for so long and nothing has changed',
          'I feel powerless and it\'s humiliating',
          'I\'m afraid of what comes next',
        ],
      );
    }
    if (q2Answer.startsWith('A relationship')) {
      return const CheckInQuestion(
        question: 'What is the pain in this relationship?',
        options: [
          'I feel unseen or unvalued',
          'Someone hurt me and hasn\'t acknowledged it',
          'I\'m struggling to forgive',
          'I\'m losing someone I love',
        ],
      );
    }
    // Grief or loss
    return const CheckInQuestion(
      question: 'What does this grief feel like right now?',
      options: [
        'Raw and fresh — I haven\'t processed it',
        'Old but still present — it doesn\'t go away',
        'Mixed with confusion about Allah\'s plan',
        'Quiet and heavy — I carry it alone',
      ],
    );
  }

  // Anxious paths
  if (q1Answer.startsWith('Anxious')) {
    if (q2Answer.startsWith('Uncertainty')) {
      return const CheckInQuestion(
        question: 'What feels most uncertain?',
        options: [
          'Whether things will work out for me',
          'What I\'m supposed to do next',
          'Whether I\'m on the right path',
          'How long I have to keep waiting',
        ],
      );
    }
    if (q2Answer.startsWith('A decision')) {
      return const CheckInQuestion(
        question: 'What is making the decision hard?',
        options: [
          'Fear of making the wrong choice',
          'I don\'t know what Allah wants for me',
          'The stakes feel too high',
          'I keep going back and forth',
        ],
      );
    }
    if (q2Answer.startsWith('Fear of failing')) {
      return const CheckInQuestion(
        question: 'What does failure mean to you in this?',
        options: [
          'Letting myself down after all my effort',
          'Letting others down who are counting on me',
          'Confirming my worst fears about myself',
          'Losing something I\'ve worked hard for',
        ],
      );
    }
    // Cannot fix or control
    return const CheckInQuestion(
      question: 'How are you responding to what you can\'t control?',
      options: [
        'Trying to control it anyway',
        'Overthinking every possible outcome',
        'Struggling to trust that it\'ll be okay',
        'Feeling angry that it\'s out of my hands',
      ],
    );
  }

  // Disconnected paths
  if (q1Answer.startsWith('Disconnected')) {
    if (q2Answer.startsWith('In my relationship with Allah')) {
      return const CheckInQuestion(
        question: 'When did you last feel close to Allah?',
        options: [
          'It\'s been a long time — I can\'t remember',
          'Recently, but something pulled me away',
          'I\'m not sure I ever really felt it',
          'I feel it sometimes, then it slips away',
        ],
      );
    }
    if (q2Answer.startsWith('In my relationship with people')) {
      return const CheckInQuestion(
        question: 'What is driving the distance from people?',
        options: [
          'I\'ve been hurt and I\'m protecting myself',
          'I don\'t feel understood by anyone',
          'I\'ve pulled away without knowing why',
          'The people I need aren\'t available to me',
        ],
      );
    }
    if (q2Answer.startsWith('From my own sense of purpose')) {
      return const CheckInQuestion(
        question: 'What does that lost sense of purpose feel like?',
        options: [
          'I don\'t know what I\'m working toward anymore',
          'I\'m doing the motions but it feels empty',
          'I feel like I\'m wasting the life Allah gave me',
          'I had direction before — I\'m not sure where it went',
        ],
      );
    }
    // Numb
    return const CheckInQuestion(
      question: 'How long have you felt this numbness?',
      options: [
        'Just today — something drained me',
        'For a while now — it\'s become normal',
        'It comes and goes — I never know when',
        'Since a specific thing happened',
      ],
    );
  }

  // "Okay but something is quietly off" paths
  if (q2Answer.startsWith('A feeling I haven\'t named')) {
    return const CheckInQuestion(
      question: 'If you had to get close to naming it, what would you say?',
      options: [
        'Something like restlessness',
        'Something like sadness without a clear cause',
        'Something like longing',
        'Something like unease I can\'t shake',
      ],
    );
  }
  if (q2Answer.startsWith('Something I have been avoiding')) {
    return const CheckInQuestion(
      question: 'What is it about this thing you\'re avoiding?',
      options: [
        'Facing it means accepting something painful',
        'I don\'t know how to deal with it',
        'I\'m afraid of what I\'ll find if I look closely',
        'It involves someone else and I don\'t want conflict',
      ],
    );
  }
  if (q2Answer.startsWith('Guilt or regret')) {
    return const CheckInQuestion(
      question: 'What is the guilt or regret about?',
      options: [
        'Something I did to someone else',
        'Time or opportunities I wasted',
        'Who I have been versus who I want to be',
        'Sins I keep returning to',
      ],
    );
  }
  // Longing
  return const CheckInQuestion(
    question: 'What is the longing for?',
    options: [
      'Peace — a quietness I can\'t find',
      'Connection — to feel truly known',
      'Meaning — a sense that this all matters',
      'Allah — a closeness I\'ve felt before',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Q4 — Always last. What does the user need right now?
// Options are constant — they apply to any emotional path.
// ─────────────────────────────────────────────────────────────────────────────

const CheckInQuestion q4 = CheckInQuestion(
  question: 'What do you need most from Allah right now?',
  options: [
    'To feel that He sees me and hasn\'t forgotten me',
    'Strength to keep going when I have nothing left',
    'Peace — a quieting of what is loud inside me',
    'Clarity — to understand what is happening and why',
  ],
);
