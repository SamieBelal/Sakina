class DailyQuestion {
  final int id;
  final String question;
  final List<String> options;

  const DailyQuestion({
    required this.id,
    required this.question,
    required this.options,
  });
}

const List<DailyQuestion> dailyQuestions = [
  DailyQuestion(id: 0, question: 'What is weighing on you most right now?', options: ['Uncertainty about the future', 'A strained relationship', 'Feeling behind in life', 'Loss or grief']),
  DailyQuestion(id: 1, question: 'Where do you feel most lacking today?', options: ['Patience', 'Gratitude', 'Trust in Allah', 'Discipline']),
  DailyQuestion(id: 2, question: 'What emotion is closest to the surface for you?', options: ['Anxiety', 'Sadness', 'Anger', 'Emptiness']),
  DailyQuestion(id: 3, question: 'What kind of strength do you need most right now?', options: ['To keep going', 'To let go', 'To forgive', 'To start over']),
  DailyQuestion(id: 4, question: 'What has been hardest about this week?', options: ['My own mistakes', "Others' actions", 'Things outside my control', 'Feeling disconnected from Allah']),
  DailyQuestion(id: 5, question: "What do you most wish Allah knew about what you're going through?", options: ['How tired I am', "That I'm trying", "How much I've lost", 'How confused I feel']),
  DailyQuestion(id: 6, question: 'Which feeling describes your relationship with your past right now?', options: ['Regret', 'Shame', 'Acceptance', 'Still unresolved']),
  DailyQuestion(id: 7, question: 'What do you need most from your faith today?', options: ['Reassurance', 'Clarity', 'Comfort', 'Motivation']),
  DailyQuestion(id: 8, question: 'What is your biggest source of worry right now?', options: ['My health or someone I love', 'My finances or provision', 'My purpose or direction', 'My relationships']),
  DailyQuestion(id: 9, question: 'How would you describe your inner state today?', options: ['Restless', 'Numb', 'Fragile', 'Struggling but holding on']),
  DailyQuestion(id: 10, question: 'What have you been avoiding facing?', options: ['A difficult conversation', 'A decision I need to make', 'My own shortcomings', "A loss I haven't processed"]),
  DailyQuestion(id: 11, question: 'Where do you feel most alone right now?', options: ['In my pain', 'In my goals', 'In my faith', 'In my responsibilities']),
  DailyQuestion(id: 12, question: 'What do you wish you could change about yourself?', options: ['My reaction to hardship', 'My consistency in worship', 'How I treat others', 'My self-doubt']),
  DailyQuestion(id: 13, question: 'What does success feel like right now — and how does it feel out of reach?', options: ['Very far away', 'Almost there but slipping', "I'm not sure what it looks like", "I've given up on it for now"]),
  DailyQuestion(id: 14, question: 'Which area of your life feels most out of your hands?', options: ['Work or livelihood', 'Family or marriage', 'Health', 'My own heart']),
  DailyQuestion(id: 15, question: 'What is the heaviest thing you are carrying alone?', options: ['Guilt from the past', 'Fear about the future', 'A secret burden', 'Responsibility for others']),
  DailyQuestion(id: 16, question: 'What do you most need to hear from Allah right now?', options: ['You are not forgotten', 'Your effort is enough', 'There is a way through', 'You are forgiven']),
  DailyQuestion(id: 17, question: 'Which relationship is causing you the most pain?', options: ['With a family member', 'With a friend', 'With myself', 'With Allah']),
  DailyQuestion(id: 18, question: 'What has shaken your sense of hope recently?', options: ['Repeated disappointment', 'A specific loss or failure', 'Seeing others suffer', 'My own distance from deen']),
  DailyQuestion(id: 19, question: 'What emotion shows up when you think about the future?', options: ['Dread', 'Confusion', 'Cautious hope', 'Resignation']),
  DailyQuestion(id: 20, question: 'What have you been struggling to accept?', options: ['A door that closed', 'How someone treated me', 'A limitation in myself', "Allah's decree"]),
  DailyQuestion(id: 21, question: 'When do you feel furthest from Allah?', options: ["When I sin and don't repent", "When my duas don't seem answered", "When I'm overwhelmed", 'When I compare myself to others']),
  DailyQuestion(id: 22, question: 'What part of yourself do you judge most harshly?', options: ['My spiritual consistency', 'My emotional reactions', 'My past decisions', 'My sense of worth']),
  DailyQuestion(id: 23, question: 'What does your heart need to release today?', options: ['Resentment', 'Self-blame', 'Worry', 'Attachment to an outcome']),
  DailyQuestion(id: 24, question: 'What has been hardest about being patient?', options: ["I don't see any signs of relief", "I've been waiting too long", "Others around me aren't patient", "I'm not sure what I'm waiting for"]),
  DailyQuestion(id: 25, question: 'What kind of day has today been emotionally?', options: ['Heavy and depleting', 'Numb and disconnected', 'Anxious and uncertain', 'Sad but quiet']),
  DailyQuestion(id: 26, question: "What do you wish others understood about what you're going through?", options: ["How much I'm trying", 'How exhausted I am', 'How alone I feel', "How much I've already lost"]),
  DailyQuestion(id: 27, question: 'When you make a mistake, what feeling comes first?', options: ['Shame', 'Self-anger', 'Hopelessness', 'Numbness']),
  DailyQuestion(id: 28, question: "What has been hardest about trusting in Allah's plan?", options: ['The wait feels endless', 'It contradicts what I want', "I don't understand why", "I'm afraid of what comes next"]),
  DailyQuestion(id: 29, question: 'What one word describes where you are spiritually right now?', options: ['Distant', 'Searching', 'Fragile', 'Hopeful but struggling']),
];

/// Returns today's daily question based on the day of the year.
/// Cycles through all 30 questions using `dayOfYear % 30`.
DailyQuestion getTodaysDailyQuestion() {
  final now = DateTime.now();
  final startOfYear = DateTime(now.year, 1, 1);
  final dayOfYear = now.difference(startOfYear).inDays + 1;
  return dailyQuestions[dayOfYear % dailyQuestions.length];
}

/// Returns today's date as a `YYYY-MM-DD` string.
String todayKey() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

class DailyAnswer {
  final String date; // YYYY-MM-DD
  final int questionId;
  final String answer;
  final String name;
  final String nameArabic;
  final String teaching;
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;

  const DailyAnswer({
    required this.date,
    required this.questionId,
    required this.answer,
    required this.name,
    required this.nameArabic,
    required this.teaching,
    required this.duaArabic,
    required this.duaTransliteration,
    required this.duaTranslation,
  });

  factory DailyAnswer.fromJson(Map<String, dynamic> json) {
    return DailyAnswer(
      date: json['date'] as String,
      questionId: json['questionId'] as int,
      answer: json['answer'] as String,
      name: json['name'] as String,
      nameArabic: json['nameArabic'] as String,
      teaching: json['teaching'] as String,
      duaArabic: json['duaArabic'] as String,
      duaTransliteration: json['duaTransliteration'] as String,
      duaTranslation: json['duaTranslation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'questionId': questionId,
      'answer': answer,
      'name': name,
      'nameArabic': nameArabic,
      'teaching': teaching,
      'duaArabic': duaArabic,
      'duaTransliteration': duaTransliteration,
      'duaTranslation': duaTranslation,
    };
  }
}
