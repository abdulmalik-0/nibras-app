import 'package:flutter/material.dart';
import 'package:nibras_app/models/user_model.dart';
import 'package:nibras_app/screens/admin_dashboard_page.dart';
import 'package:nibras_app/screens/category_management_page.dart';
import 'package:nibras_app/screens/question_management_page.dart';
import 'package:nibras_app/screens/reported_questions_page.dart';
import 'package:nibras_app/screens/user_management_page.dart';
import 'package:nibras_app/services/auth_service.dart';
import 'package:nibras_app/screens/profile_page.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const AdminLayout({
    super.key,
    required this.child,
    this.title = '',
    this.actions,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final _authService = AuthService();
  bool _isSidebarCollapsed = false;
  bool _isSuperAdmin = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUserDetails();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isSuperAdmin = user?.isSuperAdmin ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151521),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF151521),
              const Color(0xFF1E1E2D),
              Colors.deepPurple.shade900.withOpacity(0.2),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
            ),
            _buildSidebar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSidebarCollapsed ? 70 : 250,
      color: const Color(0xFF1E1E2D),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Row(
            children: [
              const SizedBox(
                width: 70,
                child: Center(
                  child: Icon(Icons.rocket_launch, color: Colors.blueAccent, size: 28),
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isSidebarCollapsed ? 0.0 : 1.0,
                  child: _isSidebarCollapsed
                      ? const SizedBox()
                      : const Text(
                          'Nibras Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(context, 'لوحة التحكم', Icons.dashboard, widget.child is AdminDashboardPage, () {
            if (widget.child is! AdminDashboardPage) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
            }
          }),
          _buildSidebarItem(context, 'الأسئلة', Icons.quiz, widget.child is QuestionManagementPage, () {
            if (widget.child is! QuestionManagementPage) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const QuestionManagementPage()));
            }
          }),
          _buildSidebarItem(context, 'البلاغات', Icons.report_problem, widget.child is ReportedQuestionsPage, () {
            if (widget.child is! ReportedQuestionsPage) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReportedQuestionsPage()));
            }
          }),
          if (_isSuperAdmin) ...[
            if (!_isSidebarCollapsed)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('الإدارة العليا', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              )
            else 
              const SizedBox(height: 24),
            _buildSidebarItem(context, 'المستخدمين', Icons.people, widget.child is UserManagementPage, () {
              if (widget.child is! UserManagementPage) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserManagementPage()));
              }
            }),
            _buildSidebarItem(context, 'الفئات', Icons.category, widget.child is CategoryManagementPage, () {
              if (widget.child is! CategoryManagementPage) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CategoryManagementPage()));
              }
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title, IconData icon, bool isActive, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: isActive
              ? BoxDecoration(
                  border: const Border(right: BorderSide(color: Colors.blueAccent, width: 4)),
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent.withOpacity(0.1), Colors.transparent],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                )
              : null,
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Center(
                  child: Icon(icon, color: isActive ? Colors.blueAccent : Colors.grey, size: 20),
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isSidebarCollapsed ? 0.0 : 1.0,
                  child: _isSidebarCollapsed
                      ? const SizedBox()
                      : Text(
                          title,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFF1E1E2D),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              backgroundImage: _currentUser?.avatarUrl != null 
                  ? NetworkImage(_currentUser!.avatarUrl!) 
                  : null,
              child: _currentUser?.avatarUrl == null 
                  ? const Icon(Icons.person, color: Colors.white) 
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (widget.actions != null) ...widget.actions!,
          const SizedBox(width: 24),
          if (widget.title.isNotEmpty)
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (widget.title.isEmpty)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151521),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'بحث...',
                    hintStyle: TextStyle(color: Colors.grey),
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
            ),
          if (widget.title.isNotEmpty) const Spacer(),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
        ],
      ),
    );
  }
}
