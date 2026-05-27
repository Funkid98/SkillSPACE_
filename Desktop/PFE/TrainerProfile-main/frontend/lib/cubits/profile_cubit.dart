import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/formateur_model.dart';
import '../services/formateur_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final FormateurService _service;

  ProfileCubit(this._service) : super(const ProfileState());

  // ─── Load ────────────────────────────────────────────────
  Future<void> loadProfile(String userId, {FormateurModel? cached}) async {
    if (state.status == ProfileStatus.loading) return;

    // Use cache from TrainerCubit if available
    final profile = cached ?? await _fetchFromApi(userId);
    if (profile == null || isClosed) return;

    emit(state.copyWith(
      status: ProfileStatus.loaded,
      id: profile.id,
      userId: profile.userId,
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email,
      phone: profile.phone,
      jobTitle: profile.jobTitle,
      location: profile.location,
      bio: profile.bio,
      linkedIn: profile.linkedIn,
      portfolio: profile.portfolio,
      profilePicture: profile.profilePicture,
      profilePictureBytes: profile.profilePicture.isNotEmpty
          ? base64Decode(profile.profilePicture)
          : null,
      profileCompleteness: _calcScore(profile),
      expertise: profile.expertise.toList(),
      certifications: profile.certifications,
    ));
  }

  Future<FormateurModel?> _fetchFromApi(String userId) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final profile = await _service.getProfile(userId);
    if (profile == null) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: 'Profil introuvable',
      ));
    }
    return profile;
  }

  // ─── Field updates ───────────────────────────────────────
  void updateFirstName(String v) => emit(state.copyWith(firstName: v));
  void updateLastName(String v) => emit(state.copyWith(lastName: v));
  void updateEmail(String v) => emit(state.copyWith(email: v));
  void updatePhone(String v) => emit(state.copyWith(phone: v));
  void updateJobTitle(String v) => emit(state.copyWith(jobTitle: v));
  void updateLocation(String v) => emit(state.copyWith(location: v));
  void updateBio(String v) => emit(state.copyWith(bio: v));
  void updateLinkedIn(String v) => emit(state.copyWith(linkedIn: v));
  void updatePortfolio(String v) => emit(state.copyWith(portfolio: v));
  void updateExpertise(List<String> tags) =>
      emit(state.copyWith(expertise: tags));

  // ─── Picture ─────────────────────────────────────────────
  void updatePicture(Uint8List bytes) {
    emit(state.copyWith(
      profilePictureBytes: bytes,
      profilePicture: base64Encode(bytes), // encode once for saving
    ));
  }

  // ─── Certifications ──────────────────────────────────────
  void addCertification(Certification c) =>
      emit(state.copyWith(certifications: [...state.certifications, c]));

  void removeCertification(Certification c) => emit(state.copyWith(
        certifications: state.certifications.where((x) => x != c).toList(),
      ));

  // ─── Bio generation ──────────────────────────────────────
  Future<void> generateBio() async {
    if (state.firstName.isEmpty || state.jobTitle.isEmpty) return;
    emit(state.copyWith(isGeneratingBio: true));

    final bio = await _service.generateBio(
      '${state.firstName} ${state.lastName}',
      state.jobTitle,
      state.expertise,
    );
    if (isClosed) return;

    emit(state.copyWith(
      isGeneratingBio: false,
      bio: bio ?? state.bio,
    ));
  }

  // ─── Save ─────────────────────────────────────────────────
  Future<bool> saveProfile() async {
    if (isClosed) return false;
    emit(state.copyWith(status: ProfileStatus.saving));

    final actualId = state.userId.isNotEmpty ? state.userId : state.id;
    final result = await _service.updateProfile(
      actualId,
      state.toModel(),
    );
    if (isClosed) return false;

    if (result != null) {
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profileCompleteness: _calcScore(result),
      ));
      return true;
    }

    emit(state.copyWith(
      status: ProfileStatus.failure,
      errorMessage: 'Échec de la mise à jour',
    ));
    return false;
  }

  // ─── Score ───────────────────────────────────────────────
  int _calcScore(FormateurModel p) {
    int score = 0;
    if (p.firstName.isNotEmpty) score += 10;
    if (p.lastName.isNotEmpty) score += 10;
    if (p.email.isNotEmpty) score += 10;
    if (p.phone.isNotEmpty) score += 10;
    if (p.jobTitle.isNotEmpty) score += 10;
    if (p.location.isNotEmpty) score += 10;
    if (p.bio.isNotEmpty) score += 10;
    if (p.linkedIn.isNotEmpty) score += 10;
    if (p.profilePicture.isNotEmpty) score += 10;
    if (p.expertise.isNotEmpty) score += 10;
    return score.clamp(0, 100);
  }
}
