import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/recruiter_job_offer_model.dart';
import '../../data/repositories/recruiter_job_repository.dart';

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
  RecruiterCandidatesCubit() : super(RecruiterCandidatesInitial());

  void loadCandidates() async {
    emit(RecruiterCandidatesLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      final candidates = [
        CandidateMatch(
          id: '1',
          name: 'Jean Dupont',
          role: 'Développeur Frontend',
          location: 'Paris',
          experience: 'Jeune diplômé',
          skills: ['React', 'TypeScript', 'CSS', 'Git'],
          matchScore: 92,
          status: 'Nouveau',
          isSaved: true,
          initials: 'JD',
        ),
        CandidateMatch(
          id: '2',
          name: 'Marie Martin',
          role: 'Data Analyst',
          location: 'Lyon',
          experience: '1 an de stage',
          skills: ['Python', 'SQL', 'Excel', 'Tableau'],
          matchScore: 87,
          status: 'En revue',
          isSaved: false,
          initials: 'MM',
        ),
        CandidateMatch(
          id: '3',
          name: 'Lucas Bernard',
          role: 'Développeur Full-Stack',
          location: 'Bordeaux',
          experience: 'Jeune diplômé',
          skills: ['React', 'Node.js', 'MongoDB', 'TypeScript'],
          matchScore: 84,
          status: 'Nouveau',
          isSaved: true,
          initials: 'LB',
        ),
        CandidateMatch(
          id: '4',
          name: 'Sophie Duval',
          role: 'UX Designer',
          location: 'Remote',
          experience: '6 mois de stage',
          skills: ['Figma', 'Adobe XD', 'User Research'],
          matchScore: 79,
          status: 'Entretien planifié',
          isSaved: false,
          initials: 'SD',
        ),
        CandidateMatch(
          id: '5',
          name: 'Ahmed Benali',
          role: 'Chef de projet IT',
          location: 'Marseille',
          experience: 'Jeune diplômé',
          skills: ['Agile', 'JIRA', 'Communication', 'Scrum'],
          matchScore: 75,
          status: 'Nouveau',
          isSaved: false,
          initials: 'AB',
        ),
      ];
      emit(RecruiterCandidatesLoaded(candidates));
    } catch (e) {
      emit(RecruiterCandidatesError(e.toString()));
    }
  }
}
