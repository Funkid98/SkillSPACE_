import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/string_extension.dart';
import '../data/models/profile_model.dart';
import '../data/profile_service.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final Map<String, dynamic>? initialUserData;

  ProfileCubit({this.initialUserData}) : super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        // Fallback to dummy or initial data if no token (might happen in dev)
        var data = await ProfileData.fetch();
        if (initialUserData != null) {
          data = _mergeInitialData(data, initialUserData!);
        }
        emit(ProfileLoaded(data, isSaved: true));
        return;
      }

      final data = await ProfileService.getProfile(token);
      emit(ProfileLoaded(data, isSaved: true));
    } catch (e) {
      if (kDebugMode) print('Error loading profile: $e');
      emit(ProfileError('Erreur de chargement du profil'));
    }
  }

  Future<void> saveProfile() async {
    if (state is! ProfileLoaded) return;
    final currentData = (state as ProfileLoaded).data;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Calculate completion before saving
      final updatedData = _calculateCompletion(currentData);

      await ProfileService.updateProfile(token, updatedData);
      emit(ProfileLoaded(updatedData, isSaved: true));
    } catch (e) {
      if (kDebugMode) print('Error saving profile: $e');
      emit(ProfileError('Erreur lors de l\'enregistrement du profil'));
    }
  }

  ProfileData _mergeInitialData(ProfileData data, Map<String, dynamic> initial) {
    return data.copyWith(
      firstName: (initial['firstName'] as String?)?.isNotEmpty == true
          ? (initial['firstName'] as String).capitalize()
          : data.firstName.capitalize(),
      lastName: (initial['lastName'] as String?)?.isNotEmpty == true
          ? (initial['lastName'] as String).capitalize()
          : data.lastName.capitalize(),
      email: (initial['email'] as String?)?.isNotEmpty == true
          ? initial['email'] as String
          : data.email,
    );
  }

  ProfileData _calculateCompletion(ProfileData data) {
    final isRecruiter = data.role == 'recruteur' || data.role == 'recruiter';
    int score = 0;
    int total = isRecruiter ? 6 : 8; // (email, phone, location, bio, skills, cv) vs (+ prenom, nom)

    if (!isRecruiter) {
      if (data.firstName.isNotEmpty) score++;
      if (data.lastName.isNotEmpty) score++;
    }
    
    if (data.email.isNotEmpty) score++;
    if (data.phone.isNotEmpty) score++;
    if (data.location.isNotEmpty) score++;
    if (data.bio.isNotEmpty) score++;
    if (data.skills.isNotEmpty) score++;
    if (data.hasCv) score++;

    int percent = ((score / total) * 100).toInt();
    return data.copyWith(completionPercent: percent);
  }

  void updateField(ProfileData updated) {
    if (state is ProfileLoaded) {
      final newData = _calculateCompletion(updated);
      emit(ProfileLoaded(newData, isSaved: false));
    }
  }

  void updateSkillPercent(int index, int percent) {
    if (state is ProfileLoaded) {
      final data = (state as ProfileLoaded).data;
      if (index >= 0 && index < data.skills.length) {
        final updatedSkills = List<ProfileSkill>.from(data.skills);
        final skill = updatedSkills[index];
        updatedSkills[index] = ProfileSkill(
          name: skill.name,
          percent: percent.clamp(0, 100),
        );
        emit(ProfileLoaded(data.copyWith(skills: updatedSkills), isSaved: false));
      }
    }
  }

  void updateFromExtractedData(Map<String, dynamic> data) {
    if (state is ProfileLoaded) {
      final current = (state as ProfileLoaded).data;

      final updated = current.copyWith(
        firstName: (data['prenom'] as String?)?.capitalize() ?? current.firstName,
        lastName: (data['nom'] as String?)?.capitalize() ?? current.lastName,
        email: data['email'] ?? current.email,
        phone: data['telephone'] ?? data['phone'] ?? current.phone,
        location: data['localisation'] ?? data['location'] ?? current.location,
        bio: data['bio'] ?? current.bio,
        poste: data['jobTitle'] ?? data['jobtitle'] ?? data['poste'] ?? current.poste,
        entreprise: data['entreprise'] ?? data['company'] ?? current.entreprise,
        hasCv: true,
        skills: (data['skills'] as List?)?.map((s) {
          if (s is String) {
            return ProfileSkill(name: s);
          } else if (s is Map) {
            return ProfileSkill(name: s['name'] ?? '', percent: (s['percent'] ?? 50).toInt());
          }
          return const ProfileSkill(name: '');
        }).toList() ?? current.skills,
      );

      // Auto-calculate completion after extraction
      emit(ProfileLoaded(_calculateCompletion(updated), isSaved: false));
    }
  }
}
