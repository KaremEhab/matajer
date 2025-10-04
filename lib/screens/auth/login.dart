import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/login/login_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/auth/forget_password.dart';
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/widgets/custom_form_field.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool visible = true;
  bool loading = false;

  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  bool isInitialInternetAvailable = true;

  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      isInitialInternetAvailable = result != ConnectivityResult.none;
    });
    print("isConnected: $isInitialInternetAvailable");
  }

  @override
  void initState() {
    super.initState();
    checkConnectivity(); // Initial check

    // ✅ Start listening to changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected != isInitialInternetAvailable) {
        setState(() {
          isInitialInternetAvailable = connected;
        });
      }
      print("Login Connectivity changed: isConnected = $connected");
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccessState) {
            navigateAndFinish(context: context, screen: const Layout());
          } else if (state is LoginErrorState) {
            showFlushBar(context: context, message: state.error);
          }

          if (state is SignInWithGuestSuccessState) {
            navigateAndFinish(context: context, screen: const Layout());
          } else if (state is LoginErrorState) {
            showFlushBar(context: context, message: state.error);
          }

          if (state is SignInWithGoogleLoadingState) {
            loading = !loading;
          } else if (state is SignInWithGoogleErrorState) {
            showFlushBar(context: context, message: state.error);
          }

          if (state is SignInWithFacebookLoadingState) {
            loading = !loading;
          } else if (state is SignInWithFacebookErrorState) {
            showFlushBar(context: context, message: state.error);
          }

          if (state is SignInWithAppleLoadingState) {
            loading = !loading;
          } else if (state is SignInWithAppleErrorState) {
            showFlushBar(context: context, message: state.error);
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Container(
                        height: 0.09.sh,
                        width: 0.09.sh,
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.w,
                          vertical: 20.h,
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.r),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primaryColor, primaryDarkColor],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: logoShadowColor,
                              offset: Offset(0, 5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: SvgPicture.asset('images/matajr_logo.svg'),
                      ),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 15,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 0.85.sw,
                              child: Text(
                                S.of(context).welcome_get_started,
                                style: TextStyle(
                                  height: 1.1,
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Row(
                              children: [
                                Text(
                                  S.of(context).dont_have_account,
                                  style: TextStyle(
                                    height: 1.1,
                                    color: textColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    slideAnimation(
                                      context: context,
                                      destination: const SignUp(),
                                    );
                                  },
                                  child: Text(
                                    S.of(context).click_here,
                                    style: TextStyle(
                                      height: 1.1,
                                      color: primaryColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30.h),
                            Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomFormField(
                                    hint: S.of(context).email_address,
                                    maxLines: 1,
                                    onTap: () {},
                                    keyboardType: TextInputType.emailAddress,
                                    controller: emailController,
                                    validator: (email) =>
                                        validateEmail(email, context),
                                  ),
                                  SizedBox(height: 13.h),
                                  CustomFormField(
                                    hint: '*************',
                                    maxLines: 1,
                                    obscure: visible,
                                    onTap: () {},
                                    controller: passController,
                                    suffix: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          visible = !visible;
                                        });
                                      },
                                      icon: Icon(
                                        visible
                                            ? Icons.lock
                                            : Icons.lock_open_rounded,
                                      ),
                                    ),
                                    validator: (pass) {
                                      if (pass!.isEmpty) {
                                        return S
                                            .of(context)
                                            .password_is_required;
                                      }
                                      return null;
                                    },
                                    // validator: (pass) =>
                                    //     validatePassword(pass, context),
                                  ),
                                  SizedBox(height: 6.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        slideAnimation(
                                          context: context,
                                          destination: ForgetPasswordScreen(),
                                        );
                                      },
                                      child: Text(
                                        S.of(context).forget_password,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7),
                        child: Column(
                          children: [
                            Column(
                              spacing: 10,
                              children: [
                                Center(
                                  child: Material(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: !isInitialInternetAvailable
                                          ? () {
                                              snack(context);
                                            }
                                          : () {
                                              log(
                                                "isInitialInternetAvailable: $isInitialInternetAvailable",
                                              );
                                              if (formKey.currentState!
                                                  .validate()) {
                                                isGuest = false;
                                                CacheHelper.saveData(
                                                  key: "isGuest",
                                                  value: isGuest,
                                                );
                                                LoginCubit.get(
                                                  context,
                                                ).userLogin(
                                                  email: emailController.text,
                                                  password: passController.text,
                                                  context: context,
                                                );
                                              }
                                            },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 23,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Center(
                                          child: loading
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  state is LoginSuccessState
                                                      ? S
                                                            .of(context)
                                                            .signed_in_success
                                                      : state
                                                            is LoginLoadingState
                                                      ? S.of(context).loading
                                                      : S.of(context).lets_go,
                                                  style: TextStyle(
                                                    color: scaffoldColor,
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Material(
                                    color: transparentColor,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: !isInitialInternetAvailable
                                          ? () {
                                              snack(context);
                                            }
                                          : () {
                                              LoginCubit.get(
                                                context,
                                              ).signInAnonymously(context);
                                            },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: greyColor.withOpacity(0.3),
                                            strokeAlign:
                                                BorderSide.strokeAlignOutside,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              size: 22,
                                              color: greyColor,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              S.of(context).continue_as_guest,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 30.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: greyColor.withOpacity(0.2),
                                      thickness: 2,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                    ),
                                    child: Text(
                                      S.of(context).or_sign_up_with,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: greyColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: greyColor.withOpacity(0.2),
                                      thickness: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (Platform.isIOS)
                              Center(
                                child: Material(
                                  color: transparentColor,
                                  borderRadius: BorderRadius.circular(20.r),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20.r),
                                    onTap: !isInitialInternetAvailable
                                        ? () {
                                            snack(context);
                                          }
                                        : () {
                                            isGuest = false;
                                            CacheHelper.saveData(
                                              key: "isGuest",
                                              value: isGuest,
                                            );
                                            LoginCubit.get(
                                              context,
                                            ).appleSignIn(context);
                                          },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: greyColor.withOpacity(0.3),
                                          strokeAlign:
                                              BorderSide.strokeAlignOutside,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'images/apple-icon-2.svg',
                                            width: 23,
                                          ),
                                          SizedBox(width: 11.w),
                                          Text(
                                            S.of(context).continue_apple,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (!Platform.isIOS) SizedBox(height: 15.h),
                            // google Icon
                            if (!Platform.isIOS)
                              Center(
                                child: Material(
                                  color: transparentColor,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: !isInitialInternetAvailable
                                        ? () {
                                            snack(context);
                                          }
                                        : () {
                                            isGuest = false;
                                            CacheHelper.saveData(
                                              key: "isGuest",
                                              value: isGuest,
                                            );
                                            LoginCubit.get(
                                              context,
                                            ).googleSignIn(context);
                                          },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: greyColor.withOpacity(0.3),
                                          strokeAlign:
                                              BorderSide.strokeAlignOutside,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'images/google-icon.svg',
                                            width: 25,
                                          ),
                                          SizedBox(width: 12.w),
                                          Text(
                                            S.of(context).continue_google,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 15.h),
                            // apple Icon
                            // facebook Icon
                            Center(
                              child: Material(
                                color: transparentColor,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: !isInitialInternetAvailable
                                      ? () {
                                          snack(context);
                                        }
                                      : () {
                                          isGuest = false;
                                          CacheHelper.saveData(
                                            key: "isGuest",
                                            value: isGuest,
                                          );
                                          LoginCubit.get(
                                            context,
                                          ).facebookSignIn(context);
                                        },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: greyColor.withOpacity(0.3),
                                        strokeAlign:
                                            BorderSide.strokeAlignOutside,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'images/facebook-icon.svg',
                                          color: blueColor,
                                          width: 23,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          S.of(context).continue_facebook,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
