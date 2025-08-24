import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/auth/login.dart';
import 'package:matajer/screens/settings/account_settings.dart';
import 'package:matajer/screens/settings/address.dart';
import 'package:matajer/screens/settings/change_email.dart';
import 'package:matajer/screens/settings/change_password.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  ScrollController scrollController = ScrollController();
  bool isVisible = true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        setState(() {
          isVisible = false;
        });
      } else {
        setState(() {
          isVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  List<String> title = [
    'Account Settings',
    'Saved Address',
    'Change Email',
    'Change Password',
  ];
  List<Widget> page = [
    const AccountSettings(),
    const SavedAddress(),
    const ChangeEmail(),
    const ChangePassword(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leadingWidth: 53,
        leading: Padding(
          padding: EdgeInsets.fromLTRB(7, 6, 0, 6),
          child: Material(
            color: lightGreyColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () {
                Navigator.pop(context);
              },
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_left_rounded,
                  color: textColor,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        child: ListView.builder(
          itemCount: title.length,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return ListTile(
              onTap: () {
                slideAnimation(
                  context: context,
                  destination: page[index],
                  rightSlide: true,
                );
              },
              titleTextStyle: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
              title: Text(title[index]),
              trailing: Icon(Icons.keyboard_arrow_right_rounded, size: 25),
            );
          },
        ),
      ),
      bottomNavigationBar: Material(
        color: transparentColor,
        child: AnimatedContainer(
          height: isVisible ? 0.1.sh : 0,
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
                    color: Colors.red,
                    elevation: 15,
                    shadowColor: Colors.red.withOpacity(0.5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17.r),
                      onTap: () async {
                        try {
                          await Future.wait([
                            CacheHelper.removeData(key: 'uId'),
                            UserCubit.get(context).setActivityStatus(
                              userId: uId,
                              statusValue: UserActivityStatus.offline.name,
                            ),
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(uId)
                                .update({
                                  'fcmTokens': FieldValue.arrayRemove([
                                    fcmDeviceToken,
                                  ]),
                                }),
                          ]);
                        } catch (e) {
                          print(e);
                        }
                        if (!context.mounted) return;
                        isSeller = false;
                        navigateAndFinish(
                          context: context,
                          screen: const Login(),
                        );
                      },
                      child: Center(
                        child: Text(
                          'Log Out',
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
    );
  }
}
