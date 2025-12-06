class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final int totalUploads;
  final int totalStorageUsed; // in bytes
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.totalUploads = 0,
    this.totalStorageUsed = 0,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    // Supabase sử dụng snake_case
    return {
      'id': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'total_uploads': totalUploads,
      'total_storage_used': totalStorageUsed,
      'preferences': preferences,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả camelCase (Firebase) và snake_case (Supabase)
    return UserModel(
      uid: json['id'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? json['displayName'],
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      totalUploads: json['total_uploads'] ?? json['totalUploads'] ?? 0,
      totalStorageUsed: json['total_storage_used'] ?? json['totalStorageUsed'] ?? 0,
      preferences: json['preferences'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    int? totalUploads,
    int? totalStorageUsed,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      totalUploads: totalUploads ?? this.totalUploads,
      totalStorageUsed: totalStorageUsed ?? this.totalStorageUsed,
      preferences: preferences ?? this.preferences,
    );
  }
}





