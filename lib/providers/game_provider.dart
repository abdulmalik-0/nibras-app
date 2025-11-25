import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';
import '../models/question_model.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';

class GameProvider extends ChangeNotifier {
  SupabaseService? _supabaseService;
  
  GameProvider({SupabaseService? supabaseService}) 
      : _supabaseService = supabaseService;
  
  // Data
  List<QuestionModel> _allQuestions = [];
  List<QuestionModel> _availableQuestions = []; // Questions not yet answered
  
  // Game State
  int _currentQuestionIndex = 0; // Not used linearly anymore, but kept for compatibility
  bool _isLoading = false;
  Timer? _timer;
  int _timeLeft = 60;
  
  // Team Management
  List<String> _teams = [];
  int _currentTeamIndex = 0;
  Map<String, int> _teamScores = {};
  Map<String, bool> _teamHintsUsed = {};
  
  // Dynamic Flow State
  QuestionModel? _currentQuestion;
  bool _isSelectionPhase = true;
  bool _showAnswer = false;
  bool _isScoringPhase = false;
  bool _areOptionsVisible = false;
  
  // Steal Mechanic State
  bool _isStealPhase = false;
  int _originalTeamIndex = 0; // Tracks whose turn it originally was
  
  // Getters
  bool get isLoading => _isLoading;
  int get timeLeft => _timeLeft;
  bool get isGameOver => _allQuestions.isNotEmpty && _availableQuestions.isEmpty && _currentQuestion == null;
  
  List<String> get teams => _teams;
  String get currentTeamName => _teams.isNotEmpty ? _teams[_currentTeamIndex] : '';
  int get currentTeamScore => _teamScores[currentTeamName] ?? 0;
  int getTeamScore(String teamName) => _teamScores[teamName] ?? 0;
  int get score => currentTeamScore;

  QuestionModel? get currentQuestion => _currentQuestion;
  bool get isSelectionPhase => _isSelectionPhase;
  bool get showAnswer => _showAnswer;
  bool get isScoringPhase => _isScoringPhase;
  bool get areOptionsVisible => _areOptionsVisible;
  bool get isStealPhase => _isStealPhase;
  
  bool get canUseHint => !_isScoringPhase && !_isStealPhase && !(_teamHintsUsed[currentTeamName] ?? false);

  // Arabic Category Names
  static const Map<String, String> categoryNames = {
    'general_knowledge': 'ثقافة عامة',
    'science': 'علوم',
    'geography': 'جغرافيا',
    'history_religion': 'تاريخ وديانات',
    'sports_tech': 'رياضة وتقنية',
    'culture': 'ثقافة',
    'food_cooking': 'طعام ومطابخ',
    'cars_vehicles': 'سيارات ومركبات',
    'logos': 'شعارات',
    'world_flags': 'أعلام دول',
    'capitals_cities': 'عواصم ومدن',
    'proverbs': 'أمثال وحكم',
    'numbers_stats': 'أرقام وإحصائيات',
    'foreign_movies': 'أفلام أجنبية',
    'foreign_series': 'مسلسلات أجنبية',
    'anime': 'أنمي',
    'video_games': 'ألعاب فيديو',
  };

  // Available Categories (that have at least one unanswered question)
  List<String> get availableCategories {
    return _availableQuestions.map((q) => q.category).toSet().toList();
  }

  // Available Difficulties for a specific category
  List<String> getAvailableDifficulties(String category) {
    return _availableQuestions
        .where((q) => q.category == category)
        .map((q) => q.difficulty)
        .toSet()
        .toList();
  }

