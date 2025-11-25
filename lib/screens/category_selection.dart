import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import 'team_setup.dart';

class CategorySelection extends StatefulWidget {
  const CategorySelection({super.key});

  @override
  State<CategorySelection> createState() => _CategorySelectionState();
}

class _CategorySelectionState extends State<CategorySelection> {
  final Set<String> _selectedCategories = {};
  
  // Helper to get icon data from string name
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'lightbulb': return Icons.lightbulb_rounded;
      case 'science': return Icons.science_rounded;
      case 'public': return Icons.public_rounded;
      case 'history_edu': return Icons.history_edu_rounded;
      case 'sports_soccer': return Icons.sports_soccer_rounded;
      case 'theater_comedy': return Icons.theater_comedy_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'directions_car': return Icons.directions_car_rounded;
      case 'star': return Icons.star_rounded;
      case 'flag': return Icons.flag_rounded;
      case 'location_city': return Icons.location_city_rounded;
      case 'format_quote': return Icons.format_quote_rounded;
      case 'calculate': return Icons.calculate_rounded;
      case 'movie': return Icons.movie_rounded;
      case 'live_tv': return Icons.live_tv_rounded;
      case 'animation': return Icons.animation_rounded;
      case 'sports_esports': return Icons.sports_esports_rounded;
      default: return Icons.category_rounded;
    }
  }

  // Helper to get color from string hex or predefined map
  Color _getColor(String? colorHex, int index) {
    if (colorHex != null && colorHex.startsWith('#')) {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    }
    
    // Fallback colors
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.teal,
      Colors.brown,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        if (_selectedCategories.length < 6) {
          _selectedCategories.add(categoryId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يمكنك اختيار 6 فئات كحد أقصى')),
          );
        }
      }
    });
  }

  Future<Map<String, int>> _getCategoryProgress(String categoryId) async {
    final supabaseService = SupabaseService();
    final authService = AuthService();
    final userId = authService.currentUser?.id;
    
    if (userId == null) {
      return {'total': 0, 'answered': 0, 'remaining': 0};
    }

    final total = await supabaseService.getCategoryQuestionCount(categoryId);
    final answered = await supabaseService.getUserAnsweredCountInCategory(userId, categoryId);
    final remaining = total - answered;

    return {
      'total': total,
      'answered': answered,
      'remaining': remaining > 0 ? remaining : 0,
    };
  }

  Future<void> _resetCategoryProgress(String categoryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين التقدم'),
        content: const Text('هل أنت متأكد من حذف جميع إجاباتك في هذا القسم؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authService = AuthService();
        final userId = authService.currentUser?.id;
        if (userId != null) {
          await SupabaseService().resetCategoryProgress(userId, categoryId);
          setState(() {}); // Refresh UI
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إعادة تعيين التقدم بنجاح'), backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting progress: $e')),
          );
        }
      }
    }
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          iconSize: 28,
                        ),
                        const Expanded(
                          child: Text(
                            'اختر الفئات',
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
                      'اختر من 1 إلى 6 فئات',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Categories Grid
              Expanded(
                child: FutureBuilder<List<CategoryModel>>(
                  future: SupabaseService().getCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    final categories = snapshot.data ?? [];

                    if (categories.isEmpty) {
                      return const Center(child: Text('No categories found', style: TextStyle(color: Colors.white)));
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Center(
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: List.generate(categories.length, (index) {
                            final category = categories[index];
                            
                            final icon = _getIconData(category.icon);
                            final color = _getColor(category.color, index); 
                            final isSelected = _selectedCategories.contains(category.id);
                            
                            return GestureDetector(
                              onTap: () => _toggleCategory(category.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            color.withOpacity(0.8),
                                            color,
                                          ],
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? color : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected 
                                          ? color.withOpacity(0.4)
                                          : Colors.black.withOpacity(0.08),
                                      blurRadius: isSelected ? 15 : 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Remaining questions badge at top
                                        FutureBuilder<Map<String, int>>(
                                          future: _getCategoryProgress(category.id),
                                          builder: (context, progressSnapshot) {
                                            if (progressSnapshot.hasData) {
                                              final remaining = progressSnapshot.data!['remaining'] ?? 0;
                                              final total = progressSnapshot.data!['total'] ?? 0;
                                              
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isSelected 
                                                      ? Colors.white.withOpacity(0.2)
                                                      : color.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'متبقي: $remaining/$total',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected ? Colors.white : color,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox(height: 20);
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Center(
                                          child: Icon(
                                            icon,
                                            size: 50,
                                            color: isSelected ? Colors.white : color,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Center(
                                            child: Text(
                                              category.nameAr,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.refresh, size: 20),
                                        color: isSelected ? Colors.white70 : Colors.grey.shade400,
                                        onPressed: () => _resetCategoryProgress(category.id),
                                        tooltip: 'إعادة تعيين التقدم',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Continue Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedOpacity(
                  opacity: _selectedCategories.isNotEmpty ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _selectedCategories.isNotEmpty
                          ? LinearGradient(
                              colors: [
                                Colors.amber.shade400,
                                Colors.orange.shade600,
                              ],
                            )
                          : null,
                      color: _selectedCategories.isEmpty ? Colors.grey.shade600 : null,
                      boxShadow: _selectedCategories.isNotEmpty
                          ? [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _selectedCategories.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamSetup(
                                    selectedCategories: _selectedCategories.toList(),
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'متابعة (${_selectedCategories.length})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Fixed text color
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 24, color: Colors.white), // Fixed icon color
                        ],
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
  }
}
