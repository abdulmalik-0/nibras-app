import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/category_model.dart';
import '../services/supabase_service.dart';
import 'edit_question_page.dart';
import 'add_question_page.dart'; // We will create this next

class QuestionManagementPage extends StatefulWidget {
  const QuestionManagementPage({super.key});

  @override
  State<QuestionManagementPage> createState() => _QuestionManagementPageState();
}

class _QuestionManagementPageState extends State<QuestionManagementPage> {
  final _supabaseService = SupabaseService();
  List<QuestionModel> _questions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _selectedCategoryId;
  final ScrollController _scrollController = ScrollController();
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreQuestions();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _supabaseService.getCategories();
      final questions = await _supabaseService.getAllQuestions(limit: _limit, offset: 0);
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _questions = questions;
          _offset = questions.length;
          _hasMore = questions.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreQuestions() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final newQuestions = await _supabaseService.getAllQuestions(
        limit: _limit, 
        offset: _offset,
        categoryId: _selectedCategoryId,
      );
      
      if (mounted) {
        setState(() {
          _questions.addAll(newQuestions);
          _offset += newQuestions.length;
          _hasMore = newQuestions.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _filterByCategory(String? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _questions = [];
      _offset = 0;
      _hasMore = true;
      _isLoading = true;
    });

    try {
      final questions = await _supabaseService.getAllQuestions(
        limit: _limit, 
        offset: 0,
        categoryId: categoryId,
      );
      
      if (mounted) {
        setState(() {
          _questions = questions;
          _offset = questions.length;
          _hasMore = questions.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(QuestionModel question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السؤال'),
        content: const Text('هل أنت متأكد من حذف هذا السؤال؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteQuestion(question.id);
        setState(() {
          _questions.removeWhere((q) => q.id == question.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف السؤال بنجاح'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting question: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأسئلة'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddQuestionPage()),
          );
          if (result == true) {
            _filterByCategory(_selectedCategoryId); // Reload
          }
        },
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('إضافة سؤال'),
      ),
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
        child: Column(
          children: [
            // Category Filter
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.2),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('الكل'),
                    selected: _selectedCategoryId == null,
                    onSelected: (selected) => _filterByCategory(null),
                    checkmarkColor: Colors.white,
                    selectedColor: Colors.amber,
                    labelStyle: TextStyle(
                      color: _selectedCategoryId == null ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                  ..._categories.map((category) {
                    return FilterChip(
                      label: Text(category.nameAr),
                      selected: _selectedCategoryId == category.id,
                      onSelected: (selected) => _filterByCategory(selected ? category.id : null),
                      checkmarkColor: Colors.white,
                      selectedColor: Colors.amber,
                      labelStyle: TextStyle(
                        color: _selectedCategoryId == category.id ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Questions List
            Expanded(
              child: _isLoading && _questions.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _questions.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد أسئلة',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _questions.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              );
                            }

                            final question = _questions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Colors.black.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  question.question,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getDifficultyColor(question.difficulty).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _getDifficultyColor(question.difficulty)),
                                          ),
                                          child: Text(
                                            _getDifficultyLabel(question.difficulty),
                                            style: TextStyle(
                                              color: _getDifficultyColor(question.difficulty),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (question.mediaType != null && question.mediaType != 'none')
                                          Icon(
                                            _getMediaIcon(question.mediaType!),
                                            color: Colors.blue.shade300,
                                            size: 16,
                                          ),
                                          ],
                                    ),
                                    if (question.mediaType == 'image' && question.mediaUrl != null && question.mediaUrl!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            question.mediaUrl!,
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const SizedBox(
                                                  height: 120,
                                                  child: Center(
                                                    child: Icon(Icons.broken_image, color: Colors.white54),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditQuestionPage(
                                              question: question,
                                              // reportUserId is null for direct edits
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          _filterByCategory(_selectedCategoryId); // Reload
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteQuestion(question),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.amber;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'سهل';
      case 'medium':
        return 'متوسط';
      case 'hard':
        return 'صعب';
      default:
        return difficulty;
    }
  }

  IconData _getMediaIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.attach_file;
    }
  }
}
