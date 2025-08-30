import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/seller/widgets/manage_shop_appBar.dart';
import 'package:matajer/widgets/custom_form_field.dart';

class ManageShopPage extends StatefulWidget {
  final ShopModel shopModel;

  const ManageShopPage({super.key, required this.shopModel});

  @override
  State<ManageShopPage> createState() => _ManageShopPageState();
}

class _ManageShopPageState extends State<ManageShopPage> {
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  bool showCollapsedActions = false;

  bool changeLicenseNumber = false;
  bool expanded = true;
  int selectedCategory = 0;

  late TextEditingController shopNameController;
  late TextEditingController shopCategoryController;
  late TextEditingController shopDescriptionController;
  late TextEditingController deliveryDaysController;
  late TextEditingController avgResponseTimeController;
  late TextEditingController licenseNumberController;

  bool autoAcceptOrders = false;

  File? newLogoFile;
  File? newBannerFile;
  File? newLicenseFile;

  bool hasChanges = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    final shop = widget.shopModel;

    shopNameController = TextEditingController(text: shop.shopName);
    shopCategoryController = TextEditingController(text: shop.shopCategory);
    shopDescriptionController = TextEditingController(
      text: shop.shopDescription,
    );
    deliveryDaysController = TextEditingController(
      text: shop.deliveryDays.toString(),
    );
    avgResponseTimeController = TextEditingController(
      text: shop.avgResponseTime.toString(),
    );
    licenseNumberController = TextEditingController(
      text: shop.sellerLicenseNumber.toString(),
    );

    autoAcceptOrders = shop.autoAcceptOrders;

