# Hướng dẫn Build và Phân phối APK

## 📱 Cách Build APK Release

### Bước 1: Chuẩn bị keystore (chỉ cần làm 1 lần)

1. Tạo keystore file:
```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Khi được hỏi:
   - **Password**: Nhập mật khẩu (nhớ kỹ, sẽ cần dùng sau)
   - **Tên, tổ chức**: Nhập thông tin của bạn
   - **Lưu ý**: File `upload-keystore.jks` sẽ được tạo trong thư mục `android/`

3. Tạo file `android/key.properties`:
```properties
storePassword=<password-bạn-vừa-nhập>
keyPassword=<password-bạn-vừa-nhập>
keyAlias=upload
storeFile=upload-keystore.jks
```

### Bước 2: Cấu hình signing trong `android/app/build.gradle.kts`

Thêm vào cuối file (trước dòng `flutter {`):

```kotlin
android {
    // ... existing code ...
    
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = java.util.Properties()
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

### Bước 3: Build APK Release

```bash
cd flutter_application_initial
flutter build apk --release
```

APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`

### Bước 4: Build App Bundle (cho Google Play Store - tùy chọn)

```bash
flutter build appbundle --release
```

File `.aab` sẽ được tạo tại: `build/app/outputs/bundle/release/app-release.aab`

---

## 📤 Các cách phân phối APK

### Cách 1: Upload lên Google Drive (Đơn giản nhất)

1. Upload file `app-release.apk` lên Google Drive
2. Click chuột phải → "Get link" → Chọn "Anyone with the link"
3. Copy link và gửi cho người dùng
4. Người dùng mở link trên điện thoại và tải về

### Cách 2: Upload lên Firebase App Distribution (Chuyên nghiệp)

1. Tạo project trên [Firebase Console](https://console.firebase.google.com/)
2. Cài đặt Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
```

3. Khởi tạo Firebase trong project:
```bash
cd flutter_application_initial
firebase init
# Chọn: App Distribution
```

4. Upload APK:
```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups "testers" \
  --release-notes "Version 1.0.0"
```

### Cách 3: Upload lên GitHub Releases

1. Tạo release trên GitHub:
   - Vào repository → Releases → "Create a new release"
   - Tag: `v1.0.0`
   - Title: `Release v1.0.0`
   - Upload file `app-release.apk` vào "Attach binaries"

2. Người dùng tải về từ link release

### Cách 4: Chia sẻ trực tiếp qua USB/Email

1. Copy file `app-release.apk` vào điện thoại qua USB
2. Hoặc gửi qua email và mở trên điện thoại

---

## 📲 Cách cài đặt APK trên thiết bị Android

### Bước 1: Cho phép cài đặt từ nguồn không xác định

1. Vào **Settings** → **Security** (hoặc **Apps** → **Special access**)
2. Bật **"Install unknown apps"** hoặc **"Unknown sources"**
3. Chọn ứng dụng bạn sẽ dùng để cài (File Manager, Chrome, Email, etc.)

### Bước 2: Cài đặt APK

1. Mở file APK đã tải về
2. Tap **"Install"**
3. Chờ quá trình cài đặt hoàn tất
4. Tap **"Open"** để mở app

---

## 🔧 Build APK Debug (để test nhanh)

Nếu chỉ muốn test nhanh mà không cần signing:

```bash
flutter build apk --debug
```

APK debug sẽ tại: `build/app/outputs/flutter-apk/app-debug.apk`

**Lưu ý**: APK debug lớn hơn và chậm hơn APK release.

---

## 📋 Checklist trước khi build release

- [ ] Đã test app trên thiết bị thật
- [ ] Đã kiểm tra tất cả tính năng hoạt động đúng
- [ ] Đã cập nhật version trong `pubspec.yaml`
- [ ] Đã tạo keystore và cấu hình signing
- [ ] Đã test build release APK
- [ ] Đã kiểm tra kích thước APK (nên < 100MB)

---

## 🚀 Build APK nhanh (không cần signing - chỉ để test)

Nếu bạn chỉ muốn test nhanh trên thiết bị thật mà không cần signing:

```bash
flutter build apk --release --no-shrink
```

Hoặc build debug APK (nhanh hơn nhưng lớn hơn):

```bash
flutter build apk --debug
```

Sau đó copy file APK vào điện thoại và cài đặt.

---

## 📝 Lưu ý quan trọng

1. **Keystore file**: Giữ file `upload-keystore.jks` và `key.properties` an toàn. Nếu mất, bạn sẽ không thể update app lên Google Play Store.

2. **Version code**: Mỗi lần upload lên Play Store, phải tăng version code trong `android/app/build.gradle.kts`:
```kotlin
defaultConfig {
    versionCode 2  // Tăng số này mỗi lần release
    versionName "1.0.1"
}
```

3. **Permissions**: Đảm bảo tất cả permissions cần thiết đã được khai báo trong `android/app/src/main/AndroidManifest.xml`

4. **ProGuard**: Nếu dùng ProGuard, kiểm tra file `android/app/proguard-rules.pro` để đảm bảo không có lỗi khi build release.

---

## 🆘 Troubleshooting

### Lỗi: "Execution failed for task ':app:signReleaseBundle'"
→ Kiểm tra lại file `key.properties` và keystore file có đúng không

### Lỗi: "Keystore file not found"
→ Đảm bảo file `upload-keystore.jks` nằm trong thư mục `android/`

### APK quá lớn (>100MB)
→ Sử dụng App Bundle (.aab) thay vì APK để upload lên Play Store

### App crash khi cài đặt
→ Kiểm tra lại permissions trong AndroidManifest.xml và đảm bảo đã test trên thiết bị thật








