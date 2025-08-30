import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:ui';
import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/main.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/models/wallet_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';

String getLocalizedGender(BuildContext context, Gender gender) {
  switch (gender) {
    case Gender.male:
      return S.of(context).male;
    case Gender.female:
      return S.of(context).female;
    default:
      return gender.name;
  }
}

String getTranslatedOrderStatus(BuildContext context, OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return S.of(context).pending;
    case OrderStatus.accepted:
      return S.of(context).accepted;
    case OrderStatus.rejected:
      return S.of(context).rejected;
    case OrderStatus.shipped:
      return S.of(context).shipped;
    case OrderStatus.delivered:
      return S.of(context).delivered;
  }
}

String getTranslatedWalletType(BuildContext context, WalletTypes walletType) {
  switch (walletType) {
    case WalletTypes.order:
      return S.of(context).order;
    case WalletTypes.offer:
      return S.of(context).offer;
    case WalletTypes.withdrawal:
      return S.of(context).withdraw;
  }
}

Color getStatusBackgroundColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Colors.orange.withOpacity(0.15);
    case OrderStatus.accepted:
      return Colors.blue.withOpacity(0.15);
    case OrderStatus.shipped:
      return primaryColor.withOpacity(0.15);
    case OrderStatus.delivered:
      return const Color(0XffDEFDB1); // أخضر فاتح
    case OrderStatus.rejected:
      return Colors.red.withOpacity(0.15);
  }
}

Color getStatusTextColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Colors.orange;
    case OrderStatus.accepted:
      return Colors.blue;
    case OrderStatus.shipped:
      return primaryColor;
    case OrderStatus.delivered:
      return Colors.green;
    case OrderStatus.rejected:
      return Colors.red;
  }
}

List<TextSpan> buildStyledText(String text, double fontSize) {
  final regex = RegExp(r'\*(.*?)\*');
  final spans = <TextSpan>[];
  int currentIndex = 0;

  for (final match in regex.allMatches(text)) {
    // Add normal text before the match
    if (match.start > currentIndex) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex, match.start),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: textColor.withOpacity(0.7),
          ),
        ),
      );
    }

    // Add bold text (inside *)
    spans.add(
      TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontSize: fontSize + 2,
          fontWeight: FontWeight.w800,
          color: textColor.withOpacity(0.7),
        ),
      ),
    );

    currentIndex = match.end;
  }

  // Add remaining normal text after last match
  if (currentIndex < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(currentIndex),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: textColor.withOpacity(0.7),
        ),
      ),
    );
  }

  return spans;
}

String formatNotificationDate(Timestamp timestamp) {
  final dateTime = timestamp.toDate();
  final timePart = DateFormat('hh:mm a').format(dateTime); // 02:45 PM
  final datePart = DateFormat(
    'dd MMMM, yyyy',
  ).format(dateTime); // 14 August, 2025
  return '$timePart $datePart';
}

String formatDateHeader(DateTime date, BuildContext context) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) return S.of(context).today;
  if (diff == 1) return S.of(context).yesterday;
  if (diff < 7) return DateFormat.EEEE().format(date); // eg. Monday, Tuesday
  return DateFormat('d MMMM yyyy').format(date); // eg. 12 June 2025
}

String formatTimestamp(Timestamp timestamp) {
  return DateFormat('h:mm a').format(timestamp.toDate());
}

String timeFromSeconds(int seconds, [bool minWidth4 = false]) {
  if (seconds == 0) return "0:00";

  String result = DateFormat(
    'HH:mm:ss',
  ).format(DateTime(2022, 1, 1, 0, 0, seconds));

  List resultParts = result.split(':');
  for (int i = 0; i < resultParts.length; i++) {
    if (resultParts[i] != "00") break;
    resultParts[i] = "";
  }
  resultParts.removeWhere((element) => element == "");

  if (minWidth4 && resultParts.length == 1) {
    resultParts = ["0", ...resultParts];
  }

  return resultParts.join(':');
}

