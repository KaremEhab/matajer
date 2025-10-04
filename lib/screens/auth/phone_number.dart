import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/register/register_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/auth/confirm_phone_number.dart';
import 'package:matajer/screens/layout.dart';

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({
    super.key,
    this.hideBackButton = false,
    this.displaySkipBtn = false,
  });

  final bool hideBackButton, displaySkipBtn;

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  TextEditingController phoneNumberController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String phone = '';
  bool loading = false;
  bool isValidNumber = false; // ✅ NEW

  PhoneNumber number = PhoneNumber(isoCode: 'AE');

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterCubit, RegisterState>(
      listener: (context, state) {
        log('📦 Bloc State: $state'); // Add this
        if (state is RegisterSendOtpSuccessState) {
          log('➡️ Navigating to ConfirmPhoneNumber');
          slideAnimation(
            context: context,
            destination: ConfirmPhoneNumber(
              verificationId: state.verificationId,
            ),
          );
        } else if (state is RegisterPhoneLoadingState) {
          loading = !loading;
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40.h),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          !widget.hideBackButton
                              ? Material(
                                  color: lightGreyColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(13.r),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(13.r),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // if (state
                                      //     is RegisterCreateUserSuccessState) {
                                      //   showFlushBar(
                                      //     context: context,
                                      //     message: S
                                      //         .of(context)
                                      //         .registration_warning,
                                      //   );
                                      // } else {
                                      //   Navigator.pop(context);
                                      // }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        backIcon(),
                                        color: textColor,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(width: 1),
                          if (widget.displaySkipBtn)
                            Material(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(13.r),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13.r),
                                onTap: () {
                                  navigateAndFinish(
                                    context: context,
                                    screen: const Layout(),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    spacing: 5,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        S.of(context).skip,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Icon(forwardIcon(), color: primaryColor),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 0.87.sw,
                          child: Text(
                            S.of(context).authenticate_account,
                            style: TextStyle(
                              height: 1.1,
                              color: textColor,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Text(
                          S.of(context).checkout_requires_phone,
                          style: TextStyle(
                            height: 1.3,
                            color: lightGreyColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Form(
                    key: formKey,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 25.w),
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      decoration: BoxDecoration(
                        color: formFieldColor,
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: InternationalPhoneNumberInput(
                        onInputChanged: (PhoneNumber number) {
                          setState(() {
                            phone = number.phoneNumber ?? '';
                          });

                          // if (number.isoCode != 'AE') {
                          //   // Force it back to UAE
                          //   phoneNumberController.text = '+971';
                          // }
                        },
                        onInputValidated: (bool value) {
                          log('Phone valid: $value');
                          setState(() {
                            isValidNumber = value; // ✅ UPDATE VALIDITYa
                          });
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                          setSelectorButtonAsPrefixIcon: true,
                          showFlags: true,
                        ),
                        ignoreBlank: false,
                        autoValidateMode: AutovalidateMode.disabled,
                        selectorTextStyle: const TextStyle(color: Colors.black),
                        initialValue: number,
                        textFieldController: phoneNumberController,
                        formatInput: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        inputBorder: const OutlineInputBorder(),
                        onSaved: (PhoneNumber number) {
                          log('On Saved: $number');
                        },
                        validator: (phone) {
                          if (phone == null || phone.isEmpty) {
                            return S.of(context).add_phone_prompt;
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Center(
                      child: Material(
                        color: primaryColor,
                        shadowColor: logoShadowColor,
                        elevation: 16,
                        borderRadius: BorderRadius.circular(20.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20.r),
                          onTap: () {
                            log('last phone number: $phone');
                            if (formKey.currentState!.validate()) {
                              if (!isValidNumber) {
                                showFlushBar(
                                  context: context,
                                  message: S.of(context).enter_valid_phone,
                                );
                                return;
                              }
                              RegisterCubit.get(
                                context,
                              ).sendOtp(phoneNumber: phone);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 23.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Center(
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      S.of(context).submit,
                                      style: TextStyle(
                                        height: 1.1,
                                        color: scaffoldColor,
                                        fontSize: 19.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
