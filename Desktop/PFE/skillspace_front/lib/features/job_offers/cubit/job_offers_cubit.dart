import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/job_offer_model.dart';

part 'job_offers_state.dart';

class JobOffersCubit extends Cubit<JobOffersState> {
  List<JobOffer> _allOffers = [];

  JobOffersCubit() : super(JobOffersInitial());

  Future<void> loadOffers() async {
    emit(JobOffersLoading());
    try {
      _allOffers = await JobOffer.fetchAll();
      emit(JobOffersLoaded(offers: _allOffers, filteredOffers: _allOffers));
    } catch (e) {
      emit(JobOffersError('Erreur de chargement des offres'));
    }
  }

  void search(String query) {
    if (state is! JobOffersLoaded) return;
    final current = state as JobOffersLoaded;
    final q = query.toLowerCase();
    final filtered = _allOffers
        .where((o) =>
            o.title.toLowerCase().contains(q) ||
            o.company.toLowerCase().contains(q))
        .toList();
    emit(JobOffersLoaded(
      offers: current.offers,
      filteredOffers: filtered,
      searchQuery: query,
      selectedContract: current.selectedContract,
    ));
  }

  void filterByContract(String? contract) {
    if (state is! JobOffersLoaded) return;
    final current = state as JobOffersLoaded;
    List<JobOffer> filtered;
    if (contract == null || contract == 'Tous') {
      filtered = _allOffers;
    } else {
      filtered =
          _allOffers.where((o) => o.contractType.label == contract).toList();
    }
    emit(JobOffersLoaded(
      offers: current.offers,
      filteredOffers: filtered,
      searchQuery: current.searchQuery,
      selectedContract: contract,
    ));
  }

  void toggleSave(String offerId) {
    if (state is! JobOffersLoaded) return;
    _allOffers = _allOffers.map((o) {
      if (o.id == offerId) return o.copyWith(isSaved: !o.isSaved);
      return o;
    }).toList();
    final current = state as JobOffersLoaded;
    final filtered = current.filteredOffers.map((o) {
      if (o.id == offerId) return o.copyWith(isSaved: !o.isSaved);
      return o;
    }).toList();
    emit(JobOffersLoaded(
      offers: _allOffers,
      filteredOffers: filtered,
      searchQuery: current.searchQuery,
      selectedContract: current.selectedContract,
    ));
  }
}
