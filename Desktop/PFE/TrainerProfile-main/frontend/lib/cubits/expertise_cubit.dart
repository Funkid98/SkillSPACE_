import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/formateur_service.dart';

part 'expertise_state.dart';

class ExpertiseCubit extends Cubit<ExpertiseState> {
  final FormateurService _service;
  Timer? _debounce;

  ExpertiseCubit(this._service) : super(const ExpertiseState());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  /// Pre-load existing tags (called after profile is fetched)
  void setInitialTags(List<String> tags) {
    emit(state.copyWith(tags: tags));
  }

  /// Fetch AI suggestions from Groq with debouncing to keep UI fast
  Future<void> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _debounce?.cancel();
      emit(state.copyWith(suggestions: [], showSuggestions: false));
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      emit(state.copyWith(isLoading: true, showSuggestions: true));
      try {
        final suggestions = await _service.suggestExpertise(query, state.tags);
        emit(state.copyWith(suggestions: suggestions, isLoading: false));
      } catch (_) {
        emit(state.copyWith(isLoading: false, suggestions: []));
      }
    });
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
