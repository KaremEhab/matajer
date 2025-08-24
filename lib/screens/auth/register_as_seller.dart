import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/image_picker.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/cubit/user/user_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/widgets/custom_form_field.dart';
import 'package:matajer/widgets/pick_image_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterAsSeller extends StatefulWidget {
  final void Function()? onShopRegistered;

  const RegisterAsSeller({super.key, this.onShopRegistered});

  @override
  State<RegisterAsSeller> createState() => _RegisterAsSellerState();
}

class _RegisterAsSellerState extends State<RegisterAsSeller> {
  XFile? selectedShopProfilePic;
  XFile? selectedShopCoverPic;
  XFile? licenceImage;

  int selectedPage = 0;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> formKey2 = GlobalKey<FormState>();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController shopTypeController = TextEditingController();
  final TextEditingController shopDescController = TextEditingController();
  final TextEditingController licenceController = TextEditingController();
  final TextEditingController deliveryDaysController = TextEditingController();
  final TextEditingController avgResponseTimeController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();
  final PageController pageController = PageController();

  bool isVisible = true;
  bool expanded = true;
  int selectedCategory = 0;

  Map<String, dynamic> _cachedData = {};

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        setState(() => isVisible = false);
      } else {
        setState(() => isVisible = true);
      }
    });
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedData = {
      'name': prefs.getString('cached_shop_name') ?? '',
      'type': prefs.getString('cached_shop_type') ?? '',
      'desc': prefs.getString('cached_shop_desc') ?? '',
      'delivery_days': prefs.getString('cached_shop_delivery_days') ?? '',
      'response_time': prefs.getString('cached_shop_response_time') ?? '',
      'licence': prefs.getString('cached_shop_licence') ?? '',
      'logo': prefs.getString('cached_logo_path'),
      'banner': prefs.getString('cached_banner_path'),
      'licenceImage': prefs.getString('cached_license_image_path'),
    };

    shopNameController.text = _cachedData['name'];
    shopTypeController.text = _cachedData['type'];
    shopDescController.text = _cachedData['desc'];
    deliveryDaysController.text = _cachedData['delivery_days'];
    avgResponseTimeController.text = _cachedData['response_time'];
    licenceController.text = _cachedData['licence'];
    if (_cachedData['logo'] != null) {
      selectedShopProfilePic = XFile(_cachedData['logo']);
    }
    if (_cachedData['banner'] != null) {
      selectedShopCoverPic = XFile(_cachedData['banner']);
    }
    if (_cachedData['licenceImage'] != null) {
      licenceImage = XFile(_cachedData['licenceImage']);
    }
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_shop_name', shopNameController.text);
    await prefs.setString('cached_shop_type', shopTypeController.text);
    await prefs.setString('cached_shop_desc', shopDescController.text);
    await prefs.setString(
      'cached_shop_delivery_days',
      deliveryDaysController.text,
    );
    await prefs.setString(
      'cached_shop_response_time',
      avgResponseTimeController.text,
    );
    await prefs.setString('cached_shop_licence', licenceController.text);
    if (selectedShopProfilePic != null) {
      await prefs.setString('cached_logo_path', selectedShopProfilePic!.path);
    }
    if (selectedShopCoverPic != null) {
      await prefs.setString('cached_banner_path', selectedShopCoverPic!.path);
    }
    if (licenceImage != null) {
      await prefs.setString('cached_license_image_path', licenceImage!.path);
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_shop_name');
    await prefs.remove('cached_shop_type');
    await prefs.remove('cached_shop_desc');
    await prefs.remove('cached_shop_delivery_days');
    await prefs.remove('cached_shop_response_time');
    await prefs.remove('cached_shop_licence');
    await prefs.remove('cached_logo_path');
    await prefs.remove('cached_banner_path');
    await prefs.remove('cached_license_image_path');
  }

  bool _hasUserInput() {
    return shopNameController.text.trim().isNotEmpty ||
        shopTypeController.text.trim().isNotEmpty ||
        shopDescController.text.trim().isNotEmpty ||
        deliveryDaysController.text.trim().isNotEmpty ||
        avgResponseTimeController.text.trim().isNotEmpty ||
        licenceController.text.trim().isNotEmpty ||
        selectedShopProfilePic != null ||
        selectedShopCoverPic != null ||
        licenceImage != null;
  }

  bool _isDataChanged() {
    return shopNameController.text != _cachedData['name'] ||
        shopTypeController.text != _cachedData['type'] ||
        shopDescController.text != _cachedData['desc'] ||
        deliveryDaysController.text != _cachedData['delivery_days'] ||
        avgResponseTimeController.text != _cachedData['response_time'] ||
        licenceController.text != _cachedData['licence'] ||
        (selectedShopProfilePic?.path != _cachedData['logo']) ||
        (selectedShopCoverPic?.path != _cachedData['banner']) ||
        (licenceImage?.path != _cachedData['licenceImage']);
  }

  Future<bool> _onWillPop() async {
    final hasInput = _hasUserInput();
    final isChanged = _isDataChanged();

    if (!hasInput && _cachedData.values.any((e) => e != null && e != '')) {
      await _clearCache();
      return true;
    }

    if (!hasInput) return true;

    return await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text("${S.of(context).save_draft}?"),
                content: Text(S.of(context).want_to_save_progress),
                actions: [
                  TextButton(
                    child: Text(
                      isChanged ? S.of(context).discard : S.of(context).clear,
                    ),
                    onPressed: () async {
                      if (isChanged) {
                        Navigator.of(ctx).pop(true);
                      } else {
                        await _clearCache();
                        Navigator.of(ctx).pop(true);
                      }
                    },
                  ),
                  TextButton(
                    child: Text(S.of(context).yes),
                    onPressed: () async {
                      await _saveCache();
                      if (context.mounted) Navigator.of(ctx).pop(true);
                    },
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  void dispose() {
    pageController.dispose();
    scrollController.dispose();
    shopNameController.dispose();
    shopTypeController.dispose();
    shopDescController.dispose();
    licenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocConsumer<UserCubit, UserState>(
        listener: (context, state) async {
          if (state is UserRegisterSellerSuccessState) {
            await _clearCache();
            if (context.mounted) {
              layoutPageController!.jumpToPage(0);
              navigateAndFinish(context: context, screen: const Layout());
              widget.onShopRegistered?.call();
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            extendBody: true,
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
                    onTap: () async {
                      if (selectedPage < 3 && selectedPage != 0) {
                        selectedPage--;
                        pageController.animateToPage(
                          selectedPage,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() {});
                      } else if (selectedPage == 0) {
                        final shouldPop = await _onWillPop();
                        if (shouldPop && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Center(
                      child: Icon(backIcon(), color: textColor, size: 26),
                    ),
                  ),
                ),
              ),
              title: Text(
                S.of(context).register_as_seller,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    lang == 'en' ? 0 : 20.w,
                    12.h,
                    lang == 'en' ? 20.w : 0,
                    0,
                  ),
                  child: Column(
                    children: [
                      Text(
                        S.of(context).information_page,
                        style: TextStyle(
                          fontSize: 9.5.h,
                          fontWeight: FontWeight.w800,
                          color: CupertinoColors.activeGreen,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 24.w,
                            height: 4.h,
                            child: Material(
                              color: CupertinoColors.activeGreen,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          SizedBox(
                            width: 24.w,
                            height: 4.h,
                            child: Material(
                              color:
                                  (selectedPage == 1 || selectedPage == 2)
                                      ? CupertinoColors.activeGreen
                                      : CupertinoColors.activeGreen.withOpacity(
                                        0.4,
                                      ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          SizedBox(
                            width: 24.w,
                            height: 4.h,
                            child: Material(
                              color:
                                  selectedPage == 2
                                      ? CupertinoColors.activeGreen
                                      : CupertinoColors.activeGreen.withOpacity(
                                        0.4,
                                      ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                selectedPage = index;
              },
              children: [
                // 1st Page
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 15),
                        Text(
                          S.of(context).register_as_seller_tip,
                          style: TextStyle(
                            height: 1.2,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        // SizedBox(height: 7),
                        // Text(
                        //   "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed faucibus augue au augue eget nisi eleifend ullamcorper. Integer vel augue ac ipsum ultrices.",
                        //   maxLines: 2,
                        //   overflow: TextOverflow.ellipsis,
                        //   style: TextStyle(
                        //     height: 1.1,
                        //     color: lightGreyColor,
                        //     fontSize: 14,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                        SizedBox(height: 25),
                        Form(
                          key: formKey,
                          child: Column(
                            spacing: 10,
                            children: [
                              CustomFormField(
                                hasTitle: true,
                                textColor: textColor,
                                title: S.of(context).shop_name,
                                hint: S.of(context).shop_name_hint,
                                onTap: () {},
                                controller: shopNameController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return S.of(context).shop_name_validation;
                                  }
                                  return null;
                                },
                              ),
                              Column(
                                children: [
                                  CustomFormField(
                                    hasTitle: true,
                                    readOnly: true,
                                    textColor: textColor,
                                    title: S.of(context).shop_type,
                                    hint: S.of(context).shop_type_hint,
                                    outlineInputBorder: OutlineInputBorder(
                                      borderRadius:
                                          expanded
                                              ? BorderRadius.circular(15.r)
                                              : BorderRadius.vertical(
                                                top: Radius.circular(15.r),
                                              ),
                                      borderSide: const BorderSide(
                                        width: 5,
                                        color: transparentColor,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        expanded = !expanded;
                                      });
                                    },
                                    controller: shopTypeController,
                                    suffix: Icon(
                                      expanded
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.keyboard_arrow_up_rounded,
                                      color: greyColor,
                                      size: 28.h,
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    // margin: EdgeInsets.symmetric(horizontal: 20.w),
                                    curve: Curves.easeInOut,
                                    height: expanded ? 0 : 290.h,
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    decoration: BoxDecoration(
                                      color: formFieldColor,
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(20.r),
                                      ),
                                    ),
                                    child: ListView.builder(
                                      itemCount:
                                          matajerEnglishCategories.length,
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      physics: const BouncingScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        String category =
                                            matajerEnglishCategories[index]["name"];
                                        IconData icon =
                                            categoryEnglishIcons[category] ??
                                            Icons.category;

                                        return Column(
                                          children: [
                                            if (index == 0)
                                              SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              child: Material(
                                                color: transparentColor,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(
                                                    22.r,
                                                  ),
                                                  topRight: Radius.circular(
                                                    22.r,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    18.r,
                                                  ),
                                                  bottomLeft: Radius.circular(
                                                    18.r,
                                                  ),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      expanded = !expanded;
                                                      selectedCategory = index;
                                                      shopTypeController.text =
                                                          category;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 15,
                                                          vertical: 10,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  selectedCategory ==
                                                                          index
                                                                      ? EdgeInsets.all(
                                                                        13,
                                                                      )
                                                                      : null,
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    selectedCategory ==
                                                                            index
                                                                        ? primaryColor
                                                                            .withOpacity(
                                                                              0.15,
                                                                            )
                                                                        : null,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      15.r,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                icon,
                                                                size: 30,
                                                                color:
                                                                    selectedCategory ==
                                                                            index
                                                                        ? primaryDarkColor
                                                                        : textColor,
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Text(
                                                              category,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    selectedCategory ==
                                                                            index
                                                                        ? 18
                                                                        : 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    selectedCategory ==
                                                                            index
                                                                        ? primaryDarkColor
                                                                        : textColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        CircleAvatar(
                                                          backgroundColor:
                                                              primaryColor,
                                                          radius:
                                                              selectedCategory ==
                                                                      index
                                                                  ? 12
                                                                  : 0,
                                                          child: Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size:
                                                                selectedCategory ==
                                                                        index
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
                              CustomFormField(
                                hasTitle: true,
                                textColor: textColor,
                                maxLines: 7,
                                title: S.of(context).shop_description,
                                hint: S.of(context).shop_description_hint,
                                onTap: () {},
                                controller: shopDescController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return S
                                        .of(context)
                                        .shop_description_validation;
                                  }
                                  return null;
                                },
                              ),
                              Row(
                                spacing: 5,
                                children: [
                                  Expanded(
                                    child: CustomFormField(
                                      hasTitle: true,
                                      textColor: textColor,
                                      keyboardType: TextInputType.number,
                                      title: S.of(context).delivery_days,
                                      hint: S.of(context).delivery_days_hint,
                                      onTap: () {},
                                      controller: deliveryDaysController,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return S
                                              .of(context)
                                              .delivery_days_validation;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: CustomFormField(
                                      hasTitle: true,
                                      textColor: textColor,
                                      keyboardType: TextInputType.number,
                                      title: S.of(context).avg_response,
                                      hint: S.of(context).avg_response_hint,
                                      onTap: () {},
                                      controller: avgResponseTimeController,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return S
                                              .of(context)
                                              .avg_response_validation;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 150),
                      ],
                    ),
                  ),
                ),
                // 2nd Page
                SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(400),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  showDragHandle: true,
                                  backgroundColor: scaffoldColor,
                                  builder: (BuildContext context) {
                                    return PickImageSource(
                                      galleryButton: () async {
                                        selectedShopProfilePic =
                                            await galleryPicker();
                                        setState(() {
                                          selectedShopProfilePic;
                                        });
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                      },
                                      cameraButton: () async {
                                        selectedShopProfilePic =
                                            await cameraPicker();
                                        setState(() {
                                          selectedShopProfilePic;
                                        });
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(400),
                                child:
                                    selectedShopProfilePic == null
                                        ? Material(
                                          color: lightGreyColor.withOpacity(
                                            0.3,
                                          ),
                                          child: SizedBox(
                                            height: 0.18.sh,
                                            width: 0.18.sh,
                                            child: Icon(
                                              Icons.add,
                                              size: 40,
                                              color: greyColor,
                                            ),
                                          ),
                                        )
                                        : Image.file(
                                          File(selectedShopProfilePic!.path),
                                          fit: BoxFit.cover,
                                          height: 0.18.sh,
                                          width: 0.18.sh,
                                        ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              '${shopNameController.text.trim()} ${S.of(context).logo}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${shopNameController.text.trim()} ${S.of(context).banner}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 5),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(30.r),
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      backgroundColor: scaffoldColor,
                                      builder: (BuildContext context) {
                                        return PickImageSource(
                                          galleryButton: () async {
                                            selectedShopCoverPic =
                                                await galleryPicker();
                                            setState(() {
                                              selectedShopCoverPic;
                                            });
                                            if (!context.mounted) return;
                                            Navigator.pop(context);
                                          },
                                          cameraButton: () async {
                                            selectedShopCoverPic =
                                                await cameraPicker();
                                            setState(() {
                                              selectedShopCoverPic;
                                            });
                                            if (!context.mounted) return;
                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30.r),
                                    child:
                                        selectedShopCoverPic == null
                                            ? Material(
                                              color: lightGreyColor.withOpacity(
                                                0.3,
                                              ),
                                              child: SizedBox(
                                                height: bannerHeight,
                                                width: bannerWidth,
                                                child: Icon(
                                                  Icons.add,
                                                  size: 40,
                                                  color: greyColor,
                                                ),
                                              ),
                                            )
                                            : Image.file(
                                              File(selectedShopCoverPic!.path),
                                              fit: BoxFit.cover,
                                              height: bannerHeight,
                                              width: bannerWidth,
                                            ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  S.of(context).optimal_dimensions,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: greyColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 150),
                    ],
                  ),
                ),
                // 3rd Page
                SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7),
                    child: Form(
                      key: formKey2,
                      child: Column(
                        spacing: 10,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 15),
                          CustomFormField(
                            hasTitle: true,
                            title: S.of(context).license_number,
                            textColor: textColor,
                            hint: S.of(context).license_number_hint,
                            keyboardType: TextInputType.number,
                            onTap: () {},
                            controller: licenceController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return S.of(context).license_number_validation;
                              }
                              return null;
                            },
                          ),
                          Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).license_number,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(30.r),
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          showDragHandle: true,
                                          backgroundColor: scaffoldColor,
                                          builder: (BuildContext context) {
                                            return PickImageSource(
                                              galleryButton: () async {
                                                licenceImage =
                                                    await galleryPicker();
                                                setState(() {
                                                  licenceImage;
                                                });
                                                if (!context.mounted) return;
                                                Navigator.pop(context);
                                              },
                                              cameraButton: () async {
                                                licenceImage =
                                                    await cameraPicker();
                                                setState(() {
                                                  licenceImage;
                                                });
                                                if (!context.mounted) return;
                                                Navigator.pop(context);
                                              },
                                            );
                                          },
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          30.r,
                                        ),
                                        child:
                                            licenceImage == null
                                                ? Material(
                                                  color: lightGreyColor
                                                      .withOpacity(0.3),
                                                  child: SizedBox(
                                                    height: bannerHeight,
                                                    width: bannerWidth,
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 40,
                                                      color: greyColor,
                                                    ),
                                                  ),
                                                )
                                                : Image.file(
                                                  File(licenceImage!.path),
                                                  fit: BoxFit.cover,
                                                  height: bannerHeight,
                                                  width: bannerWidth,
                                                ),
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      S.of(context).optimal_dimensions,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: greyColor.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Material(
                color: transparentColor,
                child: AnimatedContainer(
                  height: 0.08.sh,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 0.07.sh,
                          width: 0.94.sw,
                          child: Material(
                            borderRadius: BorderRadius.circular(17.r),
                            color: primaryColor,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(17.r),
                              onTap: () async {
                                final userCubit = UserCubit.get(context);

                                if (selectedPage == 0) {
                                  if (formKey.currentState!.validate() &&
                                      shopTypeController.text.isNotEmpty) {
                                    selectedPage++;
                                    pageController.animateToPage(
                                      selectedPage,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                    setState(() {});
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          S.of(context).fill_all_fields,
                                        ),
                                      ),
                                    );
                                  }
                                } else if (selectedPage == 1) {
                                  if (selectedShopProfilePic == null ||
                                      selectedShopCoverPic == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          S.of(context).choose_logo_banner,
                                        ),
                                      ),
                                    );
                                  } else {
                                    selectedPage++;
                                    pageController.animateToPage(
                                      selectedPage,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                    setState(() {});

                                    final tempShopId =
                                        FirebaseFirestore.instance
                                            .collection('shops')
                                            .doc()
                                            .id;
                                    userCubit.tempShopId = tempShopId;

                                    final overlay = Overlay.of(context);
                                    late OverlayEntry loaderEntry;
                                    final progressNotifier =
                                        ValueNotifier<double>(0.0);

                                    void showUploadOverlay() {
                                      loaderEntry = OverlayEntry(
                                        builder:
                                            (context) => Positioned(
                                              top: 50,
                                              left: 20,
                                              right: 20,
                                              child: Material(
                                                elevation: 10,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.black87,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 14,
                                                      ),
                                                  child: ValueListenableBuilder<
                                                    double
                                                  >(
                                                    valueListenable:
                                                        progressNotifier,
                                                    builder:
                                                        (
                                                          context,
                                                          value,
                                                          _,
                                                        ) => Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            LinearProgressIndicator(
                                                              value: value,
                                                              backgroundColor:
                                                                  Colors
                                                                      .grey[300],
                                                              color:
                                                                  Colors.orange,
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            Text(
                                                              '${S.of(context).uploading} ${(value * 100).toStringAsFixed(0)}%',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            Text(
                                                              S
                                                                  .of(context)
                                                                  .keep_screen_open,
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white70,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                      );
                                      overlay.insert(loaderEntry);
                                    }

                                    void hideUploadOverlay() {
                                      if (loaderEntry.mounted) {
                                        loaderEntry.remove();
                                      }
                                    }

                                    showUploadOverlay();
                                    await userCubit.uploadShopImages(
                                      shopLogo: selectedShopProfilePic!,
                                      shopBanner: selectedShopCoverPic!,
                                      shopId: tempShopId,
                                      onProgress: (progress) {
                                        progressNotifier.value = progress;
                                      },
                                    );
                                    hideUploadOverlay();
                                  }
                                } else {
                                  if (formKey2.currentState!.validate() &&
                                      shopNameController.text.isNotEmpty &&
                                      shopTypeController.text.isNotEmpty &&
                                      shopDescController.text.isNotEmpty &&
                                      licenceController.text.isNotEmpty &&
                                      licenceImage != null &&
                                      selectedShopProfilePic != null &&
                                      selectedShopCoverPic != null) {
                                    await userCubit.registerShop(
                                      shopName: shopNameController.text.trim(),
                                      shopCategory:
                                          shopTypeController.text.trim(),
                                      shopDescription:
                                          shopDescController.text.trim(),
                                      sellerLicenseNumber: int.parse(
                                        licenceController.text,
                                      ),
                                      deliveryDays: num.parse(
                                        deliveryDaysController.text.trim(),
                                      ),
                                      avgResponseTime: num.parse(
                                        avgResponseTimeController.text.trim(),
                                      ),
                                      shopLogo: selectedShopProfilePic!,
                                      shopBanner: selectedShopCoverPic!,
                                      sellerLicenseImage: licenceImage!,
                                      context: context,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          S.of(context).complete_all_fields,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Center(
                                child: Text(
                                  selectedPage == 2
                                      ? state is UserRegisterSellerSuccessState
                                          ? S.of(context).now_you_are_seller
                                          : state
                                              is UserRegisterSellerLoadingState
                                          ? "${S.of(context).loading}..."
                                          : S.of(context).finish
                                      : S.of(context).next,
                                  style: const TextStyle(
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
      ),
    );
  }

  Future<XFile?> cameraPicker() async {
    XFile? takenImage = await ImagePickerUtils.cameraImagePicker();
    return takenImage;
  }

  Future<XFile?> galleryPicker() async {
    XFile? newImage = await ImagePickerUtils.galleryOneImagePicker();
    return newImage;
  }
}
