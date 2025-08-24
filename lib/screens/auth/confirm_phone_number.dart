import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/layout.dart';
import 'package:otp_autofill/otp_autofill.dart';

import '../../cubit/register/register_cubit.dart';

class ConfirmPhoneNumber extends StatefulWidget {
  const ConfirmPhoneNumber({super.key, required this.verificationId});

  final String verificationId;

  @override
  State<ConfirmPhoneNumber> createState() => _ConfirmPhoneNumberState();
}

class _ConfirmPhoneNumberState extends State<ConfirmPhoneNumber> {
  TextEditingController phoneNumberController = TextEditingController();
  bool loading = false;
  List<TextEditingController> controllers = [];
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late OTPTextEditController controller;
  late OTPInteractor _otpInteractor;

  @override
  void initState() {
    super.initState();
    // Initialize text editing controllers for each OTP field
    for (int i = 0; i < 6; i++) {
      controllers.add(TextEditingController());
    }
    _initInteractor();
    controller = OTPTextEditController(
      codeLength: 5,
      onCodeReceive: (code) => print('Your Application receive code - $code'),
      otpInteractor: _otpInteractor,
    )..startListenUserConsent((code) {
      final exp = RegExp(r'(\d{5})');
      return exp.stringMatch(code ?? '') ?? '';
    }, strategies: [SampleStrategy()]);
  }

  Future<void> _initInteractor() async {
    _otpInteractor = OTPInteractor();

    // You can receive your app signature by using this method.
    final appSignature = await _otpInteractor.getAppSignature();

    print('Your app signature: $appSignature');
  }

  @override
  void dispose() {
    controller.stopListen();
    // Dispose of text editing controllers to prevent memory leaks
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state is RegisterVerifyPhoneSuccessState) {
          navigateAndFinish(context: context, screen: const Layout());
        } else if (state is RegisterVerifyPhoneLoadingState) {
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
                      padding: EdgeInsets.symmetric(horizontal: 25.w),
                      child: Material(
                        color: lightGreyColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(13.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13.r),
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(backIcon(), color: textColor, size: 26,),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 25.w,
                      vertical: 15.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 0.87.sw,
                          child: Text(
                            S.of(context).confirm_phone_digits,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < controllers.length; i++)
                          Container(
                            width: 55.w,
                            height: 75.h,
                            margin: EdgeInsets.symmetric(horizontal: 5.w),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            decoration: BoxDecoration(
                              color: formFieldColor,
                              borderRadius: BorderRadius.circular(16.r),
                              border:
                                  controllers[i].text.isNotEmpty
                                      ? Border.all(
                                        color: textColor,
                                        width: 2.5.w,
                                        strokeAlign:
                                            BorderSide.strokeAlignOutside,
                                      )
                                      : null,
                            ),
                            child: Center(
                              child: TextField(
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  fontSize: 23.sp,
                                ),
                                controller: controllers[i],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(1),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    controllers[i];
                                  });
                                  if (value.isEmpty && i > 0) {
                                    FocusScope.of(context).previousFocus();
                                  } else if (value.isNotEmpty &&
                                      i < controllers.length - 1) {
                                    FocusScope.of(context).nextFocus();
                                  }
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Center(
                    child: Text(
                      S.of(context).enter_six_digits,
                      style: TextStyle(
                        color: lightGreyColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
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
                            if (formKey.currentState!.validate()) {
                              String smsCode = '';
                              for (int i = 0; i < controllers.length; i++) {
                                smsCode += controllers[i].text;
                              }
                              RegisterCubit.get(context).verifyPhoneNumber(
                                verificationId: widget.verificationId,
                                smsCode: smsCode,
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 23.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Center(
                              child:
                                  loading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        S.of(context).confirm,
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

class SampleStrategy extends OTPStrategy {
  @override
  Future<String> listenForCode() {
    return Future.delayed(
      const Duration(seconds: 4),
      () => 'Your code is 54321',
    );
  }
}

// await FirebaseAuth.instance.verifyPhoneNumber(
//                         phoneNumber:
//                             "+${sellerController.countryCode} ${sellerController.mobileNumberController.text}",
//                         // phoneNumber: "+91 9510987832",
//                         verificationCompleted: (PhoneAuthCredential credential) {
//                           Get.toNamed("/SellerAddressDetails");
//                         },
//                         verificationFailed: (FirebaseAuthException e) {
//                           Fluttertoast.showToast(
//                               msg: "Mobile Verification Failed",
//                               toastLength: Toast.LENGTH_SHORT,
//                               gravity: ToastGravity.SNACKBAR,
//                               timeInSecForIosWeb: 2,
//                               backgroundColor: MyColors.primaryPink,
//                               textColor: MyColors.white,
//                               fontSize: 16.0);
//                         },
//                         codeSent: (String verificationId, int? resendToken) {
//                           Fluttertoast.showToast(
//                               msg: St.otpSendSuccessfully,
//                               toastLength: Toast.LENGTH_SHORT,
//                               gravity: ToastGravity.SNACKBAR,
//                               timeInSecForIosWeb: 2,
//                               backgroundColor: MyColors.primaryPink,
//                               textColor: MyColors.white,
//                               fontSize: 16.0);
//                         },
//                         codeAutoRetrievalTimeout: (String verificationId) {},
//                       );
