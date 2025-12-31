// import 'package:angelina_app/core/utils/constants/constants.dart'; // add this
// import 'package:angelina_app/core/utils/services/app_prefs.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class LocaleCubit extends Cubit<Locale> {
//   final AppPrefs _prefs;
//   LocaleCubit(this._prefs) : super(const Locale('ar'));

//   Future<void> load() async {
//     final loc = _prefs.getLocale();
//     AppConstants.lang = loc.languageCode; // keep in sync
//     emit(loc);
//   }

//   Future<void> setLocale(Locale locale) async {
//     await _prefs.setLocale(locale);
//     AppConstants.lang = locale.languageCode; // ❗ update global lang
//     emit(locale);
//   }
// }