    /// ✅ Sync category index with actual shop category
    int index = matajerEnglishCategories.indexWhere(
      (cat) => cat["name"] == shop.shopCategory,
    );
    if (index != -1) {
      selectedCategory = index;
    } else {
      selectedCategory = 0; // fallback if not found
    }
  }

  void _handleScroll() {
    final threshold = currentUserModel.shops.isNotEmpty ? 0.33.sh : 0.43.sh;
    final offset = _scrollController.position.pixels;

    if (offset >= threshold && !showCollapsedActions) {
      setState(() => showCollapsedActions = true);
    } else if (offset < threshold && showCollapsedActions) {
      setState(() => showCollapsedActions = false);
    }
  }

  void checkForChanges() {
    final shop = widget.shopModel;
    setState(() {
      hasChanges =
          shopNameController.text.trim() != shop.shopName ||
          shopCategoryController.text.trim() != shop.shopCategory ||
          shopDescriptionController.text.trim() != shop.shopDescription ||
          deliveryDaysController.text.trim() != shop.deliveryDays.toString() ||
          avgResponseTimeController.text.trim() !=
              shop.avgResponseTime.toString() ||
          licenseNumberController.text.trim() !=
              shop.sellerLicenseNumber.toString() ||
          autoAcceptOrders != shop.autoAcceptOrders ||
          newLogoFile != null ||
          newBannerFile != null ||
          newLicenseFile != null;
    });
  }

  Future<void> pickImage(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        if (type == 'logo') newLogoFile = File(picked.path);
        if (type == 'banner') newBannerFile = File(picked.path);
        if (type == 'license') newLicenseFile = File(picked.path);
      });
      checkForChanges();
    }
  }

  Future<String> uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String logoUrl = widget.shopModel.shopLogoUrl;
      String bannerUrl = widget.shopModel.shopBannerUrl;
      String licenseUrl = widget.shopModel.sellerLicenseImageUrl;

      if (newLogoFile != null) {
        logoUrl = await uploadFile(
          newLogoFile!,
          "shops/${widget.shopModel.shopId}/logo.jpg",
        );
      }
      if (newBannerFile != null) {
        bannerUrl = await uploadFile(
          newBannerFile!,
          "shops/${widget.shopModel.shopId}/banner.jpg",
        );
      }
      if (newLicenseFile != null) {
        licenseUrl = await uploadFile(
          newLicenseFile!,
          "shops/${widget.shopModel.shopId}/license.jpg",
        );
      }

      // build updated model
      final updatedShop = widget.shopModel.copyWith(
        shopName: shopNameController.text.trim(),
        shopCategory: shopCategoryController.text.trim(),
        shopDescription: shopDescriptionController.text.trim(),
        deliveryDays: int.tryParse(deliveryDaysController.text.trim()) ?? 0,
        avgResponseTime:
            int.tryParse(avgResponseTimeController.text.trim()) ?? 0,
        sellerLicenseNumber:
            num.tryParse(licenseNumberController.text.trim()) ?? 0,
        autoAcceptOrders: autoAcceptOrders,
        shopLogoUrl: logoUrl,
        shopBannerUrl: bannerUrl,
        sellerLicenseImageUrl: licenseUrl,
      );

      // update Firestore
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shopModel.shopId)
          .update(updatedShop.toMap());

      // ✅ Update both global and local state
      setState(() {
        currentShopModel = updatedShop; // global variable (from vars.dart)
        widget.shopModel.updateFrom(updatedShop); // optional sync helper
        hasChanges = false;
        newLogoFile = null;
        newBannerFile = null;
        newLicenseFile = null;
      });

      // ✅ Optionally persist locally in cache
      await CacheHelper.saveData(
        key: 'currentShopModel',
        value: jsonEncode(updatedShop.toMap()),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop details updated successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating shop: $e")));
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: RepaintBoundary(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            ManageShopAppBar(
              showCollapsedActions: showCollapsedActions,
              changeBannerButton: () => pickImage('banner'),
              changeLogoButton: () => pickImage('logo'),
            ),

            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    spacing: 10,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Shop Name
                      CustomFormField(
                        hasTitle: true,
                        textColor: textColor,
                        title: S.of(context).shop_name,
                        hint: S.of(context).shop_name_hint,
                        onTap: () {},
                        onChanged: (_) => checkForChanges(),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return S.of(context).shop_name_validation;
                          }
                          return null;
                        },
                        controller: shopNameController,
                      ),

                      // Shop Description
                      CustomFormField(
                        hasTitle: true,
                        textColor: textColor,
                        title: S.of(context).shop_description,
                        hint: S.of(context).shop_description_hint,
                        onTap: () {},
                        onChanged: (_) => checkForChanges(),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return S.of(context).shop_description_validation;
                          }
                          return null;
                        },
                        controller: shopDescriptionController,
                      ),

                      // Shop License Number
                      CustomFormField(
                        hasTitle: true,
                        readOnly: changeLicenseNumber ? false : true,
                        textColor: textColor,
                        title: S.of(context).license_number,
                        hint: S.of(context).license_number_hint,
                        maxLines: 1,
                        onTap: () {},
                        onChanged: (_) => checkForChanges(),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return S.of(context).license_number_validation;
                          }
                          return null;
                        },
                        controller: licenseNumberController,
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              changeLicenseNumber = !changeLicenseNumber;
                            });
                          },
                          icon: Row(
                            spacing: 5,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "change",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(Icons.swap_horiz, color: primaryColor),
                            ],
                          ),
                        ),
                      ),

                      // Shop License Image
                      Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).license_image,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          GestureDetector(
                            onLongPress: () => showProfilePreview(
                              context: context,
                              isProfile: false,
                              imageUrl:
                                  currentShopModel?.sellerLicenseImageUrl ?? "",
                            ),
                            onTap: () => pickImage('license'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 0.2.sh,
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      // Show license image if exists, otherwise placeholder
                                      currentShopModel?.sellerLicenseImageUrl !=
                                                  null &&
                                              currentShopModel!
                                                  .sellerLicenseImageUrl
                                                  .isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: currentShopModel!
                                                  .sellerLicenseImageUrl,
                                              progressIndicatorBuilder:
                                                  (context, url, progress) =>
                                                      shimmerPlaceholder(
                                                        height: 0.2.sh,
                                                        width: double.infinity,
                                                        radius: 0,
                                                      ),
                                              height: 0.2.sh,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 0.2.sh,
                                              width: double.infinity,
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                Icons.insert_drive_file,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                            ),

                                      // Overlay to change license
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.white.withOpacity(0.6),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.swap_horizontal_circle,
                                                  size: 55,
                                                  color: primaryColor,
                                                ),
                                                Text(
                                                  "Change license",
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
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
                        ],
                      ),

                      // Shop Description
                      Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: CustomFormField(
                              fontSize: 14,
                              hasTitle: true,
                              textColor: textColor,
                              title: S.of(context).delivery_days,
                              hint: S.of(context).delivery_days_hint,
                              onTap: () {},
                              onChanged: (_) => checkForChanges(),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return S.of(context).delivery_days_validation;
                                }
                                return null;
                              },
                              controller: deliveryDaysController,
                            ),
                          ),
                          Expanded(
                            child: CustomFormField(
                              fontSize: 14,
                              hasTitle: true,
                              textColor: textColor,
                              title: S.of(context).avg_response,
                              hint: S.of(context).avg_response_hint,
                              onTap: () {},
                              onChanged: (_) => checkForChanges(),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return S.of(context).avg_response_validation;
                                }
                                return null;
                              },
                              controller: avgResponseTimeController,
                            ),
                          ),
                        ],
                      ),

                      // Shop Category
                      Column(
                        children: [
                          CustomFormField(
                            hasTitle: true,
                            readOnly: true,
                            textColor: textColor,
                            title: S.of(context).category,
                            hint: S.of(context).shop_type_hint,
                            onChanged: (_) => checkForChanges(),
                            outlineInputBorder: OutlineInputBorder(
                              borderRadius: expanded
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
                            controller: shopCategoryController,
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
                              itemCount: matajerEnglishCategories.length,
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
                                              expanded = !expanded;
                                              selectedCategory = index;
                                              shopCategoryController.text =
                                                  category;
                                              checkForChanges();
                                            });
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
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
                                                          ? EdgeInsets.all(13)
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
                                                            FontWeight.w600,
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
                                                  backgroundColor: primaryColor,
                                                  radius:
                                                      selectedCategory == index
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
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: const SizedBox(height: 145)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Material(
          color: transparentColor,
          child: InkWell(
            onTap: hasChanges ? saveChanges : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(7, 0, 7, 15),
              child: Material(
                borderRadius: BorderRadius.circular(15),
                child: Opacity(
                  opacity: hasChanges ? 1 : 0.5,
                  child: SizedBox(
                    height: 60,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: hasChanges ? primaryColor : Colors.grey,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 10),
                            blurRadius: 8,
                            color: hasChanges
                                ? primaryColor.withOpacity(0.5)
                                : Colors.grey.withOpacity(0.5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          S.of(context).save_changes,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
