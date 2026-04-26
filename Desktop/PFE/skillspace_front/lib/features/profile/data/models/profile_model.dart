import 'skill_level.dart';

class ProfileData {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String location;
  final String bio;
  final int completionPercent;
  final bool hasCv;
  final String? entreprise;
  final String? poste;
  final List<ProfileSkill> skills;
  final String role;

  const ProfileData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.location,
    required this.bio,
    required this.completionPercent,
    required this.hasCv,
    this.entreprise,
    this.poste,
    required this.skills,
    this.role = 'candidat',
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      firstName: json['prenom'] ?? '',
      lastName: json['nom'] ?? '',
      email: json['email'] ?? '',
      phone: json['telephone'] ?? '',
      location: json['localisation'] ?? '',
      bio: json['bio'] ?? '',
      completionPercent: json['completion_percent'] ?? 0,
      hasCv: (json['cv_path'] as String?)?.isNotEmpty == true,
      entreprise: json['entreprise'] is Map
          ? (json['entreprise'] as Map)['nom']
          : json['entreprise'],
      poste: json['poste'] ?? json['jobtitle'],
      skills: (json['skills'] as List?)?.map((s) {
            if (s is Map<String, dynamic>) {
              return ProfileSkill(
                name: s['name'] ?? '',
                percent: (s['percent'] ?? 10).toInt(),
              );
            }
            return ProfileSkill(name: s.toString());
          }).toList() ??
          [],
      role: json['role'] ?? 'candidat',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prenom': firstName,
      'nom': lastName,
      'email': email,
      'telephone': phone,
      'localisation': location,
      'bio': bio,
      'completion_percent': completionPercent,
      'entreprise': entreprise,
      'poste': poste,
      'jobtitle': poste,
      'skills':
          skills.map((s) => {'name': s.name, 'percent': s.percent}).toList(),
      'role': role,
    };
  }

  ProfileData copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? location,
    String? bio,
    int? completionPercent,
    bool? hasCv,
    String? entreprise,
    String? poste,
    List<ProfileSkill>? skills,
    String? role,
  }) {
    return ProfileData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      completionPercent: completionPercent ?? this.completionPercent,
      hasCv: hasCv ?? this.hasCv,
      entreprise: entreprise ?? this.entreprise,
      poste: poste ?? this.poste,
      skills: skills ?? this.skills,
      role: role ?? this.role,
    );
  }

  static Future<ProfileData> fetch() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const ProfileData(
      firstName: 'Jean',
      lastName: 'Dupont',
      email: 'jean.dupont@email.com',
      phone: '+33 6 12 34 56 78',
      location: 'Paris, France',
      bio:
          'Jeune diplômé en informatique passionné par le développement web et l\'intelligence artificielle. À la recherche de mon premier emploi en tant que développeur frontend.',
      completionPercent: 75,
      hasCv: false,
      entreprise: null,
      poste: null,
      skills: [
        ProfileSkill(name: 'React'),
        ProfileSkill(name: 'TypeScript'),
        ProfileSkill(name: 'Python'),
        ProfileSkill(name: 'SQL'),
        ProfileSkill(name: 'Communication'),
      ],
    );
  }
}

class ProfileSkill {
  final String name;
  final int percent;

  const ProfileSkill({required this.name, this.percent = 33});

  SkillLevel get level {
    if (percent <= 33) return SkillLevel.beginner;
    if (percent <= 66) return SkillLevel.intermediate;
    return SkillLevel.advanced;
  }

  ProfileSkill copyWithLevel(SkillLevel lvl) {
    int newPercent = 33;
    switch (lvl) {
      case SkillLevel.beginner:
        newPercent = 33;
        break;
      case SkillLevel.intermediate:
        newPercent = 66;
        break;
      case SkillLevel.advanced:
        newPercent = 100;
        break;
    }
    return ProfileSkill(name: name, percent: newPercent);
  }
}
