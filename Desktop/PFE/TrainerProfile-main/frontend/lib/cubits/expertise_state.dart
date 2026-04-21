part of 'expertise_cubit.dart';

class ExpertiseState {
  final List<String> tags;
  final List<String> suggestions;
  final bool isLoading;
  final bool showSuggestions;

  const ExpertiseState({
    this.tags = const [],
    this.suggestions = const [],
    this.isLoading = false,
    this.showSuggestions = false,
  });

  ExpertiseState copyWith({
    List<String>? tags,
    List<String>? suggestions,
    bool? isLoading,
    bool? showSuggestions,
  }) {
    return ExpertiseState(
      tags: tags ?? this.tags,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      showSuggestions: showSuggestions ?? this.showSuggestions,
    );
  }
}
