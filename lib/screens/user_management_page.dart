import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../widgets/admin_layout.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _supabaseService = SupabaseService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _supabaseService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _toggleAdmin(UserModel user) async {
    try {
      await _supabaseService.updateUserRole(user.uid, !user.isAdmin, user.isSuperAdmin);
      setState(() {
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index != -1) {
          _users[index] = user.copyWith(isAdmin: !user.isAdmin);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isAdmin // Note: we just toggled it in UI but the original 'user' object is old state
                  ? 'تم إزالة صلاحيات المسؤول من ${user.username}'
                  : 'تم منح صلاحيات المسؤول لـ ${user.username}',
            ),
            backgroundColor: user.isAdmin ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user role: $e')),
        );
      }
    }
  }

  Future<void> _toggleVip(UserModel user) async {
    try {
      await _supabaseService.updateUserVipStatus(user.uid, !user.isVip);
      setState(() {
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index != -1) {
          _users[index] = user.copyWith(isVip: !user.isVip);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isVip
                  ? 'تم إزالة VIP من ${user.username}'
                  : 'تم منح VIP لـ ${user.username}',
            ),
            backgroundColor: user.isVip ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating VIP status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'إدارة المستخدمين',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: const Color(0xFF1E1E2D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: user.isSuperAdmin
                            ? Colors.amber.withOpacity(0.5)
                            : user.isAdmin
                                ? Colors.blueAccent.withOpacity(0.5)
                                : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: user.isSuperAdmin
                            ? Colors.amber
                            : user.isAdmin
                                ? Colors.blueAccent
                                : Colors.grey.shade800,
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (user.isVip) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Colors.amber, size: 16),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.email,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildRoleBadge(
                                label: 'مسؤول',
                                isActive: user.isAdmin,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              _buildRoleBadge(
                                label: 'VIP',
                                isActive: user.isVip,
                                color: Colors.amber,
                              ),
                              if (user.isSuperAdmin) ...[
                                const SizedBox(width: 8),
                                _buildRoleBadge(
                                  label: 'مسؤول فائق',
                                  isActive: true,
                                  color: Colors.redAccent,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: user.isSuperAdmin
                          ? null // Cannot edit super admin
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: user.isAdmin ? 'إزالة صلاحيات المسؤول' : 'منح صلاحيات المسؤول',
                                  icon: Icon(
                                    user.isAdmin ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined,
                                    color: user.isAdmin ? Colors.blueAccent : Colors.grey,
                                  ),
                                  onPressed: () => _toggleAdmin(user),
                                ),
                                IconButton(
                                  tooltip: user.isVip ? 'إزالة VIP' : 'منح VIP',
                                  icon: Icon(
                                    user.isVip ? Icons.star : Icons.star_border,
                                    color: user.isVip ? Colors.amber : Colors.grey,
                                  ),
                                  onPressed: () => _toggleVip(user),
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

  Widget _buildRoleBadge({required String label, required bool isActive, required Color color}) {
    if (!isActive) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
