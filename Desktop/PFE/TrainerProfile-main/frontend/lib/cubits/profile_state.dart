import 'dart:typed_data';
import '../models/formateur_model.dart';

enum ProfileStatus { initial, loading, loaded, saving, failure }

class ProfileState {
  final ProfileStatus status;

  // FormateurModel fields
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String jobTitle;
  final String location;
  final String bio;
  final String linkedIn;
  final String portfolio;
  final String profilePicture; // raw base64 (for saving)
  final Uint8List? profilePictureBytes; // decoded (for display)
  final int profileCompleteness;
  final List<String> expertise;
  final List<Certification> certifications;

  // UI-only fields
  final bool isGeneratingBio;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.id = '',
    this.userId = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.jobTitle = '',
    this.location = '',
    this.bio = '',
    this.linkedIn = '',
    this.portfolio = '',
    this.profilePicture = '',
    this.profilePictureBytes,
    this.profileCompleteness = 0,
    this.expertise = const [],
    this.certifications = const [],
    this.isGeneratingBio = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
    String? location,
    String? bio,
    String? linkedIn,
    String? portfolio,
    String? profilePicture,
    Uint8List? profilePictureBytes,
    int? profileCompleteness,
    List<String>? expertise,
    List<Certification>? certifications,
    bool? isGeneratingBio,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      linkedIn: linkedIn ?? this.linkedIn,
      portfolio: portfolio ?? this.portfolio,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureBytes: profilePictureBytes ?? this.profilePictureBytes,
      profileCompleteness: profileCompleteness ?? this.profileCompleteness,
      expertise: expertise ?? this.expertise,
      certifications: certifications ?? this.certifications,
      isGeneratingBio: isGeneratingBio ?? this.isGeneratingBio,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Convert state back to FormateurModel for saving
  FormateurModel toModel() => FormateurModel(
        id: id,
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        jobTitle: jobTitle,
        location: location,
        bio: bio,
        profilePicture: profilePicture,
        profileCompleteness: profileCompleteness,
        expertise: expertise,
        certifications: certifications,
        linkedIn: linkedIn,
        portfolio: portfolio,
      );
}
