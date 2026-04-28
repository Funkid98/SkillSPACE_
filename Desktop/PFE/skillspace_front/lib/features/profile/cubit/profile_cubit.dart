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
    // We use 10 fields for Candidat so each is exactly 10%
    int total = isRecruiter ? 8 : 9; 

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
    
    // Adding work info for perfect 10s
    if (data.poste != null && data.poste!.isNotEmpty) score++;
    if (isRecruiter && data.entreprise != null && data.entreprise!.isNotEmpty) {
      score++;
    }

    int rawPercent = ((score / total) * 100).toInt();
    // Round to nearest 10 (e.g., 12.5 -> 10, 25 -> 20, 37.5 -> 40, etc.)
    int percent = (rawPercent / 10).round() * 10;
    
    // Ensure 100 is always 100 when finished
    if (score == total) percent = 100;
    
    return data.copyWith(completionPercent: percent);
  }

  void updateField(ProfileData updated) {
    if (state is ProfileLoaded) {
      final newData = _calculateCompletion(updated);
      emit(ProfileLoaded(newData, isSaved: false));
    }
  }

  void updateSkillPercent(String skillName, int percent) {
    if (state is ProfileLoaded) {
      final data = (state as ProfileLoaded).data;
      final index = data.skills.indexWhere((s) => s.name == skillName);
      if (index >= 0) {
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
            return ProfileSkill(name: s['name'] ?? '', percent: (s['percent'] ?? 33).toInt());
          }
          return const ProfileSkill(name: '');
        }).toList() ?? current.skills,
      );

      // Auto-calculate completion after extraction
      emit(ProfileLoaded(_calculateCompletion(updated), isSaved: false));
    }
  }
}
