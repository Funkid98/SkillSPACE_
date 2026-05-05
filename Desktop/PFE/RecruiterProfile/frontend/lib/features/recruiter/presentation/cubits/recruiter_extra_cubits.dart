import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/recruiter_job_offer_model.dart';
import '../../data/repositories/recruiter_job_repository.dart';
import '../../data/repositories/recruiter_repository.dart';

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

  RecruiterOffersCubit({required this.repository, required this.userId}) : super(RecruiterOffersInitial());

  Future<void> loadOffers() async {
    emit(RecruiterOffersLoading());
    try {
      final offers = await repository.getJobs();
      final myOffers = offers.where((offer) => offer.recruiter == userId).toList();
      emit(RecruiterOffersLoaded(myOffers));
    } catch (e) {
      emit(RecruiterOffersError(e.toString()));
    }
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
  Timer? _refreshTimer;

  RecruiterCandidatesCubit({required this.repository}) : super(RecruiterCandidatesInitial());

  void loadCandidates({bool isAutoRefresh = false}) async {
    if (!isAutoRefresh) emit(RecruiterCandidatesLoading());
    try {
      _fullGroups = await repository.getGroupedMatchingCandidates();
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
    if (q.isEmpty) {
      emit(RecruiterCandidatesLoaded(_fullGroups));
      return;
    }
    
    final filtered = _fullGroups.map((group) {
        final filteredCandidates = group.candidates.where((c) {
          final nameMatch = c.name.toLowerCase().contains(q);
          final roleMatch = c.role.toLowerCase().contains(q);
          final skillMatch = c.skills.any((s) => s.toLowerCase().contains(q));
          return nameMatch || roleMatch || skillMatch;
        }).toList();

        final offerMatch = group.offer.title.toLowerCase().contains(q);

        if (offerMatch || filteredCandidates.isNotEmpty) {
            return RecruiterOfferWithCandidates(
                offer: group.offer,
                candidates: filteredCandidates.isNotEmpty ? filteredCandidates : group.candidates
            );
        }
        return null;
    }).whereType<RecruiterOfferWithCandidates>().toList();
    
    emit(RecruiterCandidatesLoaded(filtered));
  }
}
