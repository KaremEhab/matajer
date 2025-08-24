import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/auth/login.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/screens/splash.dart';

class MatajerSplash extends StatefulWidget {
  const MatajerSplash({super.key});

  @override
  State<MatajerSplash> createState() => _MatajerSplashState();
}

class _MatajerSplashState extends State<MatajerSplash>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  int _dotCount = 1;
  Timer? _dotTimer;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _visible = true;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();

    _dotTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => mounted ? setState(() => _dotCount = (_dotCount % 3) + 1) : null,
    );

    _askPermissions().then((_) => _initializeApp());
  }

  Future<void> _askPermissions() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        // Handle permanently denied case
        return;
      }

      // Now check if service is enabled AFTER permission
      if (!await Geolocator.isLocationServiceEnabled()) {
        // Optionally prompt user to enable location services
        return;
      }
    } catch (e) {
      debugPrint("❌ Permission error: $e");
    }
  }

  Future<void> _initializeApp() async {
    if (uId.isEmpty && !skipOnboarding) {
      await GoogleSignIn().signOut();
      _navigateTo(const Splash());
    } else if (uId.isEmpty && skipOnboarding) {
      await GoogleSignIn().signOut();
      _navigateTo(const Login());
    } else {
      final userCubit = UserCubit();
      final favCubit = FavoritesCubit();

      await userCubit.getUserData();
      if (isSeller) {
        await userCubit.getShop();
      } else {
        await favCubit.getFavorites(userId: uId);
      }
      _navigateTo(const Layout(getUserData: false));
    }
  }

  void _navigateTo(Widget target) async {
    if (!mounted) return;
    _controller.reverse();
    await Future.delayed(
      _controller.duration ?? const Duration(milliseconds: 200),
    );
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => target));
  }

  String get loadingDots => '.' * _dotCount;

  @override
  void dispose() {
    _controller.dispose();
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        statusBarColor: Colors.white,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color: const Color(0xFFF7F7F7),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: SvgPicture.asset(
                    "images/matajr_logo.svg",
                    height: 90,
                    width: 90,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    S.of(context).matajer,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 900),
                  child: Text(
                    '${S.of(context).loading}$loadingDots',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
