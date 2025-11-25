import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/question_view.dart';
import '../widgets/report_question_dialog.dart';
import '../widgets/answer_view.dart';
import '../widgets/score_display.dart';

class QuizPage extends StatelessWidget {
  final List<String> selectedCategories;
  final List<String> teams; // list of team names
  final bool showOptions; // true = multiple choice, false = free text
  
  const QuizPage({
    super.key,
    required this.selectedCategories,
    required this.teams,
    this.showOptions = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider()
        ..initializeGame(selectedCategories, teams),
      child: _QuizPageView(showOptions: showOptions),
    );
  }
}

class _QuizPageView extends StatefulWidget {
  final bool showOptions;

  const _QuizPageView({required this.showOptions});

  @override
  State<_QuizPageView> createState() => _QuizPageViewState();
}

class _QuizPageViewState extends State<_QuizPageView> {
  String? _selectedAnswer;
  bool _isAnswered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        if (game.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (game.isGameOver) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade900,
                    Colors.deepPurple.shade700,
                    Colors.purple.shade600,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 100,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'انتهت اللعبة!',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Display Final Scores
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: game.teams.map((team) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    team,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.amber.shade400,
                                          Colors.orange.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${game.getTeamScore(team)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'العودة للقائمة الرئيسية',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.deepPurple.shade700,
            elevation: 0,
            title: Row(
              children: [
                const Text(
                  'Nibras Quiz',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (game.isStealPhase)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'فرصة سرقة!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              // Display scores for ALL teams
              ...game.teams.map((team) {
                bool isCurrentTurn = team == game.currentTeamName;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrentTurn 
                            ? Colors.orange.shade600 
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: isCurrentTurn 
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            team,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${game.getTeamScore(team)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 16),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.deepPurple.shade500,
                  Colors.purple.shade400,
                ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildGameContent(context, game),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameContent(BuildContext context, GameProvider game) {
    if (game.isSelectionPhase) {
      return _buildSelectionView(game);
    } else if (game.isScoringPhase) {
      return _buildScoringView(game);
    } else {
      return _buildQuestionView(context, game);
    }
  }

  Widget _buildSelectionView(GameProvider game) {
    final difficulties = ['easy', 'medium', 'hard'];
    
    // Chunk categories into groups of 3
    List<List<String>> categoryChunks = [];
    for (var i = 0; i < game.availableCategories.length; i += 3) {
      categoryChunks.add(
        game.availableCategories.skip(i).take(3).toList(),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'دور فريق: ${game.currentTeamName}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: categoryChunks.map((chunk) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Column(
                    children: [
                      // Category headers row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: chunk.map((category) {
                            String displayName = GameProvider.categoryNames[category] ?? category;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade600,
                                      Colors.orange.shade800,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Difficulty rows
                      ...difficulties.map((difficulty) {
                        int points = _getPointsForDifficulty(difficulty);
                        
                        // Color based on difficulty
                        Color cardColor;
                        if (difficulty == 'easy') {
                          cardColor = Colors.green.shade600;
                        } else if (difficulty == 'medium') {
                          cardColor = Colors.orange.shade600;
                        } else {
                          cardColor = Colors.red.shade600;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: chunk.map((category) {
                              // Get specific questions for this slot to ensure stable Left/Right assignment
                              var slotQuestions = game.getQuestionsForGrid(category, difficulty);
                              
                              // We expect up to 2 questions per slot
                              var q1 = slotQuestions.isNotEmpty ? slotQuestions[0] : null;
                              var q2 = slotQuestions.length > 1 ? slotQuestions[1] : null;
                              
                              bool isQ1Available = q1 != null && game.isQuestionAvailable(q1);
                              bool isQ2Available = q2 != null && game.isQuestionAvailable(q2);
                              
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Row(
                                      children: [
                                        // Right half (Question 1)
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: isQ1Available
                                                ? () {
                                                    game.selectSpecificQuestion(q1!);
                                                  }
                                                : null,
                                            child: Container(
                                              color: isQ1Available ? cardColor : Colors.transparent,
                                              child: Center(
                                                child: Text(
                                                  isQ1Available ? '$points' : '',
                                                  style: const TextStyle(
                                                    fontSize: 52,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Divider (only if both are visible, or just keep it simple)
                                        Container(
                                          width: 2,
                                          height: double.infinity,
                                          color: Colors.black.withOpacity(0.2),
                                        ),
                                        // Left half (Question 2)
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: isQ2Available
                                                ? () {
                                                    game.selectSpecificQuestion(q2!);
                                                  }
                                                : null,
                                            child: Container(
                                              color: isQ2Available ? cardColor : Colors.transparent,
                                              child: Center(
                                                child: Text(
                                                  isQ2Available ? '$points' : '',
                                                  style: const TextStyle(
                                                    fontSize: 52,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  int _getPointsForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'easy': return 5;
      case 'medium': return 10;
      case 'hard': return 15;
      default: return 10;
    }
  }

  Widget _buildQuestionView(BuildContext context, GameProvider game) {
    final question = game.currentQuestion!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScoreDisplay(score: game.score, timeLeft: game.timeLeft),
        const SizedBox(height: 32),
        QuestionView(question: question),
        
        // Lifeline Button (Show Options)
        if (!game.areOptionsVisible && game.canUseHint)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: () {
                game.revealOptionsForTeam();
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('طلب الخيارات (مرة واحدة)'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        const SizedBox(height: 32),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Show options if requested
                if (game.areOptionsVisible)
                  AnswerView(
                    options: question.options,
                    selectedAnswer: _selectedAnswer,
                    correctAnswer: question.correctAnswer,
                    isAnswered: game.showAnswer,
                    onAnswerSelected: (answer) {
                      setState(() {
                        _selectedAnswer = answer;
                      });
                    },
                  )
                else if (game.showAnswer)
                  // Show question text and answer together
                  Column(
                    children: [
                      // Question Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          'السؤال: ${question.question}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Answer
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          'الإجابة الصحيحة: ${question.correctAnswer}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Report Button
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => ReportQuestionDialog(questionId: question.id),
                            );
                          },
                          icon: const Icon(Icons.flag, color: Colors.red),
                          label: const Text('الإبلاغ عن السؤال', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                
                // Supervisor reveal button (always show if answer not revealed)
                if (!game.showAnswer)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: game.revealAnswer,
                        icon: const Icon(Icons.visibility),
                        label: const Text('إظهار الإجابة (للمشرف)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildScoringView(GameProvider game) {
    final question = game.currentQuestion!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Text
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'السؤال:',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SelectableText(
                question.question,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Answer
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'الإجابة الصحيحة هي:',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SelectableText(
                question.correctAnswer,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Report Button
        Center(
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ReportQuestionDialog(questionId: question.id),
              );
            },
            icon: const Icon(Icons.flag, color: Colors.red, size: 24),
            label: const Text(
              'الإبلاغ عن السؤال',
              style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'من أجاب بشكل صحيح؟',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              ...game.teams.map((team) {
                return ElevatedButton.icon(
                  onPressed: () => game.awardPointsToTeam(team),
                  icon: const Icon(Icons.check_circle),
                  label: Text(team),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade900,
                  ),
                );
              }),
              ElevatedButton.icon(
                onPressed: () => game.awardPointsToTeam(null), // No one gets points
                icon: const Icon(Icons.cancel),
                label: const Text('لا أحد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
