import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/screens/auth/login.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  int currentImageIndex = 0;

  PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: transparentColor,
        systemNavigationBarColor: Colors.white,
      ),
    );
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: AlignmentDirectional.topCenter,
            child: Image.asset(
              'images/girl_farm.png',
              height: 0.6.sh,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Container(
              height: 0.09.sh,
              width: 0.09.sh,
              margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.r),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, primaryDarkColor],
                ),
              ),
              child: SvgPicture.asset('images/matajr_logo.svg'),
            ),
          ),
          Positioned.fill(
            child: Container(
              height: 30.h,
              width: 1.sw,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    transparentColor,
                    textColor.withOpacity(0.4),
                    textColor.withOpacity(0.8),
                    textColor,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 5,
                          children: [
                            Text(
                              "Farm's Limited Company",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20, // Adjusted font size
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(Icons.verified, color: primaryColor, size: 22),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "4.8(325)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Adjusted font size
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Icon(IconlyBold.star, color: starColor, size: 20),
                          ],
                        ),
                        SizedBox(height: 15.h),
                        SizedBox(
                          width: 1.sw,
                          height: 5.h,
                          child: Center(
                            child: ListView.builder(
                              itemCount: 4,
                              shrinkWrap: true,
                              padding: EdgeInsets.only(right: 24.w),
                              physics: const NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (index != 0) SizedBox(width: 3.w),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width:
                                          currentImageIndex == index
                                              ? 20.w
                                              : 5.w,
                                      decoration: BoxDecoration(
                                        color:
                                            currentImageIndex == index
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(
                                          70.r,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      height: 0.4.sh,
                      width: 1.sw,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25.r),
                          topRight: Radius.circular(25.r),
                        ),
                        color: scaffoldColor,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.h, 30.h, 20.h, 0),
                        child: PageView.builder(
                          controller: pageController,
                          onPageChanged: (index) {
                            setState(() {
                              currentImageIndex = index;
                            });
                          },
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 0.86.sw,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Connecting You\nTo Unique Findings.",
                                          style: TextStyle(
                                            height: 1.1,
                                            color: textColor,
                                            fontSize: 30.h, // Adjusted font size
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: 7.h),
                                        Text(
                                          "Celebrating Home Grown Talent.",
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 14.h, // Adjusted font size
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        // SizedBox(height: 15.h),
                                        // Text(
                                        //   "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed faucibus augue au augue eget nisi eleifend ullamcorper. Integer vel augue ac ipsum ultrices.",
                                        //   style: TextStyle(
                                        //     height: 1.1,
                                        //     color: textColor.withOpacity(0.6),
                                        //     fontSize: 12.h, // Adjusted font size
                                        //   ),
                                        // ),
                                        SizedBox(height: 45.h),
                                      ],
                                    ),
                                  ),
                                  Center(
                                    child: Material(
                                      color: primaryColor,
                                      shadowColor: logoShadowColor,
                                      elevation: 6,
                                      borderRadius: BorderRadius.circular(20.r),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20.r),
                                        onTap: () {
                                          setState(() {
                                            skipOnboarding = true;
                                          });
                                          CacheHelper.saveData(
                                            key: 'skipOnboarding',
                                            value: skipOnboarding,
                                          );
                                          slideAnimation(
                                            context: context,
                                            destination: const Login(),
                                          );
                                        },
                                        child: Container(
                                          width: 0.95.sw,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 25.h,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "GET STARTED AS BUYER",
                                              style: TextStyle(
                                                color: scaffoldColor,
                                                fontSize:
                                                    14, // Adjusted font size
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
