import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class EditQuestionPage extends StatefulWidget {
  final QuestionModel question;
  final String? reportUserId;

  const EditQuestionPage({
    super.key,
    required this.question,
    this.reportUserId,
  });

  @override
  State<EditQuestionPage> createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends State<EditQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  final _authService = AuthService();
  final _storageService = StorageService(); // Add this

  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  late TextEditingController _mediaUrlController;

  int _correctAnswerIndex = 0;
  String? _selectedMediaType; // 'image', 'video', 'audio', or null
  String _selectedDifficulty = 'medium'; // 'easy', 'medium', 'hard'
  bool _isLoading = false;

  // Add this method
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

  @override
  void initState() {
    super.initState();
    
    _questionController = TextEditingController(text: widget.question.question);
    _optionControllers = widget.question.options
        .map((option) => TextEditingController(text: option))
        .toList();
    _mediaUrlController = TextEditingController(text: widget.question.mediaUrl ?? '');
    
    // Find correct answer index
    _correctAnswerIndex = widget.question.options.indexOf(widget.question.correctAnswer);
    if (_correctAnswerIndex == -1) _correctAnswerIndex = 0;
    
    // Set media type
    _selectedMediaType = widget.question.mediaType == 'none' ? null : widget.question.mediaType;
    
    // Set difficulty
    _selectedDifficulty = widget.question.difficulty;
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

  Future<void> _saveAndResolve() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final adminId = _authService.currentUser?.id ?? '';
      
      // Prepare updated question data
      final updatedData = {
        'question': _questionController.text.trim(),
        'options': _optionControllers.map((c) => c.text.trim()).toList(),
        'correct_answer': _optionControllers[_correctAnswerIndex].text.trim(),
        'difficulty': _selectedDifficulty,
        'media_type': _selectedMediaType ?? 'none',
        'media_url': _selectedMediaType != null ? _mediaUrlController.text.trim() : null,
      };

      // Update question in Supabase
      await _supabaseService.updateQuestion(widget.question.id, updatedData);

      // Resolve ALL pending reports for this question as valid
      // This assumes that if an admin edits a question, they are fixing the reported issue
      await _supabaseService.resolveAllReportsForQuestion(
        widget.question.id,
        true, // isValid
        adminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.reportUserId != null 
                ? 'تم تحديث السؤال وتسجيل البلاغ كصحيح' 
                : 'تم تحديث السؤال بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'حدث خطأ: $e';
        if (e.toString().contains("Could not find the 'media_type' column")) {
          errorMessage = 'خطأ في قاعدة البيانات: عمود "media_type" غير موجود. يرجى التحقق من هيكل قاعدة البيانات.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل السؤال'),
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
              // Question ID
              Card(
                color: Colors.black.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'ID: ${widget.question.id}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
                'الخيارات:',
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

              // Media Type Selection
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
                      // Image Selection
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

                      if (_selectedMediaType == 'image') ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              // Upload Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: const Text('رفع صورة من الجهاز'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.white24)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('أو ضع رابط مباشر', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                    ),
                                    Expanded(child: Divider(color: Colors.white24)),
                                  ],
                                ),
                              ),

                              // URL Field
                              _buildTextField(
                                controller: _mediaUrlController,
                                label: 'رابط الصورة',
                                validator: (value) {
                                  if (_selectedMediaType == 'image' && (value == null || value.trim().isEmpty)) {
                                    return 'الرجاء رفع صورة أو إدخال رابط';
                                  }
                                  return null;
                                },
                              ),
                              
                              // Preview
                              if (_mediaUrlController.text.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _mediaUrlController.text,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 100,
                                          width: double.infinity,
                                          color: Colors.grey.shade800,
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image, color: Colors.white54),
                                              SizedBox(height: 4),
                                              Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.white54)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() => _mediaUrlController.clear()),
                                      icon: const CircleAvatar(
                                        backgroundColor: Colors.red,
                                        radius: 12,
                                        child: Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Video Selection
                      CheckboxListTile(
                        title: const Text('مقطع فيديو (رابط)', style: TextStyle(color: Colors.white)),
                        value: _selectedMediaType == 'video',
                        onChanged: (value) {
                          setState(() {
                            _selectedMediaType = value! ? 'video' : null;
                            if (!value) _mediaUrlController.clear();
                          });
                        },
                        activeColor: Colors.green,
                      ),

                      // Audio Selection
                      CheckboxListTile(
                        title: const Text('مقطع صوتي (رابط)', style: TextStyle(color: Colors.white)),
                        value: _selectedMediaType == 'audio',
                        onChanged: (value) {
                          setState(() {
                            _selectedMediaType = value! ? 'audio' : null;
                            if (!value) _mediaUrlController.clear();
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      
                      // Text Field for Video/Audio URL
                      if (_selectedMediaType == 'video' || _selectedMediaType == 'audio') ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _buildTextField(
                            controller: _mediaUrlController,
                            label: 'رابط ${_getMediaTypeLabel()}',
                            validator: (value) {
                              if (_selectedMediaType != null && (value == null || value.trim().isEmpty)) {
                                return 'الرجاء إدخال الرابط';
                              }
                              return null;
                            },
                          ),
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
                      DropdownMenuItem(
                        value: 'easy',
                        child: Text('سهل 🟢'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('متوسط 🟡'),
                      ),
                      DropdownMenuItem(
                        value: 'hard',
                        child: Text('صعب 🔴'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDifficulty = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAndResolve,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.reportUserId != null 
                            ? 'حفظ التعديلات وتسجيل البلاغ كصحيح' 
                            : 'حفظ التعديلات',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontSize: 16),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }

  String _getMediaTypeLabel() {
    switch (_selectedMediaType) {
      case 'image':
        return 'الصورة';
      case 'video':
        return 'الفيديو';
      case 'audio':
        return 'الصوت';
      default:
        return '';
    }
  }
}
