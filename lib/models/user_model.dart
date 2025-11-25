class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final DateTime createdAt;
  final bool isAdmin;
  final bool isSuperAdmin;
  final int questionsAnsweredCount;
  final int reportsMadeCount;
  final int validReportsCount;
  final int invalidReportsCount;
  final int resolvedReportsCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.createdAt,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.questionsAnsweredCount = 0,
    this.reportsMadeCount = 0,
    this.validReportsCount = 0,
    this.invalidReportsCount = 0,
    this.resolvedReportsCount = 0,
  });

  // Calculate report accuracy percentage (0-100)
  double get reportAccuracy {
    final total = validReportsCount + invalidReportsCount;
    if (total == 0) return 0.0;
    return (validReportsCount / total) * 100;
  }

  factory UserModel.fromSupabase(Map<String, dynamic> data) {
    return UserModel(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      username: data['username'] ?? '',
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      isAdmin: data['is_admin'] ?? false,
      isSuperAdmin: data['is_super_admin'] ?? false,
      questionsAnsweredCount: data['questions_answered_count'] ?? 0,
      reportsMadeCount: data['reports_made_count'] ?? 0,
      validReportsCount: data['valid_reports_count'] ?? 0,
      invalidReportsCount: data['invalid_reports_count'] ?? 0,
      resolvedReportsCount: data['resolved_reports_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'questionsAnsweredCount': questionsAnsweredCount,
      'reportsMadeCount': reportsMadeCount,
      'validReportsCount': validReportsCount,
      'invalidReportsCount': invalidReportsCount,
      'resolvedReportsCount': resolvedReportsCount,
    };
  }
}
