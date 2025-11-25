class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String category;
  final String language;
  final String difficulty;
  final String? hint;
  final String? mediaType; // 'image', 'audio', 'video', 'none'
  final String? mediaUrl;
  final int reportCount;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.language,
    required this.difficulty,
    this.hint,
    this.mediaType,
    this.mediaUrl,
    this.reportCount = 0,
  });

  factory QuestionModel.fromSupabase(Map<String, dynamic> data) {
    List<String> parsedOptions = [];
    if (data['options'] is List) {
      parsedOptions = List<String>.from(data['options']);
    }

    return QuestionModel(
      id: data['id'] ?? '',
      question: data['question'] ?? '',
      options: parsedOptions,
      correctAnswer: data['correct_answer'] ?? '',
      category: data['category_id'] ?? '',
      language: data['language'] ?? 'ar',
      difficulty: data['difficulty'] ?? 'medium',
      hint: data['hint'],
      mediaType: data['media_type'] ?? 'none',
      mediaUrl: data['media_url'],
      reportCount: data['report_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'category_id': category,
      'language': language,
      'difficulty': difficulty,
      'hint': hint,
      'media_type': mediaType,
      'media_url': mediaUrl,
    };
  }
}
