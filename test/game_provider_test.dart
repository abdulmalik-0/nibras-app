import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nibras_app/models/category_model.dart';
import 'package:nibras_app/models/question_model.dart';
import 'package:nibras_app/providers/game_provider.dart';
import 'package:nibras_app/services/firestore_service.dart';

// Mock FirestoreService
class MockFirestoreService implements FirestoreService {
  @override
  Stream<List<CategoryModel>> getCategories() {
    return Stream.value([]);
  }

  @override
  Future<List<QuestionModel>> getQuestions(String categoryId) async {
    return [];
  }

  @override
  Future<void> createUser(dynamic user) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameProvider Tests', () {
    late GameProvider gameProvider;

    setUp(() {
      // Use mock service to avoid Firebase init
      gameProvider = GameProvider(firestoreService: MockFirestoreService());
      
      // Mock rootBundle to return dummy JSON
      // This is a bit complex in unit tests without a proper mock framework for rootBundle
      // So we might expect the JSON load to fail and fall back to dummy/empty in this test environment
      // unless we set up the asset bundle.
    });

    test('Initial state should be correct', () {
      expect(gameProvider.score, 0);
      expect(gameProvider.currentQuestionIndex, 0);
      expect(gameProvider.isLoading, false);
      expect(gameProvider.timeLeft, 30);
    });

    test('startGame should load questions (fallback to dummy if asset fails)', () async {
      await gameProvider.startGame(['dummy']);
      expect(gameProvider.questions.isNotEmpty, true);
      expect(gameProvider.currentQuestion, isNotNull);
      expect(gameProvider.isLoading, false);
    });

    test('submitAnswer should update score if correct', () async {
      await gameProvider.startGame(['dummy']);
      final correctAnswer = gameProvider.currentQuestion!.correctAnswer;
      
      gameProvider.submitAnswer(correctAnswer);
      
      // Wait for the delay in submitAnswer
      await Future.delayed(const Duration(seconds: 3));
      
      expect(gameProvider.score, 10);
    });

    test('submitAnswer should NOT update score if incorrect', () async {
      await gameProvider.startGame(['dummy']);
      final wrongAnswer = 'Wrong Answer';
      
      gameProvider.submitAnswer(wrongAnswer);
      
      // Wait for the delay in submitAnswer
      await Future.delayed(const Duration(seconds: 3));
      
      expect(gameProvider.score, 0);
    });
  });
}
