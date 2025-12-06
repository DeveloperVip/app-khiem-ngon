import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Đăng ký
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName ?? email.split('@')[0],
        },
      );

      if (response.user != null) {
        // Đợi một chút để trigger chạy xong (nếu có)
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Lấy thông tin user từ database
        // getUserData sẽ tự động tạo user nếu chưa có
        final userModel = await getUserData(response.user!.id);
        
        // Nếu vẫn null, trả về user model cơ bản từ auth data
        return userModel ?? UserModel(
          uid: response.user!.id,
          email: email,
          displayName: displayName ?? email.split('@')[0],
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      // Xử lý lỗi rate limit
      final errorMessage = e.toString();
      if (errorMessage.contains('over_email_send_rate_limit') || 
          errorMessage.contains('429')) {
        throw Exception('Bạn đã gửi quá nhiều yêu cầu đăng ký. Vui lòng đợi 45 giây trước khi thử lại.');
      }
      
      // Xử lý lỗi gửi email
      if (errorMessage.contains('Error sending confirmation email') ||
          errorMessage.contains('unexpected_failure') ||
          errorMessage.contains('500')) {
        throw Exception('Không thể gửi email xác nhận. Vui lòng kiểm tra cấu hình SMTP trong Supabase Dashboard hoặc liên hệ admin.');
      }
      
      // Xử lý các lỗi khác
      if (errorMessage.contains('User already registered') ||
          errorMessage.contains('already registered')) {
        throw Exception('Email này đã được đăng ký. Vui lòng đăng nhập hoặc sử dụng email khác.');
      }
      
      if (errorMessage.contains('Password') || errorMessage.contains('password')) {
        throw Exception('Mật khẩu không hợp lệ. Mật khẩu phải có ít nhất 6 ký tự.');
      }
      
      if (errorMessage.contains('Invalid email') || errorMessage.contains('invalid')) {
        throw Exception('Email không hợp lệ. Vui lòng kiểm tra lại.');
      }
      
      throw Exception('Lỗi đăng ký: ${e.toString()}');
    }
  }

  // Đăng nhập
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Đợi một chút để đảm bảo session được set
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Lấy thông tin user từ database
        // getUserData sẽ tự động tạo user nếu chưa có
        final userModel = await getUserData(response.user!.id);
        
        // Nếu vẫn null, trả về user model cơ bản từ auth data
        return userModel ?? UserModel(
          uid: response.user!.id,
          email: email,
          displayName: response.user!.userMetadata?['display_name'] ?? 
                      email.split('@')[0],
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      final errorMessage = e.toString();
      
      if (errorMessage.contains('Invalid login credentials')) {
        throw Exception('Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.');
      }
      
      if (errorMessage.contains('Email not confirmed') || 
          errorMessage.contains('email_not_confirmed')) {
        throw Exception('Email chưa được xác nhận. Vui lòng kiểm tra email và click vào link xác nhận.\n\nNếu bạn đang test, hãy tắt "Enable email confirmations" trong Supabase Dashboard > Authentication > Settings.');
      }
      
      throw Exception('Lỗi đăng nhập: ${e.toString()}');
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Lấy thông tin user
  Future<UserModel?> getUserData(String uid) async {
    try {
      // Thử lấy user từ database
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();

      // Nếu tìm thấy, trả về
      if (response != null) {
        return UserModel.fromJson(response);
      }

      // Nếu không tìm thấy, lấy thông tin từ auth.users và tạo record mới
      final authUser = _supabase.auth.currentUser;
      if (authUser != null && authUser.id == uid) {
        // Gọi function để đảm bảo user tồn tại
        try {
          await _supabase.rpc('ensure_user_exists', params: {
            'user_id': uid,
            'user_email': authUser.email ?? '',
            'user_display_name': authUser.userMetadata?['display_name'] ?? 
                                 authUser.email?.split('@')[0],
          });
          
          // Thử lấy lại
          final retryResponse = await _supabase
              .from('users')
              .select()
              .eq('id', uid)
              .maybeSingle();
          
          if (retryResponse != null) {
            return UserModel.fromJson(retryResponse);
          }
        } catch (rpcError) {
          // Nếu RPC không hoạt động, thử insert trực tiếp
          try {
            await _supabase.from('users').insert({
              'id': uid,
              'email': authUser.email ?? '',
              'display_name': authUser.userMetadata?['display_name'] ?? 
                             authUser.email?.split('@')[0] ?? 'User',
              'created_at': DateTime.now().toIso8601String(),
              'total_uploads': 0,
              'total_storage_used': 0,
            });
            
            final finalResponse = await _supabase
                .from('users')
                .select()
                .eq('id', uid)
                .maybeSingle();
            
            if (finalResponse != null) {
              return UserModel.fromJson(finalResponse);
            }
          } catch (insertError) {
            // Nếu vẫn lỗi, trả về user model từ auth data
            return UserModel(
              uid: uid,
              email: authUser.email ?? '',
              displayName: authUser.userMetadata?['display_name'] ?? 
                          authUser.email?.split('@')[0] ?? 'User',
              createdAt: DateTime.now(),
            );
          }
        }
      }

      // Nếu vẫn không có, trả về null
      return null;
    } catch (e) {
      // Nếu có lỗi, thử trả về user model từ auth data
      final authUser = _supabase.auth.currentUser;
      if (authUser != null && authUser.id == uid) {
        return UserModel(
          uid: uid,
          email: authUser.email ?? '',
          displayName: authUser.userMetadata?['display_name'] ?? 
                      authUser.email?.split('@')[0] ?? 'User',
          createdAt: DateTime.now(),
        );
      }
      throw Exception('Lỗi lấy thông tin user: ${e.toString()}');
    }
  }

  // Cập nhật thông tin user
  Future<void> updateUserData(UserModel user) async {
    try {
      await _supabase.from('users').update({
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
        'total_uploads': user.totalUploads,
        'total_storage_used': user.totalStorageUsed,
        'preferences': user.preferences,
      }).eq('id', user.uid);
    } catch (e) {
      throw Exception('Lỗi cập nhật thông tin: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Lỗi gửi email reset password: ${e.toString()}');
    }
  }
}
