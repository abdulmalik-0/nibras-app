import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_page.dart';
import 'subscription_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUserDetails();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'هل أنت متأكد أنك تريد حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه وسيتم حذف جميع بياناتك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _authService.deleteAccount();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الحساب بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${e.toString()}')),
          );
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        height: double.infinity,
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 60, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 24),
                    if (_user != null) ...[
                      _buildInfoCard('الاسم', '${_user!.firstName} ${_user!.lastName}'),
                      const SizedBox(height: 16),
                      _buildInfoCard('اسم المستخدم', _user!.username),
                      const SizedBox(height: 16),
                      _buildInfoCard('البريد الإلكتروني', _user!.email),
                      const SizedBox(height: 24),

                      // Subscription Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _user!.isVip ? Colors.amber.withOpacity(0.5) : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _user!.isVip ? Icons.diamond : Icons.stars,
                                  color: _user!.isVip ? Colors.amber : Colors.grey,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _user!.isVip ? 'عضوية VIP نشطة' : 'عضوية مجانية',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _user!.isVip ? Colors.amber : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (_user!.isVip && _user!.subscriptionEndDate != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'ينتهي الاشتراك في: ${_formatDate(_user!.subscriptionEndDate!)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                            if (!_user!.isVip) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SubscriptionPage()),
                                  );
                                  if (result == true) {
                                    _loadUserData(); // Refresh profile if subscribed
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'ترقية إلى VIP',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      _buildInfoCard('الأسئلة المجابة', '${_user!.questionsAnsweredCount}'),
                      const SizedBox(height: 32),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isDeleting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_forever),
                                  SizedBox(width: 8),
                                  Text('حذف الحساب', style: TextStyle(fontSize: 18)),
                                ],
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

  Widget _buildInfoCard(String label, String value) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
