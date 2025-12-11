import 'package:flutter/material.dart';
import 'lessons_screen.dart';
import 'profile_screen.dart';
import 'camera_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  
  // Lazy initialization - chỉ tạo khi cần và được chọn
  Widget? _lessonsScreen;
  Widget? _cameraScreen;
  Widget? _profileScreen;

  Widget _buildCurrentScreen() {
    Widget screen;
    switch (_currentIndex) {
      case 0:
        _lessonsScreen ??= const LessonsScreen();
        screen = _lessonsScreen!;
        print('🏠 MainHomeScreen: Returning LessonsScreen');
      case 1:
        _cameraScreen ??= const CameraScreen();
        screen = _cameraScreen!;
        print('🏠 MainHomeScreen: Returning CameraScreen');
      case 2:
        _profileScreen ??= const ProfileScreen();
        screen = _profileScreen!;
        print('🏠 MainHomeScreen: Returning ProfileScreen');
      default:
        _lessonsScreen ??= const LessonsScreen();
        screen = _lessonsScreen!;
        print('🏠 MainHomeScreen: Returning default LessonsScreen');
    }
    return Container(
      color: Colors.white,
      child: screen,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 MainHomeScreen: Building with index=$_currentIndex');
    final currentScreen = _buildCurrentScreen();
    print('🏠 MainHomeScreen: Current screen type: ${currentScreen.runtimeType}');
    
    return Scaffold(
      backgroundColor: Colors.white, // Đảm bảo có background color
      body: Container(
        color: Colors.white, // Đảm bảo container có màu trắng
        child: SafeArea(
          child: currentScreen, // Chỉ render screen đang được chọn
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Bài học',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Dịch Realtime',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}