TextSpan parseStyledText(
  String input,
  TextStyle baseStyle,
  TextStyle boldStyle,
) {
  final spans = <TextSpan>[];
  final regex = RegExp(r'\*\*(.*?)\*\*');
  final matches = regex.allMatches(input);

  int currentIndex = 0;

  for (final match in matches) {
    if (match.start > currentIndex) {
      spans.add(
        TextSpan(
          text: input.substring(currentIndex, match.start),
          style: baseStyle,
        ),
      );
    }

    spans.add(TextSpan(text: match.group(1), style: boldStyle));

    currentIndex = match.end;
  }

  if (currentIndex < input.length) {
    spans.add(TextSpan(text: input.substring(currentIndex), style: baseStyle));
  }

  return TextSpan(children: spans);
}

List<String> getSubCategories(String categoryName) {
  final category = matajerEnglishCategories.firstWhere(
    (element) => element["name"] == categoryName,
    orElse: () => {"subCategories": []},
  );
  return List<String>.from(category["subCategories"]);
}

List<String> getVisibleTitles(ProductModel productModel) {
  final nonEmptyTitles = productModel.specifications
      .expand((spec) => spec.subTitles)
      .map((sub) => sub.title.trim())
      .where(
        (title) =>
            title.isNotEmpty &&
            !colorNames.containsKey(title.toLowerCase().replaceAll(' ', '')),
      )
      .toList();
  return nonEmptyTitles.take(3).toList();
}

int getHiddenTitlesCount(int visibleCount, ProductModel productModel) {
  final allTitles = productModel.specifications
      .expand((spec) => spec.subTitles)
      .map((sub) => sub.title.trim())
      .where(
        (title) =>
            title.isNotEmpty &&
            !colorNames.containsKey(title.toLowerCase().replaceAll(' ', '')),
      )
      .toList();
  return allTitles.length - visibleCount;
}

String formatNumberWithCommas(double number) {
  final formatter = NumberFormat('#,##0.00'); // adds commas + 2 decimal places
  return formatter.format(number);
}

String formatAsDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatPostDate(DateTime date, BuildContext context) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return S.of(context).just_now;
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} ${S.of(context).minutes} ${S.of(context).ago}';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} ${S.of(context).hours} ${S.of(context).ago}';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} ${S.of(context).days} ${S.of(context).ago}';
  } else if (difference.inDays < 14) {
    return '1 ${S.of(context).weeks} ${S.of(context).ago}';
  } else if (difference.inDays < 30) {
    return '${difference.inDays ~/ 7} ${S.of(context).weeks} ${S.of(context).ago}';
  } else if (difference.inDays < 365) {
    return '${difference.inDays ~/ 30} ${S.of(context).months} ${S.of(context).ago}';
  } else {
    return '${difference.inDays ~/ 365} ${S.of(context).years} ${S.of(context).ago}';
  }
}

Future<bool> isImageDark(String imageUrl) async {
  final ImageProvider imageProvider = NetworkImage(imageUrl);
  final PaletteGenerator paletteGenerator =
      await PaletteGenerator.fromImageProvider(imageProvider);
  final Color dominantColor = paletteGenerator.dominantColor!.color;
  final double luminance = dominantColor.computeLuminance();
  return luminance < 0.5; // True if image is dark, false if it's light
}

void navigateTo({required BuildContext context, required Widget screen}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
}

void navigateReplacement({
  required BuildContext context,
  required Widget screen,
}) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

void navigateAndFinish({
  required BuildContext context,
  required Widget screen,
}) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (builder) => screen),
    (route) => false,
  );
}

Future<Position> getCurrentPosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied');
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

Future<String> getAddressFromCoordinates(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isEmpty) return "Unknown location";

    final place = placemarks.first;
    return "${place.street}, ${place.locality}, ${place.country}";
  } catch (e) {
    print("Error reverse geocoding: $e");
    return "Unknown location";
  }
}

String capitalizeWords(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

/// Call this for both network and file images
void showProfilePreview({
  required BuildContext context,
  String? imageUrl,
  XFile? file,
  bool isProfile = true,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (_, __, ___) => _ProfileFlipView(
        imageUrl: imageUrl,
        file: file,
        isProfile: isProfile,
      ),
    ),
  );
}

class _ProfileFlipView extends StatefulWidget {
  final String? imageUrl; // network
  final XFile? file; // local file
  final bool isProfile;

  const _ProfileFlipView({this.imageUrl, this.file, this.isProfile = false});

  @override
  State<_ProfileFlipView> createState() => _ProfileFlipViewState();
}

