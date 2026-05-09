import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/core/network/api_client.dart';
import '../data/models/job_offer_model.dart';

part 'job_offers_state.dart';

class JobOffersCubit extends Cubit<JobOffersState> {
  List<JobOffer> _allOffers = [];

  Timer? _pollingTimer;

  JobOffersCubit() : super(JobOffersInitial());

  Future<void> loadOffers() async {
    if (isClosed) return;
    emit(JobOffersLoading());
    try {
      _allOffers = await JobOffer.fetchAll();
      if (isClosed) return;
      emit(JobOffersLoaded(offers: _allOffers, filteredOffers: _allOffers));
      _startPolling();
    } catch (e) {
      if (isClosed) return;
      emit(JobOffersError('Erreur de chargement des offres'));
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (isClosed) {
        _pollingTimer?.cancel();
        return;
      }
      
      if (state is JobOffersLoaded) {
        final current = state as JobOffersLoaded;
        final hasAnalysing = _allOffers.any((o) => o.status == 'ANALYSING');
        
        if (hasAnalysing) {
           try {
             final freshOffers = await JobOffer.fetchAll();
             if (isClosed) return;
             
             // Check if we actually got valid data before updating
             if (freshOffers.isNotEmpty) {
                 _allOffers = freshOffers;
                 _applyFilters(current.searchQuery, current.selectedContract, freshOffers);
             }
           } catch (_) {}
        } else {
          _pollingTimer?.cancel();
        }
      }
    });
  }

  void search(String query) {
    if (state is! JobOffersLoaded) return;
    final current = state as JobOffersLoaded;
    _applyFilters(query, current.selectedContract, current.offers);
  }

  void filterByContract(String? contract) {
    if (state is! JobOffersLoaded) return;
    final current = state as JobOffersLoaded;
    _applyFilters(current.searchQuery, contract, current.offers);
  }

  void _applyFilters(String query, String? contract, List<JobOffer> offers) {
    final q = query.toLowerCase();

    final filtered = _allOffers.where((o) {
      // 1. Check search query
      final matchesQuery = q.isEmpty ||
          o.title.toLowerCase().contains(q) ||
          o.company.toLowerCase().contains(q) ||
          o.city.toLowerCase().contains(q);

      // 2. Check contract filte
      // If contract is null or we can't match it to a specific type, we assume "All"
      bool matchesContract = true;
      if (contract != null && contract.isNotEmpty) {
        final cLower = contract.toLowerCase();
        if (cLower == 'cdi' ||
            cLower == 'cdd' ||
            cLower == 'freelance' ||
            cLower == 'stage') {
          matchesContract = o.contractType.name.toLowerCase() == cLower;
        }
      }

      return matchesQuery && matchesContract;
    }).toList();

    if (isClosed) return;
    emit(JobOffersLoaded(
      offers: offers,
      filteredOffers: filtered,
      searchQuery: query,
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
    if (isClosed) return;
    emit(JobOffersLoaded(
      offers: _allOffers,
      filteredOffers: filtered,
      searchQuery: current.searchQuery,
      selectedContract: current.selectedContract,
    ));
  }

  Future<void> registerView(String offerId) async {
    try {
      final client = ApiClient();
      await client.put('/api/offers/$offerId/view', {});
    } catch (_) {
      // Unobstructive silent error handler
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> applyToOffer(JobOffer offer) async {
    try {
      if (offer.recruiterId == null || offer.recruiterId!.isEmpty) {
        return 'Recruteur introuvable pour cette offre.';
      }
      final client = ApiClient();
      final response = await client.post('/candidat/apply', {
        'offerId': offer.id,
        'recruiterId': offer.recruiterId,
        'offerTitle': offer.title,
      });
      if (response.statusCode == 200) {
        return null; // success
      }
      return 'Erreur lors de la candidature (${response.statusCode}).';
    } catch (e) {
      return 'Erreur réseau. Veuillez réessayer.';
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
