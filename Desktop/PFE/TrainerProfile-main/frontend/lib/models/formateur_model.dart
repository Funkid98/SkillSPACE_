class Certification {
  String name;
  String issuer;
  String year;
  String? image;
  String fileType;
  String? fullFile;

  Certification({
    required this.name,
    required this.issuer,
    required this.year,
    this.image,
    this.fileType = 'image',
    this.fullFile,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      year: json['year'] ?? '',
      image: json['image'],
      fileType: json['fileType'] ?? 'image',
      fullFile: json['fullFile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'year': year,
      if (image != null) 'image': image,
      'fileType': fileType,
      if (fullFile != null) 'fullFile': fullFile,
    };
  }
}

class FormateurModel {
  String id;
  String userId;
  String firstName;
  String lastName;
  String email;
  String phone;
  String jobTitle;
  String location;
  String bio;
  String profilePicture;
  int profileCompleteness;
  List<String> expertise;
  List<Certification> certifications;
  String linkedIn;
  String portfolio;

  FormateurModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.jobTitle,
    required this.location,
    required this.bio,
    required this.profilePicture,
    required this.profileCompleteness,
    required this.expertise,
    required this.certifications,
    required this.linkedIn,
    required this.portfolio,
  });

  factory FormateurModel.fromJson(Map<String, dynamic> json) {
    return FormateurModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      location: json['location'] ?? '',
      bio: json['bio'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      profileCompleteness: json['profileCompleteness'] ?? 0,
      expertise:
          json['expertise'] != null ? List<String>.from(json['expertise']) : [],
      certifications: json['certifications'] != null
          ? (json['certifications'] as List)
              .map((i) => Certification.fromJson(i))
              .toList()
          : [],
      linkedIn: json['socialLinks']?['linkedIn'] ?? '',
      portfolio: json['socialLinks']?['portfolio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'jobTitle': jobTitle,
      'location': location,
      'bio': bio,
      'profilePicture': profilePicture,
      'profileCompleteness': profileCompleteness,
      'expertise': expertise,
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'socialLinks': {
        'linkedIn': linkedIn,
        'portfolio': portfolio,
      }
    };
  }
}
