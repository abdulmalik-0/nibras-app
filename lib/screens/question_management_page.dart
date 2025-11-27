import 'package:flutter/material.dart';
import 'dart:async';
import 'package:nibras_app/models/question_model.dart';
import 'package:nibras_app/models/category_model.dart';
import 'package:nibras_app/services/supabase_service.dart';
import 'package:nibras_app/screens/edit_question_page.dart';
import 'package:nibras_app/screens/add_question_page.dart';
import 'package:nibras_app/screens/category_management_page.dart';
import '../widgets/admin_layout.dart';

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
  String? _selectedDifficulty;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
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
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreQuestions();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
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
        difficulty: _selectedDifficulty,
        searchQuery: _searchController.text,
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

  Future<void> _applyFilters() async {
    setState(() {
      _questions = [];
      _offset = 0;
      _hasMore = true;
      _isLoading = true;
    });

    try {
      final questions = await _supabaseService.getAllQuestions(
        limit: _limit, 
        offset: 0,
        categoryId: _selectedCategoryId,
        difficulty: _selectedDifficulty,
        searchQuery: _searchController.text,
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

  Future<void> _filterByCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;
    await _applyFilters();
  }

  Future<void> _filterByDifficulty(String? difficulty) async {
    _selectedDifficulty = difficulty;
    await _applyFilters();
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
    return AdminLayout(
      title: 'إدارة الأسئلة',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddQuestionPage()),
            );
            if (result == true) {
              _applyFilters(); // Reload
            }
          },
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة سؤال'),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'بحث عن سؤال...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                  filled: true,
                  fillColor: const Color(0xFF2A2A3C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Filters Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Category Filter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          hint: const Text(
                            'كل الفئات',
                            style: TextStyle(color: Colors.white),
                          ),
                          dropdownColor: const Color(0xFF2A2A3C),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('كل الفئات', style: TextStyle(color: Colors.white)),
                            ),
                            ..._categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.nameAr, style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                          ],
                          onChanged: _filterByCategory,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Difficulty Filter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDifficulty,
                          hint: const Text(
                            'كل الصعوبات',
                            style: TextStyle(color: Colors.white),
                          ),
                          dropdownColor: const Color(0xFF2A2A3C),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.purpleAccent),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('كل الصعوبات', style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem<String>(
                              value: 'easy',
                              child: Text('سهل', style: TextStyle(color: Colors.green)),
                            ),
                            DropdownMenuItem<String>(
                              value: 'medium',
                              child: Text('متوسط', style: TextStyle(color: Colors.amber)),
                            ),
                            DropdownMenuItem<String>(
                              value: 'hard',
                              child: Text('صعب', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                          onChanged: _filterByDifficulty,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Questions List
            Expanded(
              child: _isLoading && _questions.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : _questions.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد أسئلة',
                            style: TextStyle(color: Colors.grey, fontSize: 18),
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
                                  child: CircularProgressIndicator(color: Colors.blueAccent),
                                ),
                              );
                            }

                            final question = _questions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: const Color(0xFF1E1E2D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                                            color: Colors.grey,
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
                                                    child: Icon(Icons.broken_image, color: Colors.grey),
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
                                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
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
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
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
