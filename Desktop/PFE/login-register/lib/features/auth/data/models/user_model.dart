class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? entreprise;
  final String? sector;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.entreprise,
    this.sector,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['prenom'] ?? json['firstName'] ?? '',
      lastName: json['nom'] ?? json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'candidat',
      entreprise: json['entreprise'] is Map
          ? (json['entreprise'] as Map)['nom']
          : json['entreprise'],
      sector: json['sector'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prenom': firstName,
      'nom': lastName,
      'email': email,
      'role': role,
      'entreprise': entreprise,
      'sector': sector,
    };
  }
}
