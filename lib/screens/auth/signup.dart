import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/register/register_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/auth/login.dart';
import 'package:matajer/screens/auth/phone_number.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/widgets/custom_form_field.dart';

enum UsernameStatus { available, notAvailable, loading, initial }

class SignUp extends StatefulWidget {
  const SignUp({
    super.key,
    this.socialInfo = false,
    this.username,
    this.email,
    this.uId,
    this.profilePic,
    this.phoneNumber,
  });

  final bool? socialInfo;
  final String? username, email, uId, profilePic, phoneNumber;

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController emailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confPassController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  UsernameStatus usernameStatus = UsernameStatus.initial;
  bool visible = true;
  bool confVisible = true;

  String? selectedEmirate;
  DateTime? selectedBirthdate;
  int? selectedAge;
  Gender selectedGender = Gender.male;

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
      print("Sign Up Connectivity changed: isConnected = $connected");
    });
  }

  // To calculate age from birthdate
  int calculateAge(DateTime birthdate) {
    final today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  Timer? _checkTypingTimer;

  Future<bool> checkUsername(String username) async {
    try {
      QuerySnapshot<Map<String, dynamic>> value = await FirebaseFirestore
          .instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      log('checking username: ${value.docs.isEmpty}');
      return value.docs.isEmpty;
    } catch (e) {
      log('error checking username: $e');
      return false;
    }
  }

  void startTimer(String username) {
    _checkTypingTimer = Timer(const Duration(milliseconds: 400), () async {
      //set your desired duration
      if (username.isEmpty) {
        setState(() {
          usernameStatus = UsernameStatus.initial;
        });
        return;
      }
      log('checking username: $username');
      bool isAvailable = await checkUsername(username);
      log('isAvailable: $isAvailable');
      setState(() {
        usernameStatus = isAvailable
            ? UsernameStatus.available
            : UsernameStatus.notAvailable;
      });
    });
  }

  void resetTimer(String username) {
    _checkTypingTimer?.cancel();
    startTimer(username);
  }

  bool loading = false;

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterCubit, RegisterState>(
      listener: (context, state) async {
        if (state is RegisterCreateUserSuccessState) {
          if (widget.socialInfo! &&
              (widget.phoneNumber != null || widget.phoneNumber != '')) {
            navigateAndFinish(context: context, screen: Layout());
          } else {
            navigateAndFinish(
              context: context,
              screen: const PhoneNumberPage(displaySkipBtn: true),
            );
          }
        } else if (state is RegisterErrorState) {
          showFlushBar(context: context, message: state.error);
        } else if (state is RegisterCreateUserErrorState) {
          showFlushBar(context: context, message: state.error);
        }

        if (state is SignUpWithGoogleLoadingState) {
          loading = !loading;
        } else if (state is SignUpWithGoogleErrorState) {
          showFlushBar(context: context, message: state.error);
        }

        if (state is SignUpWithFacebookLoadingState) {
          loading = !loading;
        } else if (state is SignUpWithFacebookErrorState) {
          showFlushBar(context: context, message: state.error);
        }

        if (state is SignUpWithAppleLoadingState) {
          loading = !loading;
        } else if (state is SignUpWithAppleErrorState) {
          showFlushBar(context: context, message: state.error);
        }
      },
      builder: (context, state) {
        // Define variables at the top of your State class
        final Map<String, String> emiratesMap = {
          S.of(context).abu_dhabi: "abu dhabi",
          S.of(context).dubai: "dubai",
          S.of(context).sharjah: "sharjah",
          S.of(context).ajman: "ajman",
          S.of(context).umm_al_quwain: "umm al-quwain",
          S.of(context).ras_al_khaimah: "ras al khaimah",
          S.of(context).fujairah: "fujairah",
          S.of(context).gharbya: "gharbya",
          S.of(context).al_ain: "al-ain",
        };

        return Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            leadingWidth: 52,
            leading: widget.socialInfo!
                ? null
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      lang == 'en' ? 7 : 0,
                      6,
                      lang == 'en' ? 0 : 7,
                      6,
                    ),
                    child: Material(
                      color: lightGreyColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Center(
                          child: Icon(backIcon(), color: textColor, size: 26),
                        ),
                      ),
                    ),
                  ),
            centerTitle: true,
            title: Text(
              widget.socialInfo!
                  ? S.of(context).complete_all_fields
                  : S.of(context).sign_up,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!widget.socialInfo!)
                              SizedBox(
                                width: 0.85.sw,
                                child: Text(
                                  S.of(context).welcome_create_account,
                                  style: TextStyle(
                                    height: 1.1,
                                    color: textColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (!widget.socialInfo!) SizedBox(height: 15.h),
                            if (!widget.socialInfo!)
                              Row(
                                children: [
                                  Text(
                                    S.of(context).have_account,
                                    style: TextStyle(
                                      height: 1.1,
                                      color: textColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      navigateReplacement(
                                        context: context,
                                        screen: Login(),
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
                            if (!widget.socialInfo!) SizedBox(height: 30.h),
                            Form(
                              key: formKey,
                              child: Column(
                                spacing: 10,
                                children: [
                                  // SizedBox(height: 13.h),
                                  if (!widget.socialInfo!)
                                    CustomFormField(
                                      onSubmit: (val) async {
                                        if (val!.isEmpty) {
                                          setState(() {
                                            usernameStatus =
                                                UsernameStatus.notAvailable;
                                          });
                                          return;
                                        }
                                        setState(() {
                                          usernameStatus ==
                                              UsernameStatus.loading;
                                        });
                                      },
                                      suffix:
                                          usernameStatus ==
                                              UsernameStatus.loading
                                          ? const CupertinoActivityIndicator(
                                              color: primaryColor,
                                            )
                                          : Icon(
                                              usernameStatus ==
                                                      UsernameStatus.initial
                                                  ? null
                                                  : usernameStatus ==
                                                        UsernameStatus.available
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color:
                                                  usernameStatus ==
                                                      UsernameStatus.available
                                                  ? CupertinoColors.systemGreen
                                                  : CupertinoColors.systemRed,
                                            ),
                                      hint: S.of(context).username,
                                      maxLines: 1,
                                      onChanged: (val) {
                                        resetTimer(val.toString());
                                      },
                                      onTap: () {},
                                      controller: usernameController,
                                      validator: (username) =>
                                          validateUsername(context, username),
                                    ),
                                  // SizedBox(height: 13.h),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: S.of(context).select_emirate,
                                      labelStyle: TextStyle(
                                        color: textColor.withOpacity(0.5),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                    ),
                                    value: selectedEmirate,
                                    items: emiratesMap.keys
                                        .map(
                                          (localizedName) => DropdownMenuItem(
                                            value: localizedName,
                                            child: Text(localizedName),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedEmirate = val!;
                                      });
                                    },
                                    validator: (val) => val == null
                                        ? S.of(context).please_select_emirate
                                        : null,
                                  ),

                                  GestureDetector(
                                    onTap: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime(2000),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                      );

                                      if (pickedDate != null) {
                                        setState(() {
                                          selectedBirthdate = pickedDate;
                                          selectedAge = calculateAge(
                                            pickedDate,
                                          );
                                        });
                                      }
                                    },
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: S.of(context).birthdate,
                                          labelStyle: TextStyle(
                                            // fontWeight: FontWeight.w500,
                                            color: textColor.withOpacity(0.5),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                          suffixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                        ),
                                        controller: TextEditingController(
                                          text: selectedBirthdate == null
                                              ? ''
                                              : '${selectedBirthdate!.day}/${selectedBirthdate!.month}/${selectedBirthdate!.year}',
                                        ),
                                        validator: (_) =>
                                            selectedBirthdate == null
                                            ? S
                                                  .of(context)
                                                  .please_select_birthdate
                                            : null,
                                      ),
                                    ),
                                  ),

                                  if (!widget.socialInfo!)
                                    CustomFormField(
                                      hint: S.of(context).email_address,
                                      maxLines: 1,
                                      onTap: () {},
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (email) =>
                                          validateEmail(email, context),
                                    ),

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
                                    validator: (pass) =>
                                        validatePassword(pass, context),
                                  ),

                                  CustomFormField(
                                    hint: '*************',
                                    maxLines: 1,
                                    obscure: confVisible,
                                    onTap: () {},
                                    controller: confPassController,
                                    suffix: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          confVisible = !confVisible;
                                        });
                                      },
                                      icon: Icon(
                                        confVisible
                                            ? Icons.lock
                                            : Icons.lock_open_rounded,
                                      ),
                                    ),
                                    validator: (confPass) =>
                                        validateConfirmPassword(
                                          passController.text,
                                          confPass,
                                          context,
                                        ),
                                  ),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: Gender.values.map((g) {
                                          return Expanded(
                                            child: RadioListTile<Gender>(
                                              activeColor: primaryColor,
                                              title: Text(
                                                getLocalizedGender(context, g),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      selectedGender.name ==
                                                          g.name
                                                      ? primaryColor
                                                      : textColor,
                                                  fontWeight:
                                                      selectedGender.name ==
                                                          g.name
                                                      ? FontWeight.w800
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                              value: g,
                                              groupValue: selectedGender,
                                              onChanged: (val) {
                                                setState(() {
                                                  selectedGender = val!;
                                                });
                                              },
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            Center(
                              child: Material(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(20.r),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20.r),
                                  onTap: !isInitialInternetAvailable
                                      ? () {
                                          snack(context);
                                        }
                                      : () async {
                                          if (widget.socialInfo!) {
                                            // Check password match
                                            if (passController.text !=
                                                confPassController.text) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    S
                                                        .of(context)
                                                        .passwords_dont_match,
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            final password = passController.text
                                                .trim();
                                            final email = widget.email!;

                                            try {
                                              final user = FirebaseAuth
                                                  .instance
                                                  .currentUser;

                                              // Link email/password to the current (Google) user
                                              final credential =
                                                  EmailAuthProvider.credential(
                                                    email: email,
                                                    password: password,
                                                  );

                                              await user!.linkWithCredential(
                                                credential,
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    S
                                                        .of(context)
                                                        .something_went_wrong,
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            // Now continue with userCreate as usual
                                            RegisterCubit.get(
                                              context,
                                            ).userCreate(
                                              userId: widget.uId!,
                                              username: widget.username!,
                                              email: email,
                                              phoneNumber:
                                                  widget.phoneNumber ?? "",
                                              phoneVerified:
                                                  widget.phoneNumber == null
                                                  ? false
                                                  : true,
                                              imageUrl: widget.profilePic!,
                                              emirate:
                                                  emiratesMap[selectedEmirate],
                                              gender: selectedGender,
                                              age: selectedAge,
                                              birthdate: selectedBirthdate,
                                            );
                                          } else {
                                            if (formKey.currentState!
                                                    .validate() &&
                                                usernameStatus ==
                                                    UsernameStatus.available) {
                                              if (passController.text !=
                                                  confPassController.text) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      S
                                                          .of(context)
                                                          .passwords_dont_match,
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                                return;
                                              }

                                              // If all checks passed, proceed to register
                                              RegisterCubit.get(
                                                context,
                                              ).userRegister(
                                                username: usernameController
                                                    .text
                                                    .trim(),
                                                emirate:
                                                    emiratesMap[selectedEmirate],
                                                gender: selectedGender,
                                                age: selectedAge,
                                                birthdate: selectedBirthdate,
                                                email: emailController.text,
                                                password: passController.text,
                                              );
                                            }
                                          }
                                        },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 23),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Center(
                                      child: loading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : Text(
                                              state
                                                      is RegisterCreateUserSuccessState
                                                  ? S
                                                        .of(context)
                                                        .created_successfully
                                                  : state
                                                        is RegisterCreateUserLoadingState
                                                  ? S.of(context).loading
                                                  : S.of(context).sign_up,
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
                            if (!widget.socialInfo!)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
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
                            // social Icons
                            if (!widget.socialInfo!)
                              Row(
                                spacing: 5,
                                children: [
                                  // apple Icon
                                  if (Platform.isIOS)
                                    Expanded(
                                      child: Center(
                                        child: Material(
                                          color: transparentColor,
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            onTap: !isInitialInternetAvailable
                                                ? () {
                                                    snack(context);
                                                  }
                                                : () {
                                                    RegisterCubit.get(
                                                      context,
                                                    ).appleSignUp(context);
                                                  },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 20,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: greyColor.withOpacity(
                                                    0.3,
                                                  ),
                                                  strokeAlign: BorderSide
                                                      .strokeAlignOutside,
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
                                                    S.of(context).apple,
                                                    style: TextStyle(
                                                      height: 1.1,
                                                      color: textColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // google Icon
                                  Expanded(
                                    child: Center(
                                      child: Material(
                                        color: transparentColor,
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          onTap: !isInitialInternetAvailable
                                              ? () {
                                                  snack(context);
                                                }
                                              : () {
                                                  RegisterCubit.get(
                                                    context,
                                                  ).googleSignUp(context);
                                                },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: greyColor.withOpacity(
                                                  0.3,
                                                ),
                                                strokeAlign: BorderSide
                                                    .strokeAlignOutside,
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
                                                SizedBox(width: 12),
                                                Text(
                                                  S.of(context).google,
                                                  style: TextStyle(
                                                    height: 1.1,
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
                                  ),

                                  // facebook Icon
                                  Expanded(
                                    child: Center(
                                      child: Material(
                                        color: transparentColor,
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          onTap: !isInitialInternetAvailable
                                              ? () {
                                                  snack(context);
                                                }
                                              : () {
                                                  RegisterCubit.get(
                                                    context,
                                                  ).facebookSignUp(context);
                                                },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: greyColor.withOpacity(
                                                  0.3,
                                                ),
                                                strokeAlign: BorderSide
                                                    .strokeAlignOutside,
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
                                                  S.of(context).facebook,
                                                  style: TextStyle(
                                                    height: 1.1,
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
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
