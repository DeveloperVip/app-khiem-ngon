import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../screens/main_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    print('Login: Starting sign in...');
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    print('Login: Sign in result = $success');
    print('Login: User = ${authProvider.user?.email}');
    print('Login: isAuthenticated = ${authProvider.isAuthenticated}');
    print('Login: AuthProvider user = ${authProvider.user != null}');

    if (!success && mounted) {
      final errorMsg = authProvider.errorMessage?.replaceAll('Exception: ', '') ?? 'Đăng nhập thất bại';
      print('Login: Error = $errorMsg');
      
      // Hiển thị dialog nếu là lỗi email chưa xác nhận
      if (errorMsg.contains('Email chưa được xác nhận')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email chưa được xác nhận'),
            content: const Text(
              'Email của bạn chưa được xác nhận. Vui lòng:\n\n'
              '1. Kiểm tra email (kể cả thư mục spam)\n'
              '2. Click vào link xác nhận trong email\n'
              '3. Đăng nhập lại\n\n'
              'Hoặc tắt "Enable email confirmations" trong Supabase Dashboard > Authentication > Providers > Email để test.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Đóng',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } else if (success && mounted) {
      // Đăng nhập thành công - Navigate trực tiếp đến MainHomeScreen
      print('Login: Success! Navigating to MainHomeScreen...');
      
      // Đợi một chút để đảm bảo state được update
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Kiểm tra lại
      final supabase = Supabase.instance.client;
      final hasSession = supabase.auth.currentSession != null;
      final hasUser = authProvider.user != null;
      
      print('Login: Final check - hasSession: $hasSession, hasUser: $hasUser');
      
      if (hasSession || hasUser) {
        // Navigate và replace LoginScreen bằng MainHomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainHomeScreen()),
        );
      } else {
        // Nếu vẫn không có session/user, thử refresh lại
        await authProvider.refreshUser();
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (authProvider.isAuthenticated || supabase.auth.currentSession != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainHomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công nhưng có lỗi khi load thông tin. Vui lòng thử lại.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
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
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sign_language,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Dịch Ngôn Ngữ Ký Hiệu',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!value.contains('@')) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                if (value.length < 6) {
                                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                return ElevatedButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Đăng nhập',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text('Chưa có tài khoản? Đăng ký'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}





