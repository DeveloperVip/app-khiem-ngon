import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_home_screen.dart';
import 'providers/translation_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kiểm tra và khởi tạo Supabase
  try {
    // Validate config trước khi khởi tạo
    final url = SupabaseConfig.supabaseUrl;
    final anonKey = SupabaseConfig.supabaseAnonKey;
    
    if (url.isEmpty || anonKey.isEmpty) {
      print('❌ ERROR: Supabase URL hoặc anon key bị rỗng!');
      print('   URL: ${url.isEmpty ? "EMPTY" : url}');
      print('   AnonKey: ${anonKey.isEmpty ? "EMPTY" : "${anonKey.substring(0, 20)}..."}');
      throw Exception('Supabase config không hợp lệ');
    }
    
    print('📦 Đang khởi tạo Supabase...');
    print('   URL: $url');
    print('   AnonKey: ${anonKey.substring(0, 20)}...');
    
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    
    print('✅ Supabase đã được khởi tạo thành công');
  } catch (e) {
    print('❌ Supabase initialization error: $e');
    final errorStr = e.toString().toLowerCase();
    
    if (errorStr.contains('failed host lookup') || 
        errorStr.contains('no address associated with hostname') ||
        errorStr.contains('socketexception')) {
      print('');
      print('⚠️ LỖI KẾT NỐI MẠNG:');
      print('   1. Kiểm tra thiết bị có internet (WiFi/4G/5G)');
      print('   2. Kiểm tra Supabase project có bị PAUSE không:');
      print('      → Vào https://app.supabase.com');
      print('      → Tìm project và click "Restore" nếu bị pause');
      print('   3. Thử restart app hoặc đổi mạng');
      print('');
    } else {
      print('❌ Vui lòng kiểm tra SupabaseConfig với URL và anon key đúng');
      print('❌ Đảm bảo đã rebuild app sau khi thay đổi config');
    }
    // Vẫn chạy app để user có thể thấy lỗi
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
      ],
      child: MaterialApp(
        title: 'Dịch Ngôn Ngữ Ký Hiệu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white, // Đảm bảo scaffold có background trắng
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Đợi một chút để auth provider load xong
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Hiển thị loading khi đang khởi tạo hoặc đang loading
        if (_isInitializing || authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Kiểm tra authentication state
        final supabase = Supabase.instance.client;
        final hasSession = supabase.auth.currentSession != null;
        final hasUser = authProvider.user != null;
        final isAuthenticated = hasUser || hasSession;
        
        // Debug log để troubleshoot
        print('AuthWrapper build:');
        print('  - hasUser: $hasUser');
        print('  - hasSession: $hasSession');
        print('  - isAuthenticated: $isAuthenticated');
        print('  - authProvider.user: ${authProvider.user?.email}');
        print('  - supabase.currentUser: ${supabase.auth.currentUser?.email}');
        
        if (isAuthenticated) {
          print('AuthWrapper: ✅ User authenticated, navigating to MainHomeScreen');
          return const MainHomeScreen();
        } else {
          print('AuthWrapper: ❌ User not authenticated, showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}