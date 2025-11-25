import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _supabaseService = SupabaseService();
  final _authService = AuthService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final currentUser = _authService.currentUser;
    _currentUserId = currentUser?.id;
    
    final users = await _supabaseService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _toggleAdminRole(UserModel user) async {
    if (user.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تغيير صلاحيات المشرف العام')),
      );
      return;
    }

    try {
      // Optimistic update
      final newStatus = !user.isAdmin;
      await _supabaseService.updateUserRole(user.uid, newStatus, user.isSuperAdmin);
      
      setState(() {
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index != -1) {
          // Create new user object with updated role to refresh UI
          // We can't use copyWith because we didn't define it, so we construct manually or reload
          // Reloading is safer to ensure consistency
        }
      });
      
      await _loadData(); // Reload to confirm

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus 
            ? 'تمت ترقية ${user.username} إلى مشرف' 
            : 'تم إلغاء صلاحية المشرف من ${user.username}'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isMe = user.uid == _currentUserId;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.black.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: user.isSuperAdmin 
                            ? Colors.amber.shade800 
                            : user.isAdmin 
                                ? Colors.red.shade100 
                                : Colors.grey.shade800,
                        child: Icon(
                          user.isSuperAdmin 
                              ? Icons.star 
                              : user.isAdmin 
                                  ? Icons.admin_panel_settings 
                                  : Icons.person,
                          color: user.isSuperAdmin 
                              ? Colors.white 
                              : user.isAdmin 
                                  ? Colors.red 
                                  : Colors.white70,
                        ),
                      ),
                      title: Text(
                        '${user.firstName} ${user.lastName} ${isMe ? '(أنت)' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${user.username}',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.quiz, size: 14, color: Colors.purple.shade300),
                              const SizedBox(width: 4),
                              Text(
                                '${user.questionsAnsweredCount}',
                                style: TextStyle(fontSize: 12, color: Colors.purple.shade200),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.report_problem, size: 14, color: Colors.orange.shade300),
                              const SizedBox(width: 4),
                              Text(
                                '${user.reportsMadeCount}',
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade200),
                              ),
                            ],
                          ),
                          if (user.validReportsCount + user.invalidReportsCount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.verified, size: 14, color: Colors.green.shade300),
                                const SizedBox(width: 4),
                                Text(
                                  'دقة البلاغات: ${user.reportAccuracy.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: user.reportAccuracy >= 70
                                        ? Colors.green.shade300
                                        : user.reportAccuracy >= 40
                                            ? Colors.orange.shade300
                                            : Colors.red.shade300,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(✓${user.validReportsCount} ✗${user.invalidReportsCount})',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ],
                          if (user.isAdmin || user.isSuperAdmin) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: Colors.blue.shade300),
                                const SizedBox(width: 4),
                                Text(
                                  'بلاغات محلولة: ${user.resolvedReportsCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade200,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: user.isSuperAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade400,
                                    Colors.orange.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'مشرف عام',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : Switch(
                              value: user.isAdmin,
                              activeColor: Colors.red,
                              onChanged: (value) => _toggleAdminRole(user),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
