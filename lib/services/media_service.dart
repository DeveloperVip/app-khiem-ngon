import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MediaService {
  final ImagePicker _picker = ImagePicker();

  // Kiểm tra và yêu cầu quyền truy cập
  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    final photosStatus = await Permission.photos.request();

    return cameraStatus.isGranted && 
           (storageStatus.isGranted || photosStatus.isGranted);
  }

  // Chọn ảnh từ thư viện
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Chọn video từ thư viện
  Future<XFile?> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  // Chụp ảnh từ camera
  Future<XFile?> takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  // Quay video từ camera
  Future<XFile?> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }

  // Lưu file vào thư mục app
  Future<String> saveFile(XFile file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(file.path);
      final savedPath = path.join(directory.path, fileName);
      
      final fileData = await file.readAsBytes();
      final savedFile = File(savedPath);
      await savedFile.writeAsBytes(fileData);
      
      return savedPath;
    } catch (e) {
      print('Error saving file: $e');
      return file.path;
    }
  }

  // Xóa file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}






