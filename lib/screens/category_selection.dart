import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import 'team_setup.dart';
import 'subscription_page.dart';

class CategorySelection extends StatefulWidget {
  const CategorySelection({super.key});

  @override
  State<CategorySelection> createState() => _CategorySelectionState();
}

class _CategorySelectionState extends State<CategorySelection> {
  final Set<String> _selectedCategories = {};
  bool _isVip = false;
  UserModel? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _checkVipStatus();
  }

  Future<void> _checkVipStatus() async {
    final authService = AuthService();
    final supabaseService = SupabaseService();
    final userId = authService.currentUser?.id;
    
    if (userId != null) {
      final user = await supabaseService.getUser(userId);
      if (mounted && user != null) {
        setState(() {
          _user = user;
          _isVip = user.hasActiveVip;
          _isLoadingUser = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }
  
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
      Colors.pink,
      Colors.cyan,
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

  Future<void> _showFreeTrialDialog(CategoryModel category) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.green),
            SizedBox(width: 8),
            Text('تجربة مجانية'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يمكنك تجربة قسم "${category.nameAr}" مجانًا مرة واحدة اليوم.',
            ),
            const SizedBox(height: 16),
            const Text(
              'أو اشترك الآن للوصول غير المحدود!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'subscribe'),
            style: TextButton.styleFrom(foregroundColor: Colors.amber.shade800),
            child: const Text('اشتراك VIP'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'trial'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('ابدأ التجربة'),
          ),
        ],
      ),
    );

    if (result == 'subscribe') {
      if (mounted) {
        final subscribed = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionPage()),
        );
        
        if (subscribed == true) {
          _checkVipStatus(); // Refresh status
        }
      }
    } else if (result == 'trial') {
      try {
        await SupabaseService().useFreeTrial(_user!.uid, category.id);
        await _checkVipStatus(); // Refresh user data to update trial usage
        _toggleCategory(category.id); // Auto-select after trial activation
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تفعيل التجربة المجانية لهذا القسم!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
  }

  Future<void> _showSubscriptionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 8),
            Text('محتوى VIP'),
          ],
        ),
        content: const Text(
          'هذا القسم متاح فقط لمشتركي VIP. اشترك الآن للوصول إلى جميع الأقسام والمميزات الحصرية!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('اشترك الآن'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final subscribed = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionPage()),
      );
      
      if (subscribed == true) {
        _checkVipStatus(); // Refresh status
      }
    }
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
                        if (!_isVip)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.5)),
                            ),
                            child: IconButton(
                              onPressed: _showSubscriptionDialog,
                              icon: const Icon(Icons.diamond_outlined, color: Colors.amber),
                              tooltip: 'اشتراك VIP',
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isVip ? 'أهلاً بك في عضوية VIP - جميع الفئات متاحة' : 'اختر من 1 إلى 6 فئات',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isVip ? Colors.amber : Colors.white.withOpacity(0.8),
                        fontWeight: _isVip ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (_isVip && _user != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _user!.isSuperAdmin 
                              ? '(Super Admin)' 
                              : (_user!.subscriptionEndDate != null 
                                  ? 'ينتهي في: ${_formatDate(_user!.subscriptionEndDate!)}' 
                                  : '(VIP دائم)'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Categories Grid
              Expanded(
                child: _isLoadingUser 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : FutureBuilder<List<CategoryModel>>(
                  future: SupabaseService().getCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    var categories = snapshot.data ?? [];
                    
                    // Filter categories based on visibility
                    if (_user != null && _user!.isAdmin) {
                      // Admins see everything
                    } else if (_isVip) {
                      // VIPs see public, vip_only, and hidden_for_regular
                      // Hide hidden_for_all
                      categories = categories.where((c) => !c.isHiddenForAll).toList();
                    } else {
                      // Regular users see public and vip_only (locked)
                      // Hide hidden_for_regular and hidden_for_all
                      categories = categories.where((c) => !c.isHiddenForRegular && !c.isHiddenForAll).toList();
                    }
                    
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
                            
                            // Lock logic: Locked if it's VIP only AND user is not VIP
                            // Note: "hidden_for_regular" is visible to VIPs, so it behaves like public for them.
                            // But if a regular user somehow sees it (shouldn't happen due to filter), it should probably be locked?
                            // Actually, if it's hidden, they don't see it.
                            // "vip_only" means visible to all but locked for regular.
                            
                            final isLocked = category.isVipOnly && !_isVip;
                            final hasUsedTrial = _user?.hasUsedFreeTrialToday(category.id) ?? false;
                            final canUseTrial = isLocked && !hasUsedTrial;
                            
                            return GestureDetector(
                              onTap: () {
                                if (isLocked) {
                                  if (canUseTrial) {
                                    _showFreeTrialDialog(category);
                                  } else {
                                    _showSubscriptionDialog();
                                  }
                                } else {
                                  _toggleCategory(category.id);
                                }
                              },
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
                                  color: isSelected ? null : (isLocked && !canUseTrial ? Colors.grey.shade300 : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? color : (canUseTrial ? Colors.green : Colors.grey.shade300),
                                    width: canUseTrial ? 3 : 2,
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
                                            isLocked && !canUseTrial ? Icons.lock : icon,
                                            size: 50,
                                            color: isLocked && !canUseTrial ? Colors.grey : (isSelected ? Colors.white : color),
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
                                                color: isLocked && !canUseTrial ? Colors.grey.shade600 : (isSelected ? Colors.white : Colors.black87),
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
                                    if (category.isVipOnly)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: canUseTrial ? Colors.green : Colors.amber,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: canUseTrial 
                                            ? const Text('تجربة مجانية', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                            : const Icon(
                                                Icons.diamond,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                        ),
                                      ),
                                    if (category.isHiddenForRegular)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.visibility_off, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    if (category.isHiddenForAll)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.lock_outline, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    if (!isLocked)
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
  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final year = localDate.year;
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
