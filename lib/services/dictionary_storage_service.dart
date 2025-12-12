import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/translation_result.dart';


class DictionaryStorageService {
  static const String _fileName = 'dictionary_history.json';

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Future<List<TranslationResult>> getSavedTranslations() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) {
        MediaType type = MediaType.camera;
        if (json['mediaType'] != null) {
          if (json['mediaType'].toString().contains('video')) type = MediaType.video;
          else if (json['mediaType'].toString().contains('image')) type = MediaType.image;
        }
        
        return TranslationResult(
          text: json['text'],
          confidence: json['confidence'],
          timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
          mediaPath: json['mediaPath'],
          mediaType: type,
        );
      }).toList();
    } catch (e) {
      print('Error reading dictionary history: $e');
      return [];
    }
  }

  Future<void> saveTranslation(TranslationResult result) async {
    try {
      final history = await getSavedTranslations();
      history.insert(0, result);
      await _saveList(history);
    } catch (e) {
      print('Error saving translation: $e');
    }
  }
  
  Future<void> deleteTranslation(int index) async {
     try {
      final history = await getSavedTranslations();
      if (index >= 0 && index < history.length) {
        history.removeAt(index);
        await _saveList(history);
      }
    } catch (e) {
      print('Error deleting translation: $e');
    }
  }

  Future<void> _saveList(List<TranslationResult> history) async {
    final path = await _getFilePath();
    final file = File(path);
    
    final jsonList = history.map((item) => {
      'text': item.text,
      'confidence': item.confidence,
      'timestamp': item.timestamp.toIso8601String(),
      'mediaPath': item.mediaPath,
      'mediaType': item.mediaType.toString(),
    }).toList();

    await file.writeAsString(jsonEncode(jsonList));
  }
}
