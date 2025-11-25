import 'package:flutter/material.dart';
import 'quiz_page.dart';

class TeamSetup extends StatefulWidget {
  final List<String> selectedCategories;
  
  const TeamSetup({super.key, required this.selectedCategories});

  @override
  State<TeamSetup> createState() => _TeamSetupState();
}

class _TeamSetupState extends State<TeamSetup> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  void _addTeam() {
    if (_controllers.length < 4) {
      setState(() {
        _controllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحد الأقصى 4 فرق'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeTeam(int index) {
    if (_controllers.length > 2) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            iconSize: 28,
                          ),
                          const Expanded(
                            child: Text(
                              'إعداد الفرق',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل أسماء الفرق (2-4 فرق)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Teams List
                      Expanded(
                        child: ListView.builder(
                          itemCount: _controllers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _controllers[index],
                                        decoration: InputDecoration(
                                          labelText: 'فريق ${index + 1}',
                                          labelStyle: TextStyle(
                                            fontSize: 18,
                                            color: Colors.deepPurple.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          hintText: 'أدخل اسم الفريق',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.groups_rounded,
                                            color: Colors.deepPurple.shade400,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.all(20),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        validator: index < 2
                                            ? (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'يجب إدخال اسم الفريق';
                                                }
                                                return null;
                                              }
                                            : null,
                                      ),
                                    ),
                                    if (index >= 2)
                                      IconButton(
                                        onPressed: () => _removeTeam(index),
                                        icon: const Icon(Icons.close_rounded),
                                        color: Colors.red.shade400,
                                        iconSize: 28,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Add Team Button
                      if (_controllers.length < 4)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutlinedButton.icon(
                            onPressed: _addTeam,
                            icon: const Icon(Icons.add_rounded, size: 24),
                            label: const Text(
                              'إضافة فريق',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Start Button
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
                          onPressed: _startQuiz,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'بدء المسابقة',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz() {
    if (_formKey.currentState!.validate()) {
      // Get team names from controllers
      final validTeams = _controllers
          .map((controller) => controller.text.trim())
          .where((name) => name.isNotEmpty)
          .toList();
      
      if (validTeams.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إدخال اسم فريقين على الأقل')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            selectedCategories: widget.selectedCategories,
            teams: validTeams,
            showOptions: false,
          ),
        ),
      );
    }
  }
}
