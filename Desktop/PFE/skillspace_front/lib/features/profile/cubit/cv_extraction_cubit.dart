import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../data/cv_extraction_service.dart';

part 'cv_extraction_state.dart';

class CvExtractionCubit extends Cubit<CvExtractionState> {
  CvExtractionCubit() : super(CvExtractionInitial());

  /// Opens file picker, uploads the selected CV, and emits states.
  Future<void> pickAndUploadCv({required String token}) async {
    try {
      // 1. Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true, // needed for web
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // 2. Start loading
      emit(CvExtractionLoading());

      // 3. Upload and extract
      final data = await CvExtractionService.uploadCv(
        file: file,
        token: token,
      );

      // 4. Success
      emit(CvExtractionSuccess(data));
    } catch (e) {
      emit(CvExtractionError(e.toString()));
    }
  }

  void reset() => emit(CvExtractionInitial());
}
