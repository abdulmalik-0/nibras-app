import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of auth changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign Up
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      // 1. Check if username exists first
      final usernameCheck = await _supabase
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (usernameCheck != null) {
        throw AuthException(
          'اسم المستخدم مستخدم بالفعل، الرجاء اختيار اسم آخر',
        );
      }

      // 2. Create Auth User
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
        },
      );

      if (response.user == null) {
        throw AuthException('فشل إنشاء الحساب');
      }

      if (response.user == null) {
        throw AuthException('فشل إنشاء الحساب');
      }

      // Return null because we can't fetch the profile yet (user is not verified/logged in)
      // The profile is created by the trigger, but we can't read it until login.
      return null;
    } on AuthException catch (e) {
      // Translate common errors
      String message = e.message;
      if (message.contains('already registered')) {
        message = 'البريد الإلكتروني مسجل بالفعل';
      } else if (message.contains('Password')) {
        message = 'كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل)';
      } else if (message.contains('email')) {
        message = 'البريد الإلكتروني غير صحيح';
      }

      throw AuthException(message);
    } catch (e) {
      throw AuthException('حدث خطأ غير متوقع: $e');
    }
  }

  // Sign In
  Future<User?> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } on AuthException catch (e) {
      print('DEBUG: SignIn Error Message: ${e.message}'); // Debugging
      String message = e.message;
      if (message.contains('Invalid')) {
        message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (message.toLowerCase().contains('email not confirmed')) {
        throw AuthException('EMAIL_NOT_CONFIRMED');
      }

      throw AuthException(message);
    } catch (e) {
      print('DEBUG: Unexpected SignIn Error: $e'); // Debugging
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      if (e.message.contains('rate_limit') || e.statusCode == '429') {
        throw AuthException('الرجاء الانتظار قليلاً قبل المحاولة مرة أخرى');
      }
      throw AuthException('فشل إرسال رمز التحقق: ${e.message}');
    } catch (e) {
      throw AuthException('فشل إرسال رمز التحقق: $e');
    }
  }

  // Verify Recovery OTP
  Future<AuthResponse> verifyRecoveryOtp(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      return response;
    } catch (e) {
      throw AuthException('رمز التحقق غير صحيح أو منتهي الصلاحية');
    }
  }

  // Verify Signup OTP
  Future<AuthResponse> verifySignupOtp(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      return response;
    } catch (e) {
      throw AuthException('رمز التحقق غير صحيح أو منتهي الصلاحية');
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AuthException('فشل تحديث كلمة المرور: $e');
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user_account');
      await signOut();
    } catch (e) {
      throw AuthException('فشل حذف الحساب: $e');
    }
  }

  // Get User Details
  Future<UserModel?> getUserDetails() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromSupabase(response);
    } catch (e) {
      print('AuthService: Error getting user details: $e');
      return null;
    }
  }
}
