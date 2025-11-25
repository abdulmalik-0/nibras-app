import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({super.key});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  final _storageService = StorageService();

  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  late TextEditingController _mediaUrlController;

  int _correctAnswerIndex = 0;
  String? _selectedMediaType;
  String _selectedDifficulty = 'medium';
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _optionControllers = List.generate(4, (_) => TextEditingController());
    _mediaUrlController = TextEditingController();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _supabaseService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _mediaUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _storageService.pickImage();
      if (image != null) {
        setState(() => _isLoading = true);
        final imageUrl = await _storageService.uploadImage(image);
        if (imageUrl != null) {
          setState(() {
            _mediaUrlController.text = imageUrl;
            _selectedMediaType = 'image';
          });
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار القسم')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newQuestionData = {
        'question': _questionController.text.trim(),
        'options': _optionControllers.map((c) => c.text.trim()).toList(),
        'correct_answer': _optionControllers[_correctAnswerIndex].text.trim(),
        'category_id': _selectedCategoryId,
        'difficulty': _selectedDifficulty,
        'media_type': _selectedMediaType ?? 'none',
        'media_url': _selectedMediaType != null ? _mediaUrlController.text.trim() : null,
        'language': 'ar',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabaseService.createQuestion(newQuestionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة السؤال بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة سؤال جديد'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Category Selection
              const Text(
                'القسم:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.black.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    dropdownColor: Colors.deepPurple.shade800,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.category, color: Colors.amber),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.nameAr),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    validator: (value) => value == null ? 'الرجاء اختيار القسم' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Question Text
              _buildTextField(
                controller: _questionController,
                label: 'نص السؤال',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال نص السؤال';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Options
              const Text(
                'الخيارات (حدد الإجابة الصحيحة):',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctAnswerIndex,
                        onChanged: (value) {
                          setState(() => _correctAnswerIndex = value!);
                        },
                        activeColor: Colors.green,
                      ),
                      Expanded(
                        child: _buildTextField(
                          controller: _optionControllers[index],
                          label: 'الخيار ${index + 1}',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'الرجاء إدخال الخيار';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Media Type Selection (Reused Logic)
              const Text(
                'الوسائط (اختياري):',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.black.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (_selectedMediaType == 'image') ...[
                        if (_mediaUrlController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _mediaUrlController.text,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: Icon(Icons.error, color: Colors.red),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text('اختر صورة من الجهاز'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (_mediaUrlController.text.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _mediaUrlController.clear();
                                  });
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      CheckboxListTile(
                        title: const Text('صورة', style: TextStyle(color: Colors.white)),
                        value: _selectedMediaType == 'image',
                        onChanged: (value) {
                          setState(() {
                            _selectedMediaType = value! ? 'image' : null;
                            if (!value) _mediaUrlController.clear();
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      CheckboxListTile(
                        title: const Text('مقطع فيديو (رابط)', style: TextStyle(color: Colors.white)),
                        value: _selectedMediaType == 'video',
                        onChanged: (value) {
                          setState(() {
                            _selectedMediaType = value! ? 'video' : null;
                            _mediaUrlController.clear();
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      CheckboxListTile(
                        title: const Text('مقطع صوتي (رابط)', style: TextStyle(color: Colors.white)),
                        value: _selectedMediaType == 'audio',
                        onChanged: (value) {
                          setState(() {
                            _selectedMediaType = value! ? 'audio' : null;
                            _mediaUrlController.clear();
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      if (_selectedMediaType != null && _selectedMediaType != 'image') ...[
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _mediaUrlController,
                          label: 'رابط الوسائط',
                          validator: (value) {
                            if (_selectedMediaType != null && (value == null || value.trim().isEmpty)) {
                              return 'الرجاء إدخال الرابط';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Difficulty Selection
              const Text(
                'مستوى الصعوبة:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.black.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    dropdownColor: Colors.deepPurple.shade800,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.speed, color: Colors.amber),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('سهل 🟢')),
                      DropdownMenuItem(value: 'medium', child: Text('متوسط 🟡')),
                      DropdownMenuItem(value: 'hard', child: Text('صعب 🔴')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedDifficulty = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'إضافة السؤال',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
