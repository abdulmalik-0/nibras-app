import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _supabaseService = SupabaseService();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _subscribe(String planType, String price) async {
    setState(() => _isLoading = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        await _supabaseService.subscribeUser(userId, planType);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم الاشتراك بنجاح! استمتع بمزايا VIP'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الاشتراك: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اشتراك VIP'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('جاري معالجة الاشتراك...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.diamond,
                        size: 80,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'احصل على عضوية VIP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'استمتع بالوصول الكامل لجميع الفئات والمميزات الحصرية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Monthly Plan
                      _buildPlanCard(
                        title: 'باقة شهرية',
                        price: '15',
                        currency: 'ر.س',
                        duration: '/ شهر',
                        features: ['وصول لجميع الفئات', 'بدون إعلانات', 'شارة VIP'],
                        isPopular: false,
                        onTap: () => _subscribe('monthly', '15'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Yearly Plan
                      _buildPlanCard(
                        title: 'باقة سنوية',
                        price: '60',
                        currency: 'ر.س',
                        originalPrice: '180',
                        duration: '/ سنة',
                        features: ['وصول لجميع الفئات', 'بدون إعلانات', 'شارة VIP', 'توفير 66%'],
                        isPopular: true,
                        onTap: () => _subscribe('yearly', '60'),
                      ),
                      
                      const SizedBox(height: 40),

                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String currency,
    String? originalPrice,
    required String duration,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPopular ? Border.all(color: Colors.amber, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isPopular)
              Positioned(
                top: -15,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'الأكثر طلباً',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (originalPrice != null) ...[
                        Text(
                          '$originalPrice $currency',
                          style: TextStyle(
                            fontSize: 18,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currency,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isPopular ? Colors.deepPurple : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'اشترك الآن',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPopular ? Colors.white : Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
