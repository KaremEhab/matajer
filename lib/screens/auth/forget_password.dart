import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/login/login_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/widgets/custom_form_field.dart';

class ForgetPasswordScreen extends StatelessWidget {
  ForgetPasswordScreen({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginForgetPasswordSuccessState) {
          showFlushBar(
            context: context,
            message: S.of(context).email_sent_success,
          );
        } else if (state is LoginForgetPasswordErrorState) {
          showFlushBar(context: context, message: state.error);
        }
      },
      builder: (context, state) {
        return Scaffold(
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
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.keyboard_arrow_left_rounded,
                            color: textColor,
                          ),
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
                          S.of(context).reset_password_tip,
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
                        S.of(context).reset_password_tip_2,
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
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: CustomFormField(
                      hint: S.of(context).email_address,
                      onTap: () {},
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (email) => validateEmail(email, context),
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
                          if (_formKey.currentState!.validate()) {
                            LoginCubit.get(
                              context,
                            ).forgetPassword(email: _emailController.text);
                          }
                        },
                        child: Container(
                          height: 0.08.sh,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Center(
                            child: Text(
                              state is LoginForgetPasswordSuccessState
                                  ? S.of(context).email_sent_success
                                  : state is LoginForgetPasswordLoadingState
                                  ? S.of(context).loading
                                  : S.of(context).send_email,
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
        );
        //   Scaffold(
        //   appBar: AppBar(
        //     title: const Text('Forget Password'),
        //   ),
        //   body: Padding(
        //     padding: const EdgeInsets.all(16.0),
        //     child: Form(
        //       key: _formKey,
        //       child: Column(
        //         children: [
        //           CustomFormField(
        //             hint: 'Email',
        //             onTap: () {},
        //             controller: _emailController,
        //             keyboardType: TextInputType.emailAddress,
        //             validator: (value) {
        //               if (value!.isEmpty) {
        //                 return 'Please enter your email';
        //               }
        //               return null;
        //             },
        //           ),
        //           const SizedBox(height: 16),
        //           ElevatedButton(
        //             onPressed: () {
        //               if (_formKey.currentState!.validate()) {
        //                 LoginCubit.get(context).forgetPassword(
        //                   email: _emailController.text,
        //                 );
        //               }
        //             },
        //             child: const Text('Send Email'),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // );
      },
    );
  }
}
