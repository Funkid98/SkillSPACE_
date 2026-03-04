class ProfileData {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String location;
  final String bio;
  final int completionPercent;
  final bool hasCv;
  final List<ProfileSkill> skills;

  const ProfileData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.location,
    required this.bio,
    required this.completionPercent,
    required this.hasCv,
    required this.skills,
  });

  ProfileData copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? location,
    String? bio,
    int? completionPercent,
    bool? hasCv,
    List<ProfileSkill>? skills,
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
      skills: skills ?? this.skills,
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
      skills: [
        ProfileSkill(name: 'React', level: 'Avancé'),
        ProfileSkill(name: 'TypeScript', level: 'Intermédiaire'),
        ProfileSkill(name: 'Python', level: 'Intermédiaire'),
        ProfileSkill(name: 'SQL', level: 'Intermédiaire'),
        ProfileSkill(name: 'Communication', level: 'Expert'),
      ],
    );
  }
}

class ProfileSkill {
  final String name;
  final String level;

  const ProfileSkill({required this.name, required this.level});
}
