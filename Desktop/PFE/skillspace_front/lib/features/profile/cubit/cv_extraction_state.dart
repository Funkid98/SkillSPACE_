part of 'cv_extraction_cubit.dart';

abstract class CvExtractionState {}

class CvExtractionInitial extends CvExtractionState {}

class CvExtractionLoading extends CvExtractionState {}

class CvExtractionSuccess extends CvExtractionState {
  final Map<String, dynamic> data;
  CvExtractionSuccess(this.data);
}

class CvExtractionError extends CvExtractionState {
  final String message;
  CvExtractionError(this.message);
}
