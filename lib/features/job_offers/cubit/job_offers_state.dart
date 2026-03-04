part of 'job_offers_cubit.dart';

abstract class JobOffersState {}

class JobOffersInitial extends JobOffersState {}

class JobOffersLoading extends JobOffersState {}

class JobOffersLoaded extends JobOffersState {
  final List<JobOffer> offers;
  final List<JobOffer> filteredOffers;
  final String searchQuery;
  final String? selectedContract;

  JobOffersLoaded({
    required this.offers,
    required this.filteredOffers,
    this.searchQuery = '',
    this.selectedContract,
  });
}

class JobOffersError extends JobOffersState {
  final String message;
  JobOffersError(this.message);
}