class _ProfileFlipViewState extends State<_ProfileFlipView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _animation = Tween<double>(
      begin: pi,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildImage() {
    if (widget.file != null) {
      return Image.file(
        File(widget.file!.path),
        height: 0.5.sh,
        width: 0.9.sw,
        fit: BoxFit.cover,
      );
    } else {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        progressIndicatorBuilder: (context, url, progress) =>
            shimmerPlaceholder(height: 0.5.sh, width: 0.9.sw, radius: 200.r),
        height: 0.5.sh,
        width: 0.9.sw,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.file?.path ?? widget.imageUrl!;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Blur background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
            Center(
              child: widget.isProfile
                  ? AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final angle = _animation.value;

                        return Hero(
                          tag: heroTag,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: senderColor,
                                width: 9.h,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              margin: EdgeInsets.all(8.h),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: primaryColor,
                                  width: 8.h,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 160.h,
                                backgroundColor: Colors.transparent,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001) // perspective
                                    ..rotateY(angle),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(200.r),
                                    child: _buildImage(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Hero(
                      tag: heroTag,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: widget.file != null
                              ? Image.file(
                                  File(widget.file!.path),
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: widget.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget showFlushBar({required BuildContext context, required String message}) =>
    Flushbar(
      message: message,
      icon: const Icon(Icons.info_outline, size: 28.0, color: primaryColor),
      margin: const EdgeInsets.all(6.0),
      flushbarStyle: FlushbarStyle.FLOATING,
      flushbarPosition: FlushbarPosition.TOP,
      textDirection: Directionality.of(context),
      borderRadius: BorderRadius.circular(12),
      duration: const Duration(seconds: 3),
      leftBarIndicatorColor: primaryColor,
    )..show(context);

String? validateEmail(String? email, BuildContext context) {
  if (email == null || email.isEmpty) {
    return S.of(context).email_is_required;
  }

  RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(email)) {
    return S.of(context).email_is_invalid;
  }

  return null;
}

// String? validatePassword(String? password, BuildContext context) {
//   if (password == null || password.isEmpty) {
//     return S.of(context).password_is_required;
//   }
//
//   if (password.length < 3) {
//     return S.of(context).password_at_least_char;
//   }
//
//   if (!password.contains(RegExp(r'\d'))) {
//     return S.of(context).password_at_least_digit;
//   }
//
//   return null;
// }

String? validateUsername(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) {
    return S.of(context).please_enter_your_name;
  }

  final name = value.trim();

  // Must be at least 3 letters
  if (name.length < 3) {
    return S.of(context).name_must_be_2_letters;
  }

  // Only alphabetic characters and spaces allowed (English + Arabic)
  final regex = RegExp(r"^[A-Za-z\u0600-\u06FF\s]+$");
  if (!regex.hasMatch(name)) {
    return S.of(context).name_can_only_contain_letters;
  }

  // Prevents single word gibberish longer than 20 characters
  if (name.length > 20 && !name.contains(" ")) {
    return S.of(context).please_enter_a_valid_full_name;
  }

  // Require at least one space if length >= 6 (to encourage full name)
  if (name.length >= 6 && !name.contains(" ")) {
    return S.of(context).please_enter_your_full_name;
  }

  return null; // valid
}

String? validatePassword(String? password, BuildContext context) {
  if (password == null || password.isEmpty) {
    return S.of(context).password_is_required;
  }

  if (password.length < 8) {
    return S.of(context).password_at_least_char; // Update string to mention "8"
  }

  if (!RegExp(r'\d').hasMatch(password)) {
    return S.of(context).password_at_least_digit;
  }

  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return S.of(context).password_at_least_uppercase;
  }

  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return S.of(context).password_at_least_lowercase;
  }

  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_-]').hasMatch(password)) {
    return S.of(context).password_at_least_special;
  }

  if (password.contains(' ')) {
    return S.of(context).password_should_not_contain_spaces;
  }

  // Optional: Check for common weak passwords
  final weakPasswords = ['123456', 'password', 'qwerty', 'abc123'];
  if (weakPasswords.contains(password.toLowerCase())) {
    return S.of(context).password_is_too_common;
  }

  return null;
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snack(context) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: const [
          Icon(Icons.wifi_off_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No internet connection. Please check your network.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.redAccent.shade200,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 4),
      elevation: 6,
    ),
  );
}

