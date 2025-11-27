class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final DateTime createdAt;
  final bool _isAdmin;
  final bool isSuperAdmin;
  final bool isVip;
  final DateTime? subscriptionEndDate;
  final String? subscriptionPlan;
  final int questionsAnsweredCount;
  final int reportsMadeCount;
  final int validReportsCount;
  final int invalidReportsCount;
  final int resolvedReportsCount;
  final Map<String, DateTime> freeTrialUsage;
  final String? avatarUrl;

  bool get isAdmin => isSuperAdmin || _isAdmin;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.createdAt,
    bool isAdmin = false,
    this.isSuperAdmin = false,
    this.isVip = false,
    this.subscriptionEndDate,
    this.subscriptionPlan,
    this.questionsAnsweredCount = 0,
    this.reportsMadeCount = 0,
    this.validReportsCount = 0,
    this.invalidReportsCount = 0,
    this.resolvedReportsCount = 0,
    this.freeTrialUsage = const {},
    this.avatarUrl,
  }) : _isAdmin = isAdmin;

  // Calculate report accuracy percentage (0-100)
  double get reportAccuracy {
    final total = validReportsCount + invalidReportsCount;
    if (total == 0) return 0.0;
    return (validReportsCount / total) * 100;
  }

  // Check if user has active VIP subscription or is manually set as VIP
  bool get hasActiveVip {
    if (isSuperAdmin) return true;
    
    // If the VIP flag is manually turned off, they are NOT VIP (even if they have a date)
    if (!isVip) return false;
    
    // If isVip is TRUE, we check if the subscription has expired
    if (subscriptionEndDate != null) {
      return subscriptionEndDate!.isAfter(DateTime.now());
    }
    
    // isVip is TRUE and no date -> Permanent VIP
    return true;
  }

  // Check if user has used free trial for a category today
  bool hasUsedFreeTrialToday(String categoryId) {
    if (!freeTrialUsage.containsKey(categoryId)) return false;
    
    final lastUsed = freeTrialUsage[categoryId]!;
    final now = DateTime.now();
    
    return lastUsed.year == now.year && 
           lastUsed.month == now.month && 
           lastUsed.day == now.day;
  }

  factory UserModel.fromSupabase(Map<String, dynamic> data) {
    Map<String, DateTime> trials = {};
    if (data['free_trial_usage'] != null) {
      final map = data['free_trial_usage'] as Map<String, dynamic>;
      map.forEach((key, value) {
        if (value is String) {
          final date = DateTime.tryParse(value);
          if (date != null) {
            trials[key] = date;
          }
        }
      });
    }

    return UserModel(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      username: data['username'] ?? '',
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      isAdmin: data['is_admin'] ?? false,
      isSuperAdmin: data['is_super_admin'] ?? false,
      isVip: data['is_vip'] ?? false,
      subscriptionEndDate: data['subscription_end_date'] != null 
          ? DateTime.tryParse(data['subscription_end_date']) 
          : null,
      subscriptionPlan: data['subscription_plan'],
      questionsAnsweredCount: data['questions_answered_count'] ?? 0,
      reportsMadeCount: data['reports_made_count'] ?? 0,
      validReportsCount: data['valid_reports_count'] ?? 0,
      invalidReportsCount: data['invalid_reports_count'] ?? 0,
      resolvedReportsCount: data['resolved_reports_count'] ?? 0,
      freeTrialUsage: trials,
      avatarUrl: data['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, String> trialsMap = {};
    freeTrialUsage.forEach((key, value) {
      trialsMap[key] = value.toIso8601String();
    });

    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'isVip': isVip,
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'subscriptionPlan': subscriptionPlan,
      'questionsAnsweredCount': questionsAnsweredCount,
      'reportsMadeCount': reportsMadeCount,
      'validReportsCount': validReportsCount,
      'invalidReportsCount': invalidReportsCount,
      'resolvedReportsCount': resolvedReportsCount,
      'freeTrialUsage': trialsMap,
      'avatar_url': avatarUrl,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    DateTime? createdAt,
    bool? isAdmin,
    bool? isSuperAdmin,
    bool? isVip,
    DateTime? subscriptionEndDate,
    String? subscriptionPlan,
    int? questionsAnsweredCount,
    int? reportsMadeCount,
    int? validReportsCount,
    int? invalidReportsCount,
    int? resolvedReportsCount,
    Map<String, DateTime>? freeTrialUsage,
    String? avatarUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isVip: isVip ?? this.isVip,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      questionsAnsweredCount: questionsAnsweredCount ?? this.questionsAnsweredCount,
      reportsMadeCount: reportsMadeCount ?? this.reportsMadeCount,
      validReportsCount: validReportsCount ?? this.validReportsCount,
      invalidReportsCount: invalidReportsCount ?? this.invalidReportsCount,
      resolvedReportsCount: resolvedReportsCount ?? this.resolvedReportsCount,
      freeTrialUsage: freeTrialUsage ?? this.freeTrialUsage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
