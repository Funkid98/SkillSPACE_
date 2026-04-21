import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/formateur_service.dart';

part 'expertise_state.dart';

class ExpertiseCubit extends Cubit<ExpertiseState> {
  final FormateurService _service;

  ExpertiseCubit(this._service) : super(const ExpertiseState());

  /// Pre-load existing tags (called after profile is fetched)
  void setInitialTags(List<String> tags) {
    emit(state.copyWith(tags: tags));
  }

  /// Fetch AI suggestions from Groq — only this cubit rebuilds, not the whole screen
  Future<void> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      emit(state.copyWith(suggestions: [], showSuggestions: false));
      return;
    }
    emit(state.copyWith(isLoading: true, showSuggestions: true));
    try {
      final suggestions = await _service.suggestExpertise(query, state.tags);
      emit(state.copyWith(suggestions: suggestions, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false, suggestions: []));
    }
  }

  /// Add a tag and clear suggestions
  void addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !state.tags.contains(trimmed)) {
      emit(state.copyWith(
        tags: [...state.tags, trimmed],
        suggestions: [],
        showSuggestions: false,
      ));
    }
  }

  /// Remove a tag
  void removeTag(String tag) {
    emit(state.copyWith(
      tags: state.tags.where((t) => t != tag).toList(),
    ));
  }

  void clearSuggestions() {
    emit(state.copyWith(suggestions: [], showSuggestions: false));
  }
}
