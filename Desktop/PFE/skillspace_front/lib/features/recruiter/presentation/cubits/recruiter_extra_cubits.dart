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

  RecruiterOffersCubit({required this.repository}) : super(RecruiterOffersInitial());

  Future<void> loadOffers() async {
    emit(RecruiterOffersLoading());
    try {
      final offers = await repository.getJobs();
      emit(RecruiterOffersLoaded(offers));
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
  final List<CandidateMatch> candidates;
  RecruiterCandidatesLoaded(this.candidates);
}

class RecruiterCandidatesError extends RecruiterCandidatesState {
  final String message;
  RecruiterCandidatesError(this.message);
}

class RecruiterCandidatesCubit extends Cubit<RecruiterCandidatesState> {
  final RecruiterRepository repository;
  List<CandidateMatch> _fullList = [];
  String _lastQuery = '';

  RecruiterCandidatesCubit({required this.repository}) : super(RecruiterCandidatesInitial());

  void loadCandidates(String sector) async {
    emit(RecruiterCandidatesLoading());
    try {
      _fullList = await repository.getCandidatesBySector(sector);
      filterCandidates(_lastQuery);
    } catch (e) {
      emit(RecruiterCandidatesError(e.toString()));
    }
  }

  void filterCandidates(String query) {
    _lastQuery = query;
    if (_fullList.isEmpty && state is! RecruiterCandidatesLoading) {
      emit(RecruiterCandidatesLoaded([]));
      return;
    }
    
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      emit(RecruiterCandidatesLoaded(_fullList));
      return;
    }
    
    final filtered = _fullList.where((c) {
      final nameMatch = c.name.toLowerCase().contains(q);
      final roleMatch = c.role.toLowerCase().contains(q);
      final skillMatch = c.skills.any((s) => s.toLowerCase().contains(q));
      return nameMatch || roleMatch || skillMatch;
    }).toList();
    
    emit(RecruiterCandidatesLoaded(filtered));
  }
}
