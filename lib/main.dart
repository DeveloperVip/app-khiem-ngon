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
  
  // Khởi tạo Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e) {
    print('Supabase initialization error: $e');
    print('Vui lòng kiểm tra SupabaseConfig với URL và anon key đúng');
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