import 'package:flutter/material.dart';
import 'category_selection.dart';
import 'reported_questions_page.dart';
import 'user_management_page.dart';
import 'question_management_page.dart';
import 'category_management_page.dart';
import 'profile_page.dart';
import 'admin_dashboard_page.dart';
import '../services/auth_service.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = await _authService.getUserDetails();
    if (mounted && user != null) {
      setState(() {
        _isAdmin = user.isAdmin;
        _isSuperAdmin = user.isSuperAdmin;
      });
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
          child: Stack(
            children: [
              // Main Content
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        
                        // App Title with glow effect
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'نبراس',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.purple.shade300,
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'مسابقة المعرفة الكبرى',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Quiz Icon with animation
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.shade300.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            size: 100,
                            color: Colors.amber,
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Start Button
                        Container(
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CategorySelection(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 32),
                                SizedBox(width: 12),
                                Text(
                                  'ابدأ اللعبة',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        if (_isAdmin || _isSuperAdmin) ...[
                          const SizedBox(height: 24),

                          // Admin Dashboard Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.blueGrey.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.blueGrey.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminDashboardPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.dashboard, size: 24, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text(
                                    'لوحة التحكم',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                        
                        // Footer text
                        Text(
                          'اختبر معلوماتك في مختلف المجالات',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Profile Button (Positioned at Top Right)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
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
