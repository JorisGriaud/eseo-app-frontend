/// User model
class User {
  final String eseoId;
  final String accessToken;

  User({
    required this.eseoId,
    required this.accessToken,
  });

  /// Create User from JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      eseoId: json['eseo_id'].toString(),
      accessToken: json['access_token'] as String,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'eseo_id': eseoId,
      'access_token': accessToken,
    };
  }
}