Future<void> retryFCMTokenIfNeeded() async {
  if (fcmDeviceToken!.isEmpty && await hasInternetConnection()) {
    try {
      fcmDeviceToken = await FirebaseMessaging.instance.getToken() ?? '';
      print("✅ Retried FCM token: $fcmDeviceToken");
    } catch (e) {
      print("❌ Still failed to fetch token later: $e");
    }
  }
}

List<String> generateSearchKeywords(String text) {
  return text
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toSet()
      .toList();
}

// Utility function
int getDaysInMonth(int year, int month) {
  if (month == 2) {
    // Check for leap year
    if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
      return 29;
    }
    return 28;
  }

  const monthsWith30Days = [4, 6, 9, 11]; // April, June, September, November
  return monthsWith30Days.contains(month) ? 30 : 31;
}

String? validateConfirmPassword(
  String? password,
  String? confirmPassword,
  BuildContext context,
) {
  if (confirmPassword == null || confirmPassword.isEmpty) {
    return S.of(context).confirm_password;
  }

  if (password != confirmPassword) {
    return S.of(context).passwords_dont_match;
  }

  return null;
}

bool isArabic(String text) {
  // Arabic Unicode Range: \u0600-\u06FF
  final arabicRegex = RegExp(r'[\u0600-\u06FF]');

  return arabicRegex.hasMatch(text);
}

bool isEnglish(String text) {
  // English Unicode Range: \u0000-\u007F
  final englishRegex = RegExp(r'[\u0000-\u007F]');

  return englishRegex.hasMatch(text);
}

// Future<String> translate(String text) async {
//   String translatedText = '';
//   if (isArabic(text)) {
//     await translator
//         .translate(text, from: 'ar', to: 'en')
//         .then((value) => translatedText = value.toString());
//     return translatedText;
//   } else if (isEnglish(text)) {
//     await translator
//         .translate(text, from: 'en', to: 'ar')
//         .then((value) => translatedText = value.toString());
//     return translatedText;
//   }
//   return 'Language Is Not Found';
// }

Future<void> launchPhoneApp(String phoneNumber) async {
  final Uri url = Uri(scheme: 'tel', path: (phoneNumber));

  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    log('Could not launch this url');
  }
}

Future<void> launchGoogleMaps(String location) async {
  try {
    if (!await launchUrl(Uri.parse(location))) {
      throw Exception('Could not launch url');
    }
  } catch (e) {
    log('Error launching Google Maps: $e');
  }
}

void slideAnimation({
  required BuildContext context,
  required Widget destination,
  bool rightSlide = true,
  bool bottomSlide = false,
  bool bottomRightSlide = false,
  bool smoothBottomRightSlide = false,
  bool topRightSlide = false,
  bool smoothTopRightSlide = false,
  bool topSlide = false,
  bool leftSlide = false,
  bool smoothBottomLeftSlide = false,
  bool bottomLeftSlide = false,
  bool topLeftSlide = false,
  bool customDuration = false,
  int duration = 300,
}) {
  Offset begin = const Offset(1.0, 0.0);
  Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: Duration(milliseconds: duration),
      reverseTransitionDuration: Duration(milliseconds: duration),
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (rightSlide == true) {
          begin = const Offset(1.0, 0.0);
        } else if (bottomSlide == true) {
          begin = const Offset(0.0, 1.0);
        } else if (bottomRightSlide == true) {
          begin = const Offset(0.5, 1.0);
        } else if (smoothBottomRightSlide == true) {
          begin = const Offset(1.0, 0.5);
        } else if (topSlide == true) {
          begin = const Offset(0.0, -1.0);
        } else if (topRightSlide == true) {
          begin = const Offset(0.5, -1.0);
        } else if (smoothTopRightSlide == true) {
          begin = const Offset(1.0, -0.5);
        } else if (smoothBottomLeftSlide == true) {
          begin = const Offset(-1.0, 0.5);
        } else if (bottomLeftSlide == true) {
          begin = const Offset(-1.0, 1.0);
        } else if (topLeftSlide == true) {
          begin = const Offset(-1.0, -1.0);
        } else if (leftSlide == true) {
          begin = const Offset(-1.0, 0.0);
        } else {
          begin = const Offset(1.0, 0.0);
        }
        Offset end = Offset.zero;
        var curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    ),
  );
}
