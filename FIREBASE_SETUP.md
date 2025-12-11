# Hướng dẫn thiết lập Firebase

## Bước 1: Tạo Firebase Project

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" và làm theo hướng dẫn
3. Bật các dịch vụ sau:
   - **Authentication**: Email/Password
   - **Cloud Firestore**: Database
   - **Storage**: File storage

## Bước 2: Thêm Android App

1. Trong Firebase Console, click "Add app" > Android
2. Nhập package name: `com.example.flutter_application_initial`
3. Tải file `google-services.json`
4. Đặt file vào `android/app/google-services.json`

## Bước 3: Thêm iOS App (nếu cần)

1. Trong Firebase Console, click "Add app" > iOS
2. Nhập Bundle ID từ Xcode project
3. Tải file `GoogleService-Info.plist`
4. Đặt file vào `ios/Runner/GoogleService-Info.plist`

## Bước 4: Cấu hình Android

Thêm vào `android/build.gradle.kts` (project level):
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

Thêm vào `android/app/build.gradle.kts` (app level):
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## Bước 5: Cấu hình Firestore Rules

Trong Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Lessons collection - public read
    match /lessons/{lessonId} {
      allow read: if true;
      allow write: if false; // Chỉ admin có thể thêm lessons
    }
    
    // User uploads - chỉ user sở hữu mới có quyền
    match /user_uploads/{uploadId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // User progress - chỉ user sở hữu mới có quyền
    match /user_progress/{progressId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
  }
}
```

## Bước 6: Cấu hình Storage Rules

Trong Firebase Console > Storage > Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_uploads/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Bước 7: Tạo dữ liệu mẫu Lessons

Bạn cần tạo collection `lessons` trong Firestore với cấu trúc:

```json
{
  "id": "lesson1",
  "title": "Bài học 1: Chào hỏi",
  "description": "Học cách chào hỏi bằng ngôn ngữ ký hiệu",
  "order": 1,
  "estimatedDuration": 10,
  "thumbnailUrl": "https://...",
  "contents": [
    {
      "id": "content1",
      "type": "video",
      "videoUrl": "https://...",
      "translation": "Xin chào",
      "description": "Cách chào hỏi cơ bản",
      "order": 0
    }
  ],
  "quiz": {
    "id": "quiz1",
    "lessonId": "lesson1",
    "questions": [
      {
        "id": "q1",
        "question": "Cách chào hỏi là gì?",
        "options": ["Xin chào", "Tạm biệt", "Cảm ơn", "Xin lỗi"],
        "correctAnswerIndex": 0,
        "explanation": "Xin chào là cách chào hỏi cơ bản"
      }
    ]
  }
}
```

## Bước 8: Chạy ứng dụng

```bash
flutter pub get
flutter run
```

## Lưu ý

- Đảm bảo đã cấu hình đúng package name/Bundle ID
- Kiểm tra quyền truy cập internet trong AndroidManifest.xml và Info.plist
- Firebase sẽ tự động khởi tạo khi app chạy lần đầu







