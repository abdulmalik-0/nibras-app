import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/supabase_service.dart';
import '../widgets/admin_layout.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _supabaseService = SupabaseService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _supabaseService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _toggleVisibility(CategoryModel category) async {
    try {
      // Cycle: public -> vip_only -> hidden_for_all -> public
      String newVisibility;
      String message;
      Color color;

      if (category.visibility == 'public') {
        newVisibility = 'vip_only';
        message = 'تم تحويل الفئة ${category.nameAr} إلى VIP فقط';
        color = Colors.amber;
      } else if (category.visibility == 'vip_only') {
        newVisibility = 'hidden_for_all';
        message = 'تم إخفاء الفئة ${category.nameAr}';
        color = Colors.red;
      } else {
        newVisibility = 'public';
        message = 'تم إظهار الفئة ${category.nameAr} للجميع';
        color = Colors.green;
      }

      await _supabaseService.updateCategoryVisibility(category.id, newVisibility);
      setState(() {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = category.copyWith(visibility: newVisibility);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating category visibility: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'إدارة الفئات',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  
                  IconData icon;
                  Color color;
                  String statusText;
                  
                  if (category.isVipOnly) {
                    icon = Icons.diamond;
                    color = Colors.amber;
                    statusText = 'VIP فقط';
                  } else if (category.isHiddenForAll) {
                    icon = Icons.visibility_off;
                    color = Colors.red;
                    statusText = 'مخفية';
                  } else {
                    icon = Icons.visibility;
                    color = Colors.green;
                    statusText = 'ظاهرة للجميع';
                  }

                  return Card(
                    color: const Color(0xFF1E1E2D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: color.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _toggleVisibility(category),
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  color: color,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category.nameAr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category.id,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