  // Initialize Game
  Future<void> initializeGame(List<String> categoryIds, List<String> teams) async {
    _isLoading = true;
    _teams = teams;
    _teamScores = {for (var team in teams) team: 0};
    _teamHintsUsed = {for (var team in teams) team: false};
    _currentTeamIndex = 0;
    _isSelectionPhase = true;
    _isScoringPhase = false;
    _showAnswer = false;
    _currentQuestion = null;
    _isStealPhase = false;
    notifyListeners();

    _supabaseService ??= SupabaseService();
    final authService = AuthService();
    final user = authService.currentUser;

    try {
      _allQuestions = [];
      
      // 2. Fetch answered questions with timestamps
      Map<String, DateTime> answeredData = {};
      if (user != null) {
        answeredData = await _supabaseService!.getAnsweredQuestionsData(user.id);
      }
      
      // 3. Fetch questions for selected categories
      List<QuestionModel> categoryQuestions = [];
      for (var category in categoryIds) { // Use the passed categoryIds argument
        var questions = await _supabaseService!.getQuestions(category, limit: 50);
        categoryQuestions.addAll(questions);
      }
      
      // 4. Select questions for the grid
      for (String difficulty in ['easy', 'medium', 'hard']) {
        // Filter by difficulty
        var difficultyQuestions = categoryQuestions.where((q) => q.difficulty == difficulty).toList();
        
        // Split into fresh and answered
        var freshPool = difficultyQuestions.where((q) => !answeredData.containsKey(q.id)).toList();
        var answeredPool = difficultyQuestions.where((q) => answeredData.containsKey(q.id)).toList();
        
        // Sort fresh by ID (Queue order for new questions)
        freshPool.sort((a, b) => a.id.compareTo(b.id));
        
        // Sort answered by timestamp (Oldest answered first -> Cyclic Queue)
        answeredPool.sort((a, b) {
          final timeA = answeredData[a.id]!;
          final timeB = answeredData[b.id]!;
          return timeA.compareTo(timeB);
        });
        
        // Try to take 2 from fresh pool
        var selected = freshPool.take(2).toList();
        
        // If we don't have enough fresh questions, fill with answered ones (oldest first)
        if (selected.length < 2) {
          int needed = 2 - selected.length;
          selected.addAll(answeredPool.take(needed));
        }
        
        _allQuestions.addAll(selected);
      }
      
      _availableQuestions = List.from(_allQuestions);
      
      if (_availableQuestions.isEmpty) {
        debugPrint('Warning: No questions fetched from Firestore. Using dummy data.');
        _availableQuestions = _getDummyQuestions();
      }

    } catch (e) {
      debugPrint('Error starting game: $e');
      _availableQuestions = _getDummyQuestions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get questions for a specific grid slot (ensures stable ordering)
  List<QuestionModel> getQuestionsForGrid(String category, String difficulty) {
    return _allQuestions
        .where((q) => q.category == category && q.difficulty == difficulty)
        .toList();
  }
  
  // Check if a specific question is still available
  bool isQuestionAvailable(QuestionModel question) {
    return _availableQuestions.contains(question);
  }

  // Step 1: Select Question
  void selectQuestion(String category, String difficulty) {
    // Legacy support or random selection if needed
    var candidates = _availableQuestions.where((q) => q.category == category && q.difficulty == difficulty).toList();
    if (candidates.isNotEmpty) {
      selectSpecificQuestion(candidates.first);
    }
  }

  // Select a specific question instance
  void selectSpecificQuestion(QuestionModel question) {
    if (_availableQuestions.contains(question)) {
      _currentQuestion = question;
      _availableQuestions.remove(question); // Remove from pool
      
      _isSelectionPhase = false;
      _showAnswer = false;
      _isScoringPhase = false;
      _areOptionsVisible = false;
      _isStealPhase = false;
      _originalTeamIndex = _currentTeamIndex; // Save who started the turn
      
      _startTimer();
      notifyListeners();
    }
  }

  // Lifeline: Reveal Options
  void revealOptionsForTeam() {
    if (canUseHint) {
      _areOptionsVisible = true;
      _teamHintsUsed[currentTeamName] = true; // Mark lifeline as used
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _isStealPhase ? 30 : 60; // 30s for steal, 60s for normal
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        // Time's up!
        _timer?.cancel();
        
        if (!_isStealPhase) {
          // Activate Steal Phase
          _isStealPhase = true;
          // Switch to next team
          _currentTeamIndex = (_currentTeamIndex + 1) % _teams.length;
          // Restart timer with half time
          _startTimer();
        } else {
          // Steal time up, show answer
          _showAnswer = true;
          _isScoringPhase = true;
          notifyListeners();
        }
      }
    });
  }
  
  // Step 2: Reveal Answer (Supervisor)
  void revealAnswer() {
    _timer?.cancel();
    _showAnswer = true;
    _isScoringPhase = true; // Now supervisor decides points
    notifyListeners();
  }

  // Step 3: Award Points (Supervisor)
  void awardPointsToTeam(String? teamName) {
    if (teamName != null && _currentQuestion != null) {
      int points = _getPointsForDifficulty(_currentQuestion!.difficulty);
      _teamScores[teamName] = (_teamScores[teamName] ?? 0) + points;
    }
    
    // Move to next turn
    _endTurn();
  }

  void _endTurn() {
    // Mark question as answered in Firestore for the current user
    if (_currentQuestion != null) {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user != null && _supabaseService != null) {
        _supabaseService!.markQuestionAsAnswered(user.id, _currentQuestion!.id);
      }
    }

    _currentQuestion = null;
    _isSelectionPhase = true;
    _isScoringPhase = false;
    _showAnswer = false;
    _isStealPhase = false;
    
    // Rotate team turn for SELECTION based on ORIGINAL turn
    // So if Team A started, next is Team B, regardless of who stole
    _currentTeamIndex = (_originalTeamIndex + 1) % _teams.length;
    
    notifyListeners();
  }
  
  void useHint() {
    // Deprecated in favor of revealOptionsForTeam, but kept for compatibility if needed
    if (canUseHint) {
      _teamHintsUsed[currentTeamName] = true;
      notifyListeners();
    }
  }

  int _getPointsForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'easy': return 5;
      case 'medium': return 10;
      case 'hard': return 15;
      default: return 10;
    }
  }

  List<QuestionModel> _getDummyQuestions() {
    return [
      QuestionModel(
        id: '1',
        question: 'سؤال تجريبي',
        options: ['أ', 'ب', 'ج', 'د'],
        correctAnswer: 'أ',
        category: 'general',
        language: 'ar',
        difficulty: 'easy',
      ),
    ];
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
