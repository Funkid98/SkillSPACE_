import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class L10nCubit extends Cubit<Locale> {
  L10nCubit() : super(const Locale('fr'));

  void setLocale(Locale locale) => emit(locale);

  void changeLanguage(String languageCode) {
    emit(Locale(languageCode));
  }
}
