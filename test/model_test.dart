import 'package:flutter_test/flutter_test.dart';
import 'package:nibras_app/models/category_model.dart';
import 'package:nibras_app/models/question_model.dart';

void main() {
  group('Model Tests', () {
    test('CategoryModel should be created correctly', () {
      final category = CategoryModel(
        id: '1',
        name: 'Test',
        nameAr: 'تست',
        icon: 'icon.png',
      );
      
      expect(category.id, '1');
      expect(category.name, 'Test');
      expect(category.nameAr, 'تست');
    });

    test('QuestionModel should be created correctly', () {
      final question = QuestionModel(
        id: '1',
        question: 'Q1',
        options: ['A', 'B'],
        correctAnswer: 'A',
        category: 'cat1',
        language: 'en',
        difficulty: 'easy',
      );

      expect(question.question, 'Q1');
      expect(question.options.length, 2);
    });
  });
}
