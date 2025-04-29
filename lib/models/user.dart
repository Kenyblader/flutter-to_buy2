class User {
  String? id;
  final String email;
  final String password;
  final bool isActive;

  User({
    id,
    required this.email,
    required this.password,
    this.isActive = false,
  }) {
    this.id = id ?? DateTime.now().hashCode.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'] as String,
      password: map['password'] as String,
      isActive: (map['isActive'] as int) == 1,
    );
  }
}
