import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/recruiter_job_offer_model.dart';
import '../../data/repositories/recruiter_job_repository.dart';
import '../../data/repositories/recruiter_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class RecruiterOffersState {}

class RecruiterOffersInitial extends RecruiterOffersState {}

class RecruiterOffersLoading extends RecruiterOffersState {}

class RecruiterOffersLoaded extends RecruiterOffersState {
  final List<RecruiterJobOffer> offers;
  RecruiterOffersLoaded(this.offers);
}

class RecruiterOffersError extends RecruiterOffersState {
  final String message;
  RecruiterOffersError(this.message);
}

class RecruiterOffersCubit extends Cubit<RecruiterOffersState> {
  final RecruiterJobRepository repository;
  final String userId;
  Timer? _pollingTimer;

  RecruiterOffersCubit({required this.repository, required this.userId})
      : super(RecruiterOffersInitial());

  Future<void> loadOffers({bool isBackground = false}) async {
    if (!isBackground) emit(RecruiterOffersLoading());
    try {
      final offers = await repository.getJobs();
      final myOffers =
          offers.where((offer) => offer.recruiter == userId).toList();
      emit(RecruiterOffersLoaded(myOffers));
      _startPolling();
    } catch (e) {
      if (!isBackground) emit(RecruiterOffersError(e.toString()));
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (isClosed) {
        timer.cancel();
        return;
      }
      try {
        final offers = await repository.getJobs();
        final myOffers =
            offers.where((offer) => offer.recruiter == userId).toList();
        if (!isClosed) emit(RecruiterOffersLoaded(myOffers));
      } catch (_) {}
    });
  }

  Future<void> createOffer(RecruiterJobOffer job) async {
    try {
      await repository.createJob(job);
      await loadOffers();
    } catch (e) {
      emit(RecruiterOffersError(e.toString()));
    }
  }

  Future<void> updateOffer(String id, RecruiterJobOffer job) async {
    try {
      await repository.updateJob(id, job);
      await loadOffers();
    } catch (e) {
      emit(RecruiterOffersError(e.toString()));
    }
  }

  Future<void> deleteOffer(String id) async {
    try {
      await repository.deleteJob(id);
      await loadOffers();
    } catch (e) {
      emit(RecruiterOffersError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}

// ─── Candidates Cubit ───
abstract class RecruiterCandidatesState {}

class RecruiterCandidatesInitial extends RecruiterCandidatesState {}

class RecruiterCandidatesLoading extends RecruiterCandidatesState {}

class RecruiterCandidatesLoaded extends RecruiterCandidatesState {
  final List<RecruiterOfferWithCandidates> groupedMatches;
  RecruiterCandidatesLoaded(this.groupedMatches);
}

class RecruiterCandidatesError extends RecruiterCandidatesState {
  final String message;
  RecruiterCandidatesError(this.message);
}

class RecruiterCandidatesCubit extends Cubit<RecruiterCandidatesState> {
  final RecruiterRepository repository;
  List<RecruiterOfferWithCandidates> _fullGroups = [];
  String _lastQuery = '';
  bool _showSavedOnly = false;
  Timer? _refreshTimer;

  List<String> _savedCandidateIds = [];

  RecruiterCandidatesCubit({required this.repository}) : super(RecruiterCandidatesInitial());

  void loadCandidates({bool isAutoRefresh = false}) async {
    if (!isAutoRefresh) emit(RecruiterCandidatesLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedCandidateIds = prefs.getStringList('saved_candidates') ?? [];

      var rawGroups = await repository.getGroupedMatchingCandidates();
      
      _fullGroups = rawGroups.map((group) {
        final syncedCandidates = group.candidates.map((c) {
          if (_savedCandidateIds.contains(c.id)) {
            return c.copyWith(isSaved: true);
          }
          return c;
        }).toList();
        return RecruiterOfferWithCandidates(offer: group.offer, candidates: syncedCandidates);
      }).toList();

      filterCandidates(_lastQuery);
      
      // Check if we need to continue polling
      _checkPolling();
    } catch (e) {
      if (!isAutoRefresh) emit(RecruiterCandidatesError(e.toString()));
    }
  }

  void _checkPolling() {
    bool needsPolling = false;
    for (var group in _fullGroups) {
      if (group.candidates.any((c) => c.status == 'ANALYSING' || c.matchScore == 0)) {
        needsPolling = true;
        break;
      }
    }

    if (needsPolling) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer(const Duration(seconds: 10), () => loadCandidates(isAutoRefresh: true));
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  void filterCandidates(String query) {
    _lastQuery = query;
    if (_fullGroups.isEmpty && state is! RecruiterCandidatesLoading) {
      emit(RecruiterCandidatesLoaded([]));
      return;
    }
    
    final q = query.trim().toLowerCase();
    
    final filtered = _fullGroups.map((group) {
        final filteredCandidates = group.candidates.where((c) {
          if (_showSavedOnly && !c.isSaved) return false;

          if (q.isEmpty) return true;

          final nameMatch = c.name.toLowerCase().contains(q);
          final roleMatch = c.role.toLowerCase().contains(q);
          final skillMatch = c.skills.any((s) => s.toLowerCase().contains(q));
          return nameMatch || roleMatch || skillMatch;
        }).toList();

        final offerMatch = group.offer.title.toLowerCase().contains(q);

        // If filtering by saved only, don't show empty groups just because offer matches query.
        if ((offerMatch && !_showSavedOnly && filteredCandidates.isEmpty) || filteredCandidates.isNotEmpty) {
            return RecruiterOfferWithCandidates(
                offer: group.offer,
                candidates: filteredCandidates.isNotEmpty ? filteredCandidates : (_showSavedOnly ? [] : group.candidates)
            );
        }
        return null;
    }).whereType<RecruiterOfferWithCandidates>().where((g) => g.candidates.isNotEmpty || (!_showSavedOnly && q.isEmpty)).toList();
    
    emit(RecruiterCandidatesLoaded(filtered));
  }

  void toggleSavedFilter() {
    _showSavedOnly = !_showSavedOnly;
    filterCandidates(_lastQuery);
  }

  bool get isShowingSavedOnly => _showSavedOnly;

  int get savedCount {
    int count = 0;
    for (var group in _fullGroups) {
      count += group.candidates.where((c) => c.isSaved).length;
    }
    return count;
  }

  void toggleSaveCandidate(String offerId, String candidateId) async {
    final prefs = await SharedPreferences.getInstance();

    _fullGroups = _fullGroups.map((group) {
      if (group.offer.id == offerId) {
        final newCandidates = group.candidates.map((c) {
          if (c.id == candidateId) {
            final newIsSaved = !c.isSaved;
            if (newIsSaved) {
              if (!_savedCandidateIds.contains(candidateId)) _savedCandidateIds.add(candidateId);
            } else {
              _savedCandidateIds.remove(candidateId);
            }
            return c.copyWith(isSaved: newIsSaved);
          }
          return c;
        }).toList();
        return RecruiterOfferWithCandidates(offer: group.offer, candidates: newCandidates);
      }
      return group;
    }).toList();
    
    await prefs.setStringList('saved_candidates', _savedCandidateIds);

    filterCandidates(_lastQuery);
  }
}
