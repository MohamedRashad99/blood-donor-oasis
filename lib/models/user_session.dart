class UserSession {
  final String username;
  final String displayName;
  final String role; // 'مدير النظام', 'مشرف حملات', 'مسؤول تسجيل'
  final bool isAuthenticated;
  final DateTime? loginTime;

  const UserSession({
    required this.username,
    required this.displayName,
    required this.role,
    this.isAuthenticated = true,
    this.loginTime,
  });

  static const UserSession guest = UserSession(
    username: '',
    displayName: 'زائر',
    role: 'غير مسجل',
    isAuthenticated: false,
  );

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'displayName': displayName,
      'role': role,
      'isAuthenticated': isAuthenticated,
      'loginTime': loginTime?.toIso8601String(),
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'مدير النظام',
      role: json['role'] as String? ?? 'مدير النظام',
      isAuthenticated: json['isAuthenticated'] == true,
      loginTime: json['loginTime'] != null
          ? DateTime.tryParse(json['loginTime'] as String)
          : null,
    );
  }
}
