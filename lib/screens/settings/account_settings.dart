import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/cubit/user/user_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/auth/phone_number.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/widgets/custom_form_field.dart';
import 'package:matajer/widgets/pick_image_source.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  XFile? selectedImage;
  String selectedGender = currentUserModel.gender.name;
  final List<String> genderOptions = ['male', 'female'];

  String getLocalizedGender(String gender, BuildContext context) {
    switch (gender) {
      case 'male':
        return S.of(context).male;
      case 'female':
        return S.of(context).female;
      default:
        return gender;
    }
  }

  bool genderExpanded = false;

  Future<void> pickOrTakeImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: S.current.crop_image,
            toolbarColor: scaffoldColor,
            toolbarWidgetColor: primaryColor,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: S.current.crop_image,
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          selectedImage = XFile(croppedFile.path);
          checkForChanges();
        });
      }
    } else {
      log('Image picking canceled');
    }
  }

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  DateTime birthdate = currentUserModel.birthdate;
  bool isVisible = true;
  bool hasChanges = false;

  late String initialUsername;
  late DateTime initialBirthdate;
  late String initialGender;

  @override
  void initState() {
    super.initState();

    // Make the status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // <-- شفافية
        // statusBarIconBrightness: Brightness.light, // لون الأيقونات
      ),
    );

    usernameController.text = currentUserModel.username;
    genderController.text = currentUserModel.gender.name;
    phoneNumberController.text = currentUserModel.phoneNumber.toString();
    birthdate = currentUserModel.birthdate;
    selectedGender = currentUserModel.gender.name;
    initialUsername = currentUserModel.username;
    initialBirthdate = currentUserModel.birthdate;
    initialGender = currentUserModel.gender.name;
  }

  void checkForChanges() {
    setState(() {
      hasChanges =
          usernameController.text.trim() != initialUsername ||
          birthdate != initialBirthdate ||
          selectedGender != initialGender ||
          selectedImage != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserUpdateBuyerDataSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).data_updated),
              backgroundColor: primaryColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 280.h,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  SizedBox(
                    height: 260.h,
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 0.25.sh,
                          color: primaryColor,
                          width: double.infinity,
                          child: Opacity(
                            opacity: 0.1,
                            child: Image.asset(
                              'images/shape.png',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 7,
                          right: 7,
                          child: SafeArea(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(7),
                                      child: Icon(
                                        backIcon(),
                                        color: textColor,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  S.of(context).account_settings,
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 37),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -80,
                          child: Center(
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(400),
                                      onTap: () {
                                        print("HHH");
                                        showModalBottomSheet(
                                          context: context,
                                          showDragHandle: true,
                                          backgroundColor: scaffoldColor,
                                          builder: (BuildContext context) {
                                            return PickImageSource(
                                              galleryButton: () {
                                                Navigator.pop(context);
                                                pickOrTakeImage(
                                                  ImageSource.gallery,
                                                );
                                              },
                                              cameraButton: () {
                                                Navigator.pop(context);
                                                pickOrTakeImage(
                                                  ImageSource.camera,
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(6.h),
                                        decoration: BoxDecoration(
                                          color: senderColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(5.h),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: CircleAvatar(
                                            radius: 70.h,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(200.r),
                                              child: selectedImage == null
                                                  ? (isSeller
                                                            ? (currentShopModel!
                                                                  .shopLogoUrl
                                                                  .isEmpty)
                                                            : (currentUserModel
                                                                          .profilePicture ==
                                                                      null ||
                                                                  currentUserModel
                                                                      .profilePicture!
                                                                      .isEmpty))
                                                        ? Icon(
                                                            IconlyBold.profile,
                                                            size: 55,
                                                          )
                                                        : CachedNetworkImage(
                                                            imageUrl: isSeller
                                                                ? currentShopModel!
                                                                      .shopLogoUrl
                                                                : currentUserModel
                                                                      .profilePicture
                                                                      .toString(),
                                                            progressIndicatorBuilder:
                                                                (
                                                                  context,
                                                                  url,
                                                                  progress,
                                                                ) =>
                                                                    shimmerPlaceholder(
                                                                      height:
                                                                          150.h,
                                                                      width:
                                                                          150.h,
                                                                      radius:
                                                                          200.r,
                                                                    ),
                                                            height: 150.h,
                                                            width: 150.h,
                                                            fit: BoxFit.cover,
                                                          )
                                                  : Image.file(
                                                      File(selectedImage!.path),
                                                      fit: BoxFit.cover,
                                                      height: 150.h,
                                                      width: 150.h,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      usernameController.text,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),

                                // Delete Button
                                if (selectedImage != null)
                                  Positioned(
                                    left: 20.w,
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedImage = null;
                                            checkForChanges();
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Edit Button
                                Positioned(
                                  right: 20.w,
                                  bottom: 40,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(400),
                                      onTap: () {
                                        print("KKKK");
                                        showModalBottomSheet(
                                          context: context,
                                          showDragHandle: true,
                                          backgroundColor: scaffoldColor,
                                          builder: (BuildContext context) {
                                            return PickImageSource(
                                              galleryButton: () {
                                                Navigator.pop(context);
                                                pickOrTakeImage(
                                                  ImageSource.gallery,
                                                );
                                              },
                                              cameraButton: () {
                                                Navigator.pop(context);
                                                pickOrTakeImage(
                                                  ImageSource.camera,
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: primaryColor.withOpacity(
                                              0.4,
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          IconlyBold.edit,
                                          color: primaryColor,
                                        ),
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
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Center(
                //   child: Stack(
                //     children: [
                //       Column(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: [
                //           InkWell(
                //             borderRadius: BorderRadius.circular(400),
                //             onTap: () {
                //               showModalBottomSheet(
                //                 context: context,
                //                 showDragHandle: true,
                //                 backgroundColor: scaffoldColor,
                //                 builder: (BuildContext context) {
                //                   return PickImageSource(
                //                     galleryButton: () {
                //                       Navigator.pop(context);
                //                       pickOrTakeImage(
                //                         ImageSource.gallery,
                //                       );
                //                     },
                //                     cameraButton: () {
                //                       Navigator.pop(context);
                //                       pickOrTakeImage(ImageSource.camera);
                //                     },
                //                   );
                //                 },
                //               );
                //             },
                //             child: Container(
                //               padding: EdgeInsets.all(6.h),
                //               decoration: BoxDecoration(
                //                 color: senderColor,
                //                 shape: BoxShape.circle,
                //               ),
                //               child: Container(
                //                 padding: EdgeInsets.all(5.h),
                //                 decoration: BoxDecoration(
                //                   color: primaryColor,
                //                   shape: BoxShape.circle,
                //                 ),
                //                 child: CircleAvatar(
                //                   radius: 70,
                //                   child: ClipRRect(
                //                     borderRadius: BorderRadius.circular(
                //                       200.r,
                //                     ),
                //                     child:
                //                         selectedImage == null
                //                             ? CachedNetworkImage(
                //                               imageUrl:
                //                                   isSeller
                //                                       ? currentShopModel!
                //                                           .shopLogoUrl
                //                                       : currentUserModel
                //                                           .profilePicture
                //                                           .toString(),
                //                               progressIndicatorBuilder:
                //                                   (
                //                                     context,
                //                                     url,
                //                                     progress,
                //                                   ) => shimmerPlaceholder(
                //                                     height: 150,
                //                                     width: 150,
                //                                     radius: 200.r,
                //                                   ),
                //                               height: 150,
                //                               width: 150,
                //                               fit: BoxFit.cover,
                //                             )
                //                             : Image.file(
                //                               File(selectedImage!.path),
                //                               fit: BoxFit.cover,
                //                               height: 150,
                //                               width: 150,
                //                             ),
                //                   ),
                //                 ),
                //               ),
                //             ),
                //           ),
                //           SizedBox(height: 5),
                //           Text(
                //             usernameController.text,
                //             style: TextStyle(
                //               fontSize: 20,
                //               fontWeight: FontWeight.w700,
                //             ),
                //           ),
                //         ],
                //       ),
                //       if (selectedImage != null)
                //         Positioned(
                //           right: 0,
                //           left: -90,
                //           child: Container(
                //             padding: EdgeInsets.all(5.h),
                //             decoration: BoxDecoration(
                //               color: Colors.white,
                //               shape: BoxShape.circle,
                //             ),
                //             child: InkWell(
                //               onTap: () {
                //                 setState(() {
                //                   selectedImage = null;
                //                   checkForChanges();
                //                 });
                //               },
                //               child: Icon(Icons.close, color: Colors.red),
                //             ),
                //           ),
                //         ),
                //
                //       Positioned(
                //         left: 0,
                //         right: -0.15.sw,
                //         bottom: 40,
                //         child: Material(
                //           color: Colors.white,
                //           shape: const CircleBorder(),
                //           child: Container(
                //             padding: EdgeInsets.all(5.h),
                //             decoration: BoxDecoration(
                //               shape: BoxShape.circle,
                //               border: Border.all(
                //                 color: primaryColor.withOpacity(0.4),
                //               ),
                //             ),
                //             child: Icon(
                //               IconlyBold.edit,
                //               color: primaryColor,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                Form(
                  key: formKey,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CustomFormField(
                              hasTitle: true,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return S.of(context).username_validation;
                                }
                                return null;
                              },
                              textColor: textColor,
                              title: S.of(context).username,
                              hint: S.of(context).fake_username_hint,
                              onTap: () {},
                              controller: usernameController,
                              onChanged: (val) {
                                setState(() {
                                  usernameController.text = val.toString();
                                  checkForChanges();
                                });
                              },
                            ),
                            Positioned(
                              left: lang == 'ar' ? 10 : null,
                              right: lang == 'en' ? 10 : null,
                              bottom: 8,
                              child: Chip(
                                label: Text(
                                  usernameController.text == "null"
                                      ? S.of(context).not_added
                                      : S.of(context).authentic,
                                  textDirection: ui.TextDirection.ltr,
                                  style: TextStyle(
                                    color: usernameController.text == "null"
                                        ? Colors.red
                                        : CupertinoColors.systemGreen,
                                  ),
                                ),
                                side: BorderSide.none,
                                backgroundColor:
                                    usernameController.text == "null"
                                    ? Colors.red.withOpacity(0.1)
                                    : CupertinoColors.systemGreen.withOpacity(
                                        0.15,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).birthdate,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                // Day
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final selectedDay =
                                          await showModalBottomSheet<int>(
                                            showDragHandle: true,
                                            backgroundColor: scaffoldColor,
                                            context: context,
                                            builder: (_) {
                                              final controller = ScrollController(
                                                initialScrollOffset:
                                                    (birthdate.day - 1) *
                                                    56.0, // Approx item height
                                              );

                                              return SafeArea(
                                                child: ListView.builder(
                                                  controller: controller,
                                                  itemCount: getDaysInMonth(
                                                    birthdate.year,
                                                    birthdate.month,
                                                  ),
                                                  itemBuilder: (context, index) {
                                                    final day = index + 1;
                                                    final isSelected =
                                                        birthdate.day == day;

                                                    return ListTile(
                                                      tileColor: isSelected
                                                          ? primaryColor
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                          : null,
                                                      title: Center(
                                                        child: Text(
                                                          '$day',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                            color: isSelected
                                                                ? primaryColor
                                                                : null,
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                            context,
                                                            day,
                                                          ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          );

                                      if (selectedDay != null) {
                                        setState(() {
                                          birthdate = DateTime(
                                            birthdate.year,
                                            birthdate.month,
                                            selectedDay,
                                          );
                                          checkForChanges();
                                        });
                                      }
                                    },
                                    child: _buildBirthdateContainer(
                                      '${birthdate.day}',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),

                                // Month
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final selectedMonth =
                                          await showModalBottomSheet<int>(
                                            showDragHandle: true,
                                            backgroundColor: scaffoldColor,
                                            context: context,
                                            builder: (_) {
                                              final controller =
                                                  ScrollController(
                                                    initialScrollOffset:
                                                        (birthdate.month - 1) *
                                                        56.0,
                                                  );

                                              return SafeArea(
                                                child: ListView.builder(
                                                  controller: controller,
                                                  itemCount: 12,
                                                  itemBuilder: (context, index) {
                                                    final month = index + 1;
                                                    final isSelected =
                                                        birthdate.month ==
                                                        month;

                                                    return ListTile(
                                                      tileColor: isSelected
                                                          ? primaryColor
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                          : null,
                                                      title: Center(
                                                        child: Text(
                                                          DateFormat(
                                                            'MMMM',
                                                          ).format(
                                                            DateTime(
                                                              2025,
                                                              month,
                                                            ),
                                                          ),
                                                          style: TextStyle(
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                            color: isSelected
                                                                ? primaryColor
                                                                : null,
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                            context,
                                                            month,
                                                          ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          );

                                      if (selectedMonth != null) {
                                        setState(() {
                                          final day =
                                              birthdate.day >
                                                  _daysInMonth(
                                                    selectedMonth,
                                                    birthdate.year,
                                                  )
                                              ? _daysInMonth(
                                                  selectedMonth,
                                                  birthdate.year,
                                                )
                                              : birthdate.day;

                                          birthdate = DateTime(
                                            birthdate.year,
                                            selectedMonth,
                                            day,
                                          );
                                          checkForChanges();
                                        });
                                      }
                                    },
                                    child: _buildBirthdateContainer(
                                      DateFormat('MMMM').format(birthdate),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),

                                // Year
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final selectedYear =
                                          await showModalBottomSheet<int>(
                                            showDragHandle: true,
                                            backgroundColor: scaffoldColor,
                                            context: context,
                                            builder: (_) {
                                              final currentYear =
                                                  DateTime.now().year;
                                              final selectedIndex =
                                                  currentYear - birthdate.year;
                                              final controller =
                                                  ScrollController(
                                                    initialScrollOffset:
                                                        selectedIndex * 56.0,
                                                  );

                                              return SafeArea(
                                                child: ListView.builder(
                                                  controller: controller,
                                                  itemCount: 100,
                                                  itemBuilder: (context, index) {
                                                    final year =
                                                        currentYear - index;
                                                    final isSelected =
                                                        birthdate.year == year;

                                                    return ListTile(
                                                      tileColor: isSelected
                                                          ? primaryColor
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                          : null,
                                                      title: Center(
                                                        child: Text(
                                                          '$year',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                            color: isSelected
                                                                ? primaryColor
                                                                : null,
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                            context,
                                                            year,
                                                          ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          );

                                      if (selectedYear != null) {
                                        final day =
                                            birthdate.day >
                                                _daysInMonth(
                                                  birthdate.month,
                                                  selectedYear,
                                                )
                                            ? _daysInMonth(
                                                birthdate.month,
                                                selectedYear,
                                              )
                                            : birthdate.day;

                                        setState(() {
                                          birthdate = DateTime(
                                            selectedYear,
                                            birthdate.month,
                                            day,
                                          );
                                          checkForChanges();
                                        });
                                      }
                                    },
                                    child: _buildBirthdateContainer(
                                      '${birthdate.year}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            CustomFormField(
                              hasTitle: true,
                              readOnly: true,
                              controller: genderController,
                              color: lightGreyColor.withOpacity(0.3),
                              title: S.of(context).gender,
                              hint: S.of(context).select_gender,
                              textColor: textColor,
                              cursorColor: primaryColor,
                              outlineInputBorder: OutlineInputBorder(
                                borderRadius: genderExpanded
                                    ? BorderRadius.vertical(
                                        top: Radius.circular(15.r),
                                      )
                                    : BorderRadius.circular(15.r),
                                borderSide: const BorderSide(
                                  width: 5,
                                  color: transparentColor,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  genderExpanded = !genderExpanded;
                                });
                              },
                              suffix: Icon(
                                genderExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: textColor.withOpacity(0.7),
                                size: 28.h,
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              // margin: EdgeInsets.symmetric(horizontal: 20.w),
                              curve: Curves.easeInOut,
                              height: genderExpanded ? 120 : 0,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              decoration: BoxDecoration(
                                color: lightGreyColor.withOpacity(0.2),
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(20.r),
                                ),
                              ),
                              child: ListView.builder(
                                itemCount: genderOptions.length,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      if (index == 0) SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Material(
                                          color: transparentColor,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(22.r),
                                            topRight: Radius.circular(22.r),
                                            bottomRight: Radius.circular(18.r),
                                            bottomLeft: Radius.circular(18.r),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                selectedGender =
                                                    genderOptions[index];
                                                genderController.text =
                                                    genderOptions[index];
                                                genderExpanded =
                                                    !genderExpanded;
                                                checkForChanges();
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 15.w,
                                                vertical: 10,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        getLocalizedGender(
                                                          genderOptions[index],
                                                          context,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize:
                                                              selectedGender ==
                                                                  genderOptions[index]
                                                              ? 18
                                                              : 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              selectedGender ==
                                                                  genderOptions[index]
                                                              ? primaryColor
                                                              : textColor
                                                                    .withOpacity(
                                                                      0.5,
                                                                    ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        primaryColor,
                                                    radius:
                                                        selectedGender ==
                                                            genderOptions[index]
                                                        ? 12
                                                        : 0,
                                                    child: Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size:
                                                          selectedGender ==
                                                              genderOptions[index]
                                                          ? 15
                                                          : 0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            CustomFormField(
                              hasTitle: true,
                              readOnly: true,
                              textColor: textColor,
                              title: S.of(context).phone_number,
                              hint: '+971 50 717 1626',
                              onTap: phoneNumberController.text.isNotEmpty
                                  ? () {}
                                  : () {
                                      navigateTo(
                                        context: context,
                                        screen: PhoneNumberPage(),
                                      );
                                    },
                              controller: phoneNumberController,
                              onChanged: (val) {
                                setState(() {
                                  phoneNumberController.text = val.toString();
                                  checkForChanges();
                                });
                              },
                            ),
                            Positioned(
                              left: lang == 'ar' ? 10 : null,
                              right: lang == 'en' ? 10 : null,
                              bottom: 8,
                              child: GestureDetector(
                                onTap: phoneNumberController.text.isNotEmpty
                                    ? null
                                    : () {
                                        navigateTo(
                                          context: context,
                                          screen: PhoneNumberPage(),
                                        );
                                      },
                                child: Chip(
                                  label: Text(
                                    phoneNumberController.text.isEmpty
                                        ? S.of(context).not_added
                                        : S.of(context).authentic,
                                    textDirection: ui.TextDirection.ltr,
                                    style: TextStyle(
                                      color: phoneNumberController.text.isEmpty
                                          ? Colors.red
                                          : CupertinoColors.systemGreen,
                                    ),
                                  ),
                                  side: BorderSide.none,
                                  backgroundColor:
                                      phoneNumberController.text.isEmpty
                                      ? Colors.red.withOpacity(0.1)
                                      : CupertinoColors.systemGreen.withOpacity(
                                          0.15,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Material(
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
                          color: hasChanges
                              ? primaryColor
                              : primaryColor.withOpacity(0.4),
                          elevation: 15,
                          shadowColor: primaryColor.withOpacity(0.5),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(17.r),
                            onTap: hasChanges
                                ? () async {
                                    if (formKey.currentState!.validate()) {
                                      await UserCubit.get(
                                        context,
                                      ).updateBuyerData(
                                        username: usernameController.text,
                                        image: selectedImage,
                                        birthdate: birthdate,
                                        gender: selectedGender,
                                      );
                                    }
                                  }
                                : null,
                            child: Center(
                              child: state is UserUploadImageLoadingState
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      S.of(context).save,
                                      style: TextStyle(
                                        height: 0.8,
                                        color: hasChanges
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.4),
                                        fontSize: 21.sp,
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

  Widget _buildBirthdateContainer(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: formFieldColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: lightGreyColor.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 15, color: textColor)),
    );
  }

  int _daysInMonth(int month, int year) {
    return DateTimeRange(
      start: DateTime(year, month, 1),
      end: DateTime(year, month + 1, 1),
    ).duration.inDays;
  }
}
