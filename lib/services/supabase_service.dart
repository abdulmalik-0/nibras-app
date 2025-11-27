import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/question_model.dart';
import '../models/category_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // ============================================
  // USER OPERATIONS
  // ============================================

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return UserModel.fromSupabase(response);
    } catch (e) {
      print('SupabaseService: Error getting user: $e');
      return null;
    }
  }

  /// Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((user) => UserModel.fromSupabase(user))
          .toList();
    } catch (e) {
      print('SupabaseService: Error getting all users: $e');
      return [];
    }
  }

  /// Update user role (admin/super admin)
  Future<void> updateUserRole(String userId, bool isAdmin, bool isSuperAdmin) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_admin': isAdmin,
            'is_super_admin': isSuperAdmin,
          })
          .eq('id', userId);
    } catch (e) {
      print('SupabaseService: Error updating user role: $e');
      rethrow;
    }
  }

  /// Subscribe user to a plan
  Future<void> subscribeUser(String userId, String planType) async {
    try {
      final now = DateTime.now().toUtc();
      DateTime endDate;
      
      if (planType == 'monthly') {
        endDate = now.add(const Duration(days: 30));
      } else if (planType == 'yearly') {
        endDate = now.add(const Duration(days: 365));
      } else {
        throw Exception('Invalid plan type');
      }

      await _supabase
          .from('users')
          .update({
            'is_vip': true, // Auto-enable VIP
            'subscription_plan': planType,
            'subscription_end_date': endDate.toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('SupabaseService: Error subscribing user: $e');
      rethrow;
    }
  }

  /// Update user VIP status (super admin only)
  Future<void> updateUserVipStatus(String userId, bool isVip) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_vip': isVip,
          })
          .eq('id', userId);
    } catch (e) {
      print('SupabaseService: Error updating user VIP status: $e');
      rethrow;
    }
  }

  /// Use free trial for a category
  Future<void> useFreeTrial(String userId, String categoryId) async {
    try {
      // 1. Get current usage
      final user = await getUser(userId);
      if (user == null) throw Exception('User not found');

      final Map<String, dynamic> currentUsage = {};
      user.freeTrialUsage.forEach((key, value) {
        currentUsage[key] = value.toIso8601String();
      });

      // 2. Update with new usage
      currentUsage[categoryId] = DateTime.now().toIso8601String();

      // 3. Save to DB
      await _supabase
          .from('users')
          .update({
            'free_trial_usage': currentUsage,
          })
          .eq('id', userId);
    } catch (e) {
      print('SupabaseService: Error using free trial: $e');
      rethrow;
    }
  }

  // ============================================
  // CATEGORY OPERATIONS
  // ============================================

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('order', ascending: true);
      
      return (response as List)
          .map((data) => CategoryModel.fromSupabase(data))
          .toList();
    } catch (e) {
      print('SupabaseService: Error getting categories: $e');
      return [];
    }
  }

  /// Update category visibility (super admin only)
  Future<void> updateCategoryVisibility(String categoryId, String visibility) async {
    try {
      final response = await _supabase
          .from('categories')
          .update({
            'visibility': visibility,
          })
          .eq('id', categoryId)
          .select();
      
      if (response.isEmpty) {
        print('SupabaseService: Warning - No category updated for ID $categoryId. Check permissions or ID validity.');
        throw Exception('Failed to update category. It may not exist or you lack permissions.');
      }
      
      print('SupabaseService: Updated category $categoryId to visibility=$visibility');
    } catch (e) {
      print('SupabaseService: Error updating category visibility: $e');
      rethrow;
    }
  }

  /// Get total question count for a category
  Future<int> getCategoryQuestionCount(String categoryId) async {
    try {
      final count = await _supabase
          .from('questions')
          .count(CountOption.exact)
          .eq('category_id', categoryId);
      
      print('SupabaseService: Category $categoryId has $count questions');
      return count;
    } catch (e) {
      print('SupabaseService: Error getting category question count for $categoryId: $e');
      return 0;
    }
  }

  // ============================================
  // QUESTION OPERATIONS
  // ============================================

  /// Get questions for a category
  Future<List<QuestionModel>> getQuestions(String categoryId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('category_id', categoryId)
          .limit(limit);
      
      return (response as List)
          .map((q) => QuestionModel.fromSupabase(q))
          .toList();
    } catch (e) {
      print('SupabaseService: Error getting questions: $e');
      return [];
    }
  }

  /// Get question by ID
  Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('id', questionId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return QuestionModel.fromSupabase(response);
    } catch (e) {
      print('SupabaseService: Error getting question: $e');
      return null;
    }
  }

  /// Update question
  Future<void> updateQuestion(String questionId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('questions')
          .update(data)
          .eq('id', questionId);
    } catch (e) {
      print('SupabaseService: Error updating question: $e');
      rethrow;
    }
  }

  /// Create a new question
  Future<void> createQuestion(Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('questions')
          .insert(data);
    } catch (e) {
      print('SupabaseService: Error creating question: $e');
      rethrow;
    }
  }

  /// Delete a question
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _supabase
          .from('questions')
          .delete()
          .eq('id', questionId);
    } catch (e) {
      print('SupabaseService: Error deleting question: $e');
      rethrow;
    }
  }

  /// Get all questions (for admin management) with pagination
  Future<List<QuestionModel>> getAllQuestions({
    int limit = 20, 
    int offset = 0, 
    String? categoryId, 
    String? difficulty,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase
          .from('questions')
          .select();
      
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (difficulty != null) {
        query = query.eq('difficulty', difficulty);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('question', '%$searchQuery%');
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((q) => QuestionModel.fromSupabase(q))
          .toList();
    } catch (e) {
      print('SupabaseService: Error getting all questions: $e');
      return [];
    }
  }

  // ============================================
  // ANSWERED QUESTIONS OPERATIONS
  // ============================================

  /// Mark question as answered
  Future<void> markQuestionAsAnswered(String userId, String questionId) async {
    try {
      // Insert into answered_questions
      await _supabase
          .from('answered_questions')
          .insert({
            'user_id': userId,
            'question_id': questionId,
          });
      
      // Increment user's questions_answered_count
      await _supabase.rpc('increment_questions_answered', params: {
        'user_id_param': userId,
      });
    } catch (e) {
      print('SupabaseService: Error marking question as answered: $e');
    }
  }

  /// Check if user has answered a question
  Future<bool> hasUserAnsweredQuestion(String userId, String questionId) async {
    try {
      final response = await _supabase
          .from('answered_questions')
          .select('id')
          .eq('user_id', userId)
          .eq('question_id', questionId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('SupabaseService: Error checking answered question: $e');
      return false;
    }
  }

  /// Get user's answered count in a category
  Future<int> getUserAnsweredCountInCategory(String userId, String categoryId) async {
    try {
      // 1. Get question IDs for this category
      final questionsResponse = await _supabase
          .from('questions')
          .select('id')
          .eq('category_id', categoryId);
      
      final questionIds = (questionsResponse as List)
          .map((q) => q['id'] as String)
          .toList();
          
      if (questionIds.isEmpty) return 0;

      // 2. Count answered questions matching these IDs
      final count = await _supabase
          .from('answered_questions')
          .count(CountOption.exact)
          .eq('user_id', userId)
          .filter('question_id', 'in', questionIds);
      
      return count;
    } catch (e) {
      print('SupabaseService: Error getting answered count: $e');
      return 0;
    }
  }

  /// Reset progress for a specific category
  Future<void> resetCategoryProgress(String userId, String categoryId) async {
    try {
      await _supabase.rpc('reset_category_progress', params: {
        'user_id_param': userId,
        'category_id_param': categoryId,
      });
    } catch (e) {
      print('SupabaseService: Error resetting category progress: $e');
      rethrow;
    }
  }

  /// Get answered questions data (ID -> Timestamp)
  Future<Map<String, DateTime>> getAnsweredQuestionsData(String userId) async {
    try {
      final response = await _supabase
          .from('answered_questions')
          .select('question_id, answered_at')
          .eq('user_id', userId);
      
      final Map<String, DateTime> result = {};
      for (var row in response) {
        result[row['question_id']] = DateTime.parse(row['answered_at']);
      }
      return result;
    } catch (e) {
      print('SupabaseService: Error getting answered questions data: $e');
      return {};
    }
  }

  // ============================================
  // REPORT OPERATIONS
  // ============================================

  /// Report a question
  Future<void> reportQuestion(
    String questionId,
    String userId,
    String username,
    String email,
    String reason,
  ) async {
    try {
      // Check if already reported
      final existing = await _supabase
          .from('reports')
          .select('id')
          .eq('question_id', questionId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existing != null) {
        // Update existing report
        await _supabase
            .from('reports')
            .update({'reason': reason})
            .eq('question_id', questionId)
            .eq('user_id', userId);
      } else {
        // Insert new report
        await _supabase
            .from('reports')
            .insert({
              'question_id': questionId,
              'user_id': userId,
              'username': username,
              'email': email,
              'reason': reason,
            });
        
        // Increment question's report_count and user's reports_made_count
        await _supabase.rpc('increment_report_counts', params: {
          'question_id_param': questionId,
          'user_id_param': userId,
        });
      }
    } catch (e) {
      print('SupabaseService: Error reporting question: $e');
      rethrow;
    }
  }

  /// Get reports for a specific question
  Future<List<Map<String, dynamic>>> getQuestionReports(String questionId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('question_id', questionId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('SupabaseService: Error getting question reports: $e');
      return [];
    }
  }

  /// Get reported questions by status
  Future<List<QuestionModel>> getReportedQuestionsByStatus(String? status) async {
    try {
      // Get questions with reports matching the status
      final query = _supabase
          .from('questions')
          .select('*, reports!inner(*)')
          .gt('report_count', 0);
      
      if (status != null) {
        query.eq('reports.status', status);
      }
      
      final response = await query;
      
      return (response as List)
          .map((q) => QuestionModel.fromSupabase(q))
          .toList();
    } catch (e) {
      print('SupabaseService: Error getting reported questions: $e');
      return [];
    }
  }

  /// Resolve a report (mark as valid or invalid)
  Future<void> resolveReport(
    String questionId,
    String userId,
    bool isValid,
    String adminId,
  ) async {
    try {
      final status = isValid ? 'valid' : 'invalid';
      
      // Update report status
      await _supabase
          .from('reports')
          .update({
            'status': status,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': adminId,
          })
          .eq('question_id', questionId)
          .eq('user_id', userId);
      
      // Use RPC to update counters
      await _supabase.rpc('resolve_report_counters', params: {
        'report_user_id': userId,
        'admin_id_param': adminId,
        'is_valid_param': isValid,
        'question_id_param': questionId,
      });
    } catch (e) {
      print('SupabaseService: Error resolving report: $e');
      rethrow;
    }
  }

  /// Resolve ALL reports for a question (when admin fixes it)
  Future<void> resolveAllReportsForQuestion(
    String questionId,
    bool isValid,
    String adminId,
  ) async {
    try {
      // 1. Get all pending reports for this question
      final reports = await getQuestionReports(questionId);
      final pendingReports = reports.where((r) => r['status'] == 'pending').toList();

      // 2. Resolve each one
      for (var report in pendingReports) {
        final userId = report['user_id'] as String;
        await resolveReport(questionId, userId, isValid, adminId);
      }
    } catch (e) {
      print('SupabaseService: Error resolving all reports: $e');
      rethrow;
    }
  }

  /// Delete a report
  Future<void> deleteReport(String questionId, String userId) async {
    try {
      // Delete the report
      await _supabase
          .from('reports')
          .delete()
          .eq('question_id', questionId)
          .eq('user_id', userId);
      
      // Decrement counters
      await _supabase.rpc('delete_report_counters', params: {
        'question_id_param': questionId,
        'user_id_param': userId,
      });
    } catch (e) {
      print('SupabaseService: Error deleting report: $e');
      rethrow;
    }
  }

  /// Delete ALL reports for a question
  Future<void> deleteQuestionReports(String questionId) async {
    try {
      // Delete all reports for this question
      await _supabase
          .from('reports')
          .delete()
          .eq('question_id', questionId);
      
      // Reset report count for the question
      await _supabase
          .from('questions')
          .update({'report_count': 0})
          .eq('id', questionId);
    } catch (e) {
      print('SupabaseService: Error deleting question reports: $e');
      rethrow;
    }
  }
  // ============================================
  // STATISTICS OPERATIONS
  // ============================================

  /// Get question counts per category and difficulty
  Future<List<Map<String, dynamic>>> getCategoryQuestionCounts() async {
    try {
      final response = await _supabase.rpc('get_category_question_counts');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('SupabaseService: Error getting category question counts: $e');
      return [];
    }
  }

  /// Get general report stats
  Future<Map<String, dynamic>> getReportStats() async {
    try {
      final response = await _supabase.rpc('get_report_stats');
      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('SupabaseService: Error getting report stats: $e');
      return {};
    }
  }

  /// Get top admin resolvers
  Future<List<Map<String, dynamic>>> getTopAdminResolvers() async {
    try {
      final response = await _supabase.rpc('get_top_admin_resolvers');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('SupabaseService: Error getting top admin resolvers: $e');
      return [];
    }
  }

  /// Get most played categories
  Future<List<Map<String, dynamic>>> getMostPlayedCategories() async {
    try {
      final response = await _supabase.rpc('get_most_played_categories');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('SupabaseService: Error getting most played categories: $e');
      return [];
    }
  }
}
