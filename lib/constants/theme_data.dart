import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'colors.dart';

class Styles {
  static ThemeData themeData({required BuildContext context}) {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldColor,
      popupMenuTheme: PopupMenuThemeData(
        color: scaffoldColor,
        shadowColor: primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      sliderTheme: SliderThemeData(
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        overlayColor: Colors.white.withOpacity(0.4),
        thumbColor: Colors.white,
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 30.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: scaffoldColor,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        fillColor: formFieldColor,
        hintStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: Colors.grey,
        ),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 5, color: transparentColor),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 5, color: transparentColor),
          borderRadius: BorderRadius.circular(15),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: ThemeData().colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: ThemeData().colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  static ThemeData darkTheme({required BuildContext context}) {
    return ThemeData(
      primaryColor: Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey.shade900,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 20,
        ),
        fillColor: const Color.fromARGB(255, 133, 137, 147),
        hintStyle: const TextStyle(fontSize: 15, color: Colors.white),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 5, color: transparentColor),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 5, color: transparentColor),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: ThemeData().colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: ThemeData().colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      cardColor: Colors.grey.shade700,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          letterSpacing: -1.5,
          fontSize: 48,
          color: Colors.grey.shade50,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          letterSpacing: -1.0,
          fontSize: 40,
          color: Colors.grey.shade50,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          letterSpacing: -1.0,
          fontSize: 32,
          color: Colors.grey.shade50,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          letterSpacing: -1.0,
          color: Colors.grey.shade50,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          letterSpacing: -1.0,
          color: Colors.grey.shade50,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: Colors.grey.shade50,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: Colors.grey.shade50,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: Colors.grey.shade50,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Colors.grey.shade50,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: Colors.grey.shade50,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: TextStyle(
          color: Colors.grey.shade50,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: Colors.grey.shade50,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      bottomAppBarTheme: BottomAppBarTheme(color: Colors.grey.shade900),
    );
  }
}
