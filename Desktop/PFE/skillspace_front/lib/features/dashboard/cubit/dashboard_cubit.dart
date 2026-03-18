import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/dashboard_model.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final data = await DashboardData.fetch();
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError('Erreur de chargement des données'));
    }
  }
}
