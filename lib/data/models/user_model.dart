class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'super_admin', 'admin', 'cashier'
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
  });

  // Factory to create User from Firestore Document
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['displayName'] ?? 'Unknown Staff',
      role: data['role'] ?? 'cashier', // Default to lowest privilege
      isActive: data['isActive'] ?? false, // Default to blocked for safety
    );
  }

  // Helpers to check permissions easily
  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin'; // Admins can see basic stuff

  // === NEW: COPYWITH METHOD ===
  // This allows us to update the local user state without fetching from DB again
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}