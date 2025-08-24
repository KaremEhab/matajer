import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/cubit/user/user_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/widgets/custom_form_field.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmNewPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserChangePasswordSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).password_changed_successfully),
              backgroundColor: primaryColor,
            ),
          );
        } else if (state is UserChangePasswordErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            leadingWidth: 53,
            leading: Padding(
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
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15.h),
                  Text(
                    S.of(context).change_password,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    S.of(context).change_password_subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      height: 1.1,
                      color: textColor.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 25.h),
                  Form(
                    key: formKey,
                    child: Column(
                      spacing: 10,
                      children: [
                        CustomFormField(
                          hasTitle: true,
                          textColor: textColor,
                          title: S.of(context).your_old_password,
                          hint: S.of(context).hint_old_password,
                          onTap: () {},
                          validator: (value) {
                            if (value!.isEmpty) {
                              return S.of(context).enter_password;
                            }
                            return null;
                          },
                          controller: oldPasswordController,
                        ),
                        CustomFormField(
                          hasTitle: true,
                          textColor: textColor,
                          title: S.of(context).your_new_password,
                          hint: S.of(context).hint_new_password,
                          onTap: () {},
                          validator: (pass) => validatePassword(pass, context),
                          controller: newPasswordController,
                        ),
                        CustomFormField(
                          hasTitle: true,
                          textColor: textColor,
                          title: S.of(context).your_new_password_confirmation,
                          hint: S.of(context).hint_confirm_password,
                          validator: (confPass) => validateConfirmPassword(
                            newPasswordController.text,
                            confPass,
                            context,
                          ),
                          onTap: () {},
                          controller: confirmNewPasswordController,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Material(
              color: transparentColor,
              child: AnimatedContainer(
                height: 0.1.sh,
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 0.07.sh,
                        width: 0.9.sw,
                        child: Material(
                          borderRadius: BorderRadius.circular(17.r),
                          color: primaryColor,
                          elevation: 15,
                          shadowColor: primaryColor.withOpacity(0.5),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(17.r),
                            onTap: () {
                              if (formKey.currentState!.validate()) {
                                UserCubit.get(context).changePassword(
                                  currentPassword: oldPasswordController.text,
                                  newPassword: newPasswordController.text,
                                );
                              }
                            },
                            child: Center(
                              child: Text(
                                S.of(context).submit,
                                style: TextStyle(
                                  height: 0.8,
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
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
            ),
          ),
        );
      },
    );
  }
}
