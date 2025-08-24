import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/vars.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(Locale(lang ?? 'en'));

  void changeLocale(String languageCode) {
    lang = languageCode;
    CacheHelper.saveData(key: 'lang', value: languageCode);
    emit(Locale(languageCode));
  }
}
