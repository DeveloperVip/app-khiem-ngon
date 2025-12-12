import 'package:flutter/material.dart';
import 'lessons_screen.dart';
import 'profile_screen.dart';
import 'camera_screen.dart';
import 'storage_screen.dart';

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
  Widget? _storageScreen;

  Widget _buildCurrentScreen() {
    Widget screen;
    switch (_currentIndex) {
      case 0:
        _lessonsScreen ??= const LessonsScreen();
        screen = _lessonsScreen!;
        screen = _lessonsScreen!;
      case 1:
        _storageScreen ??= const StorageScreen();
        screen = _storageScreen!;
        screen = _storageScreen!;
      case 2:
        _cameraScreen ??= const CameraScreen();
        screen = _cameraScreen!;
        screen = _cameraScreen!;
      case 3:
        _profileScreen ??= const ProfileScreen();
        screen = _profileScreen!;
        screen = _profileScreen!;
      default:
        _lessonsScreen ??= const LessonsScreen();
        screen = _lessonsScreen!;
        screen = _lessonsScreen!;
    }
    return Container(
      color: Colors.white,
      child: screen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = _buildCurrentScreen();
    
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
             icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_open),
            label: 'Lưu trữ',
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







