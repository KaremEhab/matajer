import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/draft_storage.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/image_picker.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/product_list_screen.dart';
import 'package:matajer/widgets/custom_form_field.dart';
import 'package:matajer/widgets/pick_image_source.dart';

class AddProducts extends StatefulWidget {
  final ShopModel? shopModel;
  final ProductModel? draftProduct;
  final bool? edit;

  const AddProducts({
    super.key,
    this.shopModel,
    this.draftProduct,
    this.edit = false,
  });

  @override
  State<AddProducts> createState() => _AddProductsState();
}

class _AddProductsState extends State<AddProducts> {
  bool hasChanged = false;
  bool _showAllImages = false;
  List<XFile> productImages = [];
  List<String> subCategories = [];
  List<String> networkImageUrls = [];
  List<XFile> fileImages = [];
  TextEditingController subCategoryController = TextEditingController();
  bool subCategoryExpanded = false;

  // we have title for the specification and value for the specification and price
  List<ProductSpecificationModel> productSpecifications = [];

  Future<void> galleryImages() async {
    final picked =
        await ImagePickerUtils.galleryImagePicker(); // supports multiple
    if (picked.isNotEmpty) {
      setState(() {
        fileImages.addAll(picked);
        hasChanged = true;
      });
    }
  }

  Future<void> cameraImages() async {
    final picked = await ImagePickerUtils.cameraImagePicker();
    if (picked != null) {
      setState(() {
        fileImages.add(picked);
        hasChanged = true;
      });
    }
  }

  Future<bool> onWillPop(
    BuildContext context,
    ProductModel draftProduct,
  ) async {
    if (!hasChanged) return true; // ✅ No changes? Skip dialog and pop.

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(S.of(context).save_draft),
          content: Text(S.of(context).want_to_save_progress),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(true); // discard
              },
              child: Text(S.of(context).discard),
            ),
            TextButton(
              onPressed: () async {
                await DraftsStorage.saveDraft(draftProduct);
                Navigator.of(ctx).pop(true); // saved draft
              },
              child: Text(S.of(context).yes),
            ),
          ],
        );
      },
    );
    return discard ?? false; // false = don't allow pop if dismissed
  }

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  int selectedSubCategory = 0;

  bool showImageError = false;
  bool isUploading = false;

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
      print("Add Products Connectivity changed: isConnected = $connected");
    });

    subCategories.addAll(getSubCategories(widget.shopModel!.shopCategory));

    // Add listeners
    titleController.addListener(detectChanges);
    descController.addListener(detectChanges);
    priceController.addListener(detectChanges);
    quantityController.addListener(detectChanges);
    discountController.addListener(detectChanges);

    if (widget.draftProduct != null) {
      final draft = widget.draftProduct!;
      titleController.text = draft.title;
      descController.text = draft.description;
      priceController.text = draft.price.toString();
      quantityController.text = draft.quantity.toString();
      discountController.text = draft.discount.toString();

      selectedSubCategory = subCategories.indexOf(draft.productCategory);
      if (selectedSubCategory == -1) selectedSubCategory = 0;
      subCategoryController.text = subCategories[selectedSubCategory];

      productImages = draft.images.map((path) => XFile(path)).toList();
      productSpecifications = draft.specifications;

      if (widget.edit!) {
        networkImageUrls = draft.images;
        fileImages = [];
      } else {
        fileImages = productImages;
      }
    } else {
      selectedSubCategory = 0;
      subCategoryController.text = subCategories[selectedSubCategory];
    }

    // ✅ Call this after fields are initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      detectChanges();
    });
  }

  void detectChanges() {
    final draft = widget.draftProduct;

    final currentTitle = titleController.text;
    final currentDesc = descController.text;
    final currentPrice = priceController.text;
    final currentQuantity = quantityController.text;
    final currentDiscount = discountController.text.replaceAll('%', '').trim();
    final currentSubCat = subCategories[selectedSubCategory];
    final currentSpecs = productSpecifications;

    bool changed = false;

    if (draft != null) {
      final hasTitleChanged = draft.title != currentTitle;
      final hasDescChanged = draft.description != currentDesc;
      final hasPriceChanged = draft.price.toString() != currentPrice;
      final hasQuantityChanged = draft.quantity.toString() != currentQuantity;
      final hasDiscountChanged = draft.discount.toString() != currentDiscount;
      final hasSubCatChanged = draft.productCategory != currentSubCat;

      final hasImagesChanged =
          networkImageUrls.length != draft.images.length ||
          fileImages.isNotEmpty;

      final hasSpecsChanged = !_areSpecsEqual(
        currentSpecs,
        productSpecifications,
      );

      changed =
          hasTitleChanged ||
          hasDescChanged ||
          hasPriceChanged ||
          hasQuantityChanged ||
          hasDiscountChanged ||
          hasSubCatChanged ||
          hasImagesChanged ||
          hasSpecsChanged;
    } else {
      // This is a new product (no draft), so any non-empty input = change
      changed =
          currentTitle.isNotEmpty ||
          currentDesc.isNotEmpty ||
          currentPrice.isNotEmpty ||
          currentQuantity.isNotEmpty ||
          currentDiscount.isNotEmpty ||
          fileImages.isNotEmpty ||
          currentSpecs.isNotEmpty;
    }

    setState(() {
      hasChanged = changed;
    });
  }

  bool _compareSpecs(
    List<ProductSpecificationModel> a,
    List<ProductSpecificationModel> b,
  ) {
    if (a.length != b.length) return false;

    for (final spec in a) {
      final match = b.firstWhere(
        (x) => x.title == spec.title,
        orElse: () => ProductSpecificationModel(title: '', subTitles: []),
      );
      if (match.title.isEmpty) return false;

      if (spec.subTitles.length != match.subTitles.length) return false;

      for (int j = 0; j < spec.subTitles.length; j++) {
        if (spec.subTitles[j].title != match.subTitles[j].title ||
            spec.subTitles[j].price != match.subTitles[j].price) {
          return false;
        }
      }
    }

    return true;
  }

  bool _areSpecsEqual(
    List<ProductSpecificationModel> a,
    List<ProductSpecificationModel> b,
  ) {
    if (a.length != b.length) return false;

    for (final specA in a) {
      final specB = b.firstWhere(
        (s) => s.title == specA.title,
        orElse: () => ProductSpecificationModel(title: '', subTitles: []),
      );
      if (specB.title.isEmpty) return false;

      if (specA.subTitles.length != specB.subTitles.length) return false;

      for (int i = 0; i < specA.subTitles.length; i++) {
        final subA = specA.subTitles[i];
        final subB = specB.subTitles[i];
        if (subA.title != subB.title || subA.price != subB.price) return false;
      }
    }

    return true;
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {},
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            // Build the ProductModel from your form fields here, example:
            ProductModel draftProduct = ProductModel(
              id: widget.draftProduct?.id ?? UniqueKey().toString(),
              shopId: widget.shopModel!.shopId,
              title: titleController.text,
              description: descController.text,
              specifications: productSpecifications,
              price: num.tryParse(priceController.text) ?? 0,
              discount: discountController.text.trim().isEmpty
                  ? 0
                  : int.tryParse(
                          discountController.text.replaceAll('%', '').trim(),
                        ) ??
                        0,
              quantity: num.tryParse(quantityController.text) ?? 0,
              images: fileImages.map((file) => file.path).toList(),
              sellerId: widget.shopModel!.sellerId,
              shopName: widget.shopModel!.shopName,
              sellerPhone: '',
              shopLogo: widget.shopModel!.shopLogoUrl,
              productCategory: subCategories[selectedSubCategory],
              sellerCategory: widget.shopModel!.shopCategory,
              fullCategory:
                  "${widget.shopModel!.shopCategory} > ${subCategories[selectedSubCategory]}",
              createdAt: DateTime.now(),
            );

            // Convert your local List<Map<String, dynamic>> to model-based list
            draftProduct.specifications = productSpecifications;

            final saved = await onWillPop(context, draftProduct);
            return saved; // if saved, allow back, else stay
          },
          child: Scaffold(
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
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      // Build the ProductModel from your form fields here, example:
                      ProductModel draftProduct = ProductModel(
                        id: widget.draftProduct?.id ?? UniqueKey().toString(),
                        shopId: widget.shopModel!.shopId,
                        title: titleController.text,
                        description: descController.text,
                        price: num.tryParse(priceController.text) ?? 0,
                        discount: discountController.text.trim().isEmpty
                            ? 0
                            : int.tryParse(
                                    discountController.text
                                        .replaceAll('%', '')
                                        .trim(),
                                  ) ??
                                  0,
                        quantity: num.tryParse(quantityController.text) ?? 0,
                        images: fileImages.map((file) => file.path).toList(),
                        sellerId: widget.shopModel!.sellerId,
                        shopName: widget.shopModel!.shopName,
                        specifications: productSpecifications,
                        sellerPhone: '',
                        shopLogo: widget.shopModel!.shopLogoUrl,
                        productCategory: subCategories[selectedSubCategory],
                        sellerCategory: widget.shopModel!.shopCategory,
                        fullCategory:
                            "${widget.shopModel!.shopCategory} > ${subCategories[selectedSubCategory]}",
                        createdAt: DateTime.now(),
                      );

                      // Convert your local List<Map<String, dynamic>> to model-based list
                      draftProduct.specifications = productSpecifications;

                      final saved = await onWillPop(context, draftProduct);

                      if (saved) {
                        Navigator.of(context).pop(); // Go back
                      }
                      // else do nothing, stay on page
                    },
                    child: Center(
                      child: Icon(backIcon(), color: textColor, size: 26),
                    ),
                  ),
                ),
              ),
              centerTitle: true,
              title: Text(
                widget.edit!
                    ? S.of(context).edit_product
                    : S.of(context).add_product,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              actions: [
                if (widget.draftProduct != null)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      if (widget.edit!) {
                        MultiProductDeleter.show(
                          context: context,
                          shopModel: widget.shopModel!,
                          selectedProductIds: [widget.draftProduct!.id],
                          onDeleteComplete: () {
                            setState(() {
                              [widget.draftProduct!.id].clear();
                            });
                          },
                        );
                      } else {
                        await DraftsStorage.removeDraft(
                          widget.shopModel!.shopId,
                          widget.draftProduct!.id,
                        );
                        await DraftsStorage.getDrafts(widget.shopModel!.shopId);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Text(
                          S.of(context).product_images,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      if (networkImageUrls.isEmpty && fileImages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20.r),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                showDragHandle: true,
                                backgroundColor: scaffoldColor,
                                builder: (context) => PickImageSource(
                                  galleryButton: () async {
                                    await galleryImages();
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  },
                                  cameraButton: () async {
                                    await cameraImages();
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: Material(
                                color: lightGreyColor.withOpacity(0.3),
                                child: SizedBox(
                                  height: 0.33.sh,
                                  width: double.infinity,
                                  child: Icon(
                                    IconlyLight.image,
                                    size: 0.13.sh,
                                    color: greyColor.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (networkImageUrls.isNotEmpty || fileImages.isNotEmpty)
                        SizedBox(height: 10),

                      if (networkImageUrls.isNotEmpty || fileImages.isNotEmpty)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final allImages = [
                              ...networkImageUrls.map(
                                (e) => Image.network(e, fit: BoxFit.cover),
                              ),
                              ...fileImages.map(
                                (e) =>
                                    Image.file(File(e.path), fit: BoxFit.cover),
                              ),
                            ];

                            final totalImages = allImages.length;

                            final showSeeLess =
                                _showAllImages && totalImages >= 5;
                            final totalItems =
                                1 // Add More button
                                +
                                (_showAllImages
                                    ? totalImages
                                    : totalImages.clamp(0, 5)) +
                                (showSeeLess
                                    ? 1
                                    : 0); // Only add See Less if conditions met

                            final crossAxisCount = totalItems <= 2 ? 2 : 3;
                            const spacing = 7.0;
                            const itemAspectRatio = 0.75;

                            final rowCount = (totalItems / crossAxisCount)
                                .ceil();
                            final totalSpacing = (crossAxisCount - 1) * spacing;
                            final itemWidth =
                                (constraints.maxWidth - totalSpacing) /
                                crossAxisCount;
                            final itemHeight = itemWidth / itemAspectRatio;
                            final gridHeight =
                                rowCount * (itemHeight - 4) +
                                (rowCount - 1) * spacing;

                            return Container(
                              height: gridHeight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              child: GridView.builder(
                                itemCount: totalItems,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: spacing,
                                      mainAxisSpacing: spacing,
                                      childAspectRatio: itemAspectRatio,
                                    ),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    // Add More Button
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(20.r),
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          showDragHandle: true,
                                          backgroundColor: scaffoldColor,
                                          builder: (context) => PickImageSource(
                                            galleryButton: () async {
                                              await galleryImages();
                                              if (!context.mounted) return;
                                              Navigator.pop(context);
                                            },
                                            cameraButton: () async {
                                              await cameraImages();
                                              if (!context.mounted) return;
                                              Navigator.pop(context);
                                            },
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        child: Material(
                                          color: lightGreyColor.withOpacity(
                                            0.3,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                IconlyLight.image,
                                                size: 45,
                                                color: textColor,
                                              ),
                                              Text(
                                                S.of(context).add_more,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: textColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final imageIndex = index - 1;

                                  if (showSeeLess && index == totalItems - 1) {
                                    return Material(
                                      color: secondaryColor,
                                      borderRadius: BorderRadius.circular(15),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(15),
                                        onTap: () {
                                          setState(() {
                                            _showAllImages = false;
                                          });
                                        },
                                        child: Center(
                                          child: Text(
                                            S.of(context).see_less,
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (!_showAllImages &&
                                      totalImages > 5 &&
                                      imageIndex == 4) {
                                    // Stack the View More button
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          child: allImages[imageIndex],
                                        ),

                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 3,
                                              sigmaY: 3,
                                            ),
                                            child: Material(
                                              color: secondaryColor.withOpacity(
                                                0.8,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                onTap: () {
                                                  setState(() {
                                                    _showAllImages = true;
                                                  });
                                                },
                                                child: Center(
                                                  child: Text(
                                                    "+${totalImages - 5} ${S.of(context).view_more}",
                                                    style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  // Show image normally
                                  final imgWidget = allImages[imageIndex];
                                  return _buildRemovableImage(
                                    context: context,
                                    imageWidget: imgWidget,
                                    onPreview: () {
                                      if (imageIndex <
                                          networkImageUrls.length) {
                                        showProfilePreview(
                                          context: context,
                                          isProfile: false,
                                          imageUrl:
                                              networkImageUrls[imageIndex],
                                        );
                                      } else {
                                        final file =
                                            fileImages[imageIndex -
                                                networkImageUrls.length];
                                        showProfilePreview(
                                          context: context,
                                          isProfile: false,
                                          file: file,
                                        );
                                      }
                                    },
                                    onRemove: () {
                                      setState(() {
                                        if (imageIndex <
                                            networkImageUrls.length) {
                                          networkImageUrls.removeAt(imageIndex);
                                        } else {
                                          fileImages.removeAt(
                                            imageIndex -
                                                networkImageUrls.length,
                                          );
                                        }
                                        detectChanges();
                                      });
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),

                      // if (networkImageUrls.isEmpty && fileImages.isEmpty)
                      //   Padding(
                      //     padding: const EdgeInsets.symmetric(horizontal: 7),
                      //     child: InkWell(
                      //       borderRadius: BorderRadius.circular(20.r),
                      //       onTap: () {
                      //         showModalBottomSheet(
                      //           context: context,
                      //           showDragHandle: true,
                      //           backgroundColor: scaffoldColor,
                      //           builder: (context) => PickImageSource(
                      //             galleryButton: () async {
                      //               await galleryImages();
                      //               if (!context.mounted) return;
                      //               Navigator.pop(context);
                      //             },
                      //             cameraButton: () async {
                      //               await cameraImages();
                      //               if (!context.mounted) return;
                      //               Navigator.pop(context);
                      //             },
                      //           ),
                      //         );
                      //       },
                      //       child: ClipRRect(
                      //         borderRadius: BorderRadius.circular(20.r),
                      //         child: Material(
                      //           color: lightGreyColor.withOpacity(0.3),
                      //           child: SizedBox(
                      //             height: 0.33.sh,
                      //             width: double.infinity,
                      //             child: Icon(
                      //               IconlyLight.image,
                      //               size: 0.13.sh,
                      //               color: greyColor.withOpacity(0.4),
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      //
                      // if (networkImageUrls.isNotEmpty || fileImages.isNotEmpty)
                      //   SizedBox(height: 15.h),
                      //
                      // if (networkImageUrls.isNotEmpty || fileImages.isNotEmpty)
                      //   SizedBox(
                      //     height: 0.23.sh,
                      //     child: ListView(
                      //       scrollDirection: Axis.horizontal,
                      //       children: [
                      //         const SizedBox(width: 7),
                      //         // ADD MORE Button
                      //         InkWell(
                      //           borderRadius: BorderRadius.circular(20.r),
                      //           onTap: () {
                      //             showModalBottomSheet(
                      //               context: context,
                      //               showDragHandle: true,
                      //               backgroundColor: scaffoldColor,
                      //               builder: (context) => PickImageSource(
                      //                 galleryButton: () async {
                      //                   await galleryImages();
                      //                   if (!context.mounted) return;
                      //                   Navigator.pop(context);
                      //                 },
                      //                 cameraButton: () async {
                      //                   await cameraImages();
                      //                   if (!context.mounted) return;
                      //                   Navigator.pop(context);
                      //                 },
                      //               ),
                      //             );
                      //           },
                      //           child: ClipRRect(
                      //             borderRadius: BorderRadius.circular(20.r),
                      //             child: Material(
                      //               color: lightGreyColor.withOpacity(0.3),
                      //               child: SizedBox(
                      //                 height: 1.sw,
                      //                 width: 200,
                      //                 child: Column(
                      //                   mainAxisAlignment:
                      //                       MainAxisAlignment.center,
                      //                   children: [
                      //                     Icon(
                      //                       IconlyLight.image,
                      //                       size: 65,
                      //                       color: textColor,
                      //                     ),
                      //                     Text(
                      //                       S.of(context).add_more,
                      //                       style: TextStyle(
                      //                         fontWeight: FontWeight.w800,
                      //                         fontSize: 17,
                      //                         color: textColor,
                      //                       ),
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //         const SizedBox(width: 7),
                      //         ...displayedImages,
                      //       ],
                      //     ),
                      //   ),
                      if (showImageError)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 8,
                          ),
                          child: Text(
                            S.of(context).image_validation,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).product_details,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          CustomFormField(
                            hasTitle: true,
                            textColor: textColor,
                            title: S.of(context).add_product_title,
                            hint: S.of(context).add_product_title_hint,
                            onTap: () {},
                            validator: (value) {
                              if (value!.isEmpty) {
                                return S.of(context).title_validation;
                              }
                              return null;
                            },
                            controller: titleController,
                            onChanged: (change) => setState(() {
                              capitalizeWords(change!);
                              detectChanges();
                            }),
                          ),
                          SizedBox(height: 15.h),
                          CustomFormField(
                            hasTitle: true,
                            textColor: textColor,
                            maxLines: 7,
                            title: S.of(context).add_product_description,
                            hint: S.of(context).add_product_description_hint,
                            onTap: () {},
                            validator: (value) {
                              if (value!.isEmpty) {
                                return S.of(context).description_validation;
                              }
                              return null;
                            },
                            controller: descController,
                            onChanged: (change) => setState(() {
                              detectChanges();
                            }),
                          ),
                          SizedBox(height: 15.h),
                          Row(
                            spacing: 5,
                            children: [
                              Expanded(
                                child: CustomFormField(
                                  hasTitle: true,
                                  textColor: textColor,
                                  title: S.of(context).price,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return S.of(context).price_validation;
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  prefix: const Icon(
                                    Icons.attach_money_rounded,
                                    color: textColor,
                                  ),
                                  hint: '- -',
                                  onTap: () {},
                                  controller: priceController,
                                  onChanged: (change) => setState(() {
                                    detectChanges();
                                  }),
                                ),
                              ),
                              Expanded(
                                child: CustomFormField(
                                  hasTitle: true,
                                  textColor: textColor,
                                  title: S.of(context).add_product_discount,
                                  validator: (value) => null,
                                  keyboardType: TextInputType.number,
                                  prefix: const Icon(
                                    Icons.percent_rounded,
                                    color: textColor,
                                  ),
                                  hint: '- -',
                                  controller: discountController,
                                  onChanged: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return;
                                    }

                                    final numericValue = value
                                        .replaceAll('%', '')
                                        .trim();
                                    if (value.endsWith('%')) return;

                                    final newValue = '$numericValue%';
                                    discountController.value = TextEditingValue(
                                      text: newValue,
                                      selection: TextSelection.collapsed(
                                        offset: newValue.length,
                                      ),
                                    );
                                    detectChanges();
                                  },
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15.h),
                          CustomFormField(
                            hasTitle: true,
                            textColor: textColor,
                            title: S.of(context).add_product_quantity,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return S.of(context).quantity_validation;
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            prefix: const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: textColor,
                            ),
                            hint: '- -',
                            onTap: () {},
                            controller: quantityController,
                            onChanged: (change) => setState(() {
                              detectChanges();
                            }),
                          ),
                          SizedBox(height: 15.h),
                          Text(
                            S.of(context).product_category,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomFormField(
                                readOnly: true,
                                controller: subCategoryController,
                                color: senderColor.withOpacity(0.3),
                                hint: S.of(context).product_category,
                                cursorColor: textColor,
                                fieldTextStyle: const TextStyle(
                                  color: textColor,
                                ),
                                hintStyle: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                ),
                                outlineInputBorder: OutlineInputBorder(
                                  borderRadius: subCategoryExpanded
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
                                    subCategoryExpanded = !subCategoryExpanded;
                                  });
                                },
                                suffix: Icon(
                                  subCategoryExpanded
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
                                height: subCategoryExpanded ? 290.h : 0,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                decoration: BoxDecoration(
                                  color: senderColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(20.r),
                                  ),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: subCategories.length,
                                  itemBuilder: (context, index) {
                                    final isSelected =
                                        selectedSubCategory == index;

                                    return SizedBox(
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
                                              subCategoryExpanded =
                                                  !subCategoryExpanded;
                                              selectedSubCategory = index;
                                              subCategoryController.text =
                                                  subCategories[selectedSubCategory];
                                              detectChanges();
                                            });
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.all(15),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  subCategories[index],
                                                  style: TextStyle(
                                                    fontSize: isSelected
                                                        ? 17
                                                        : 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? textColor
                                                        : textColor.withOpacity(
                                                            0.5,
                                                          ),
                                                  ),
                                                ),
                                                CircleAvatar(
                                                  backgroundColor: primaryColor,
                                                  radius: isSelected ? 12 : 0,
                                                  child: Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: isSelected ? 16 : 0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                S.of(context).specification_details,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ),
                              if (productSpecifications.isNotEmpty)
                                Material(
                                  color: formFieldColor,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      TextEditingController titleController =
                                          TextEditingController();
                                      // TextEditingController subTitleController =
                                      //     TextEditingController();
                                      AlertDialog alert = AlertDialog(
                                        title: Text(
                                          S.of(context).add_new_specification,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CustomFormField(
                                              hasTitle: false,
                                              textColor: textColor,
                                              hint: S
                                                  .of(context)
                                                  .specification_title_hint,
                                              onTap: () {},
                                              controller: titleController,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              S.of(context).cancel,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              final title = titleController.text
                                                  .trim();
                                              if (title.isEmpty) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      S
                                                          .of(context)
                                                          .specification_title_validation,
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              setState(() {
                                                addSpecification(title: title);
                                                hasChanged = true;
                                              });

                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              S.of(context).add,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return alert;
                                        },
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        spacing: 5,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color: textColor,
                                            size: 18,
                                          ),
                                          Text(
                                            S.of(context).add_new_btn,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              color: lightGreyColor.withOpacity(0.3),
                            ),
                            child: Center(
                              child: Column(
                                // mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: productSpecifications.length,
                                    itemBuilder: (context, index) => Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsetsGeometry.directional(
                                                    start: 15,
                                                  ),
                                              child: Text(
                                                productSpecifications[index]
                                                    .title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      productSpecifications
                                                          .removeAt(index);
                                                      hasChanged = true;
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    IconlyLight.delete,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: primaryColor,
                                                  ),
                                                  onPressed: () {
                                                    TextEditingController
                                                    editTitleController =
                                                        TextEditingController(
                                                          text:
                                                              productSpecifications[index]
                                                                  .title,
                                                        );
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) => Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Center(
                                                            child: AlertDialog(
                                                              title: Text(
                                                                S
                                                                    .of(context)
                                                                    .edit_specification,
                                                              ),
                                                              content: CustomFormField(
                                                                controller:
                                                                    editTitleController,
                                                                hasTitle: false,
                                                                textColor:
                                                                    textColor,
                                                                hint: S
                                                                    .of(context)
                                                                    .edit,
                                                                onTap: () {},
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                      ),
                                                                  child: Text(
                                                                    S
                                                                        .of(
                                                                          context,
                                                                        )
                                                                        .cancel,
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      productSpecifications[index]
                                                                          .title = editTitleController
                                                                          .text
                                                                          .trim();
                                                                      hasChanged =
                                                                          true;
                                                                    });
                                                                    Navigator.pop(
                                                                      context,
                                                                    );
                                                                  },
                                                                  child: Text(
                                                                    S
                                                                        .of(
                                                                          context,
                                                                        )
                                                                        .save,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8.h),
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          itemBuilder: (context, subIndex) => SizedBox(
                                            width: double.infinity,
                                            child: Row(
                                              spacing: 5,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      productSpecifications[index]
                                                          .subTitles
                                                          .removeAt(subIndex);
                                                      hasChanged = true;
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    IconlyLight.delete,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Material(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15.r,
                                                        ),
                                                    color: Colors.white,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            15.r,
                                                          ),
                                                      onTap: () {
                                                        TextEditingController
                                                        titleController =
                                                            TextEditingController(
                                                              text: productSpecifications[index]
                                                                  .subTitles[subIndex]
                                                                  .title,
                                                            );
                                                        TextEditingController
                                                        priceController =
                                                            TextEditingController(
                                                              text: productSpecifications[index]
                                                                  .subTitles[subIndex]
                                                                  .price
                                                                  .toString(),
                                                            );

                                                        showDialog(
                                                          context: context,
                                                          builder: (_) => Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Center(
                                                                child: AlertDialog(
                                                                  title: Text(
                                                                    S
                                                                        .of(
                                                                          context,
                                                                        )
                                                                        .edit_option,
                                                                  ),
                                                                  content: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      CustomFormField(
                                                                        controller:
                                                                            titleController,
                                                                        hasTitle:
                                                                            false,
                                                                        textColor:
                                                                            textColor,
                                                                        hint: S
                                                                            .of(
                                                                              context,
                                                                            )
                                                                            .option_title_hint,
                                                                        onTap:
                                                                            () {},
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            10,
                                                                      ),
                                                                      CustomFormField(
                                                                        controller:
                                                                            priceController,
                                                                        hasTitle:
                                                                            false,
                                                                        textColor:
                                                                            textColor,
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        hint: S
                                                                            .of(
                                                                              context,
                                                                            )
                                                                            .option_price_hint,
                                                                        onTap:
                                                                            () {},
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.pop(
                                                                            context,
                                                                          ),
                                                                      child: Text(
                                                                        S
                                                                            .of(
                                                                              context,
                                                                            )
                                                                            .cancel,
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        setState(() {
                                                                          productSpecifications[index]
                                                                              .subTitles[subIndex]
                                                                              .title = titleController
                                                                              .text
                                                                              .trim();
                                                                          productSpecifications[index].subTitles[subIndex].price =
                                                                              num.tryParse(
                                                                                priceController.text.trim(),
                                                                              ) ??
                                                                              0;
                                                                          hasChanged =
                                                                              true;
                                                                        });
                                                                        Navigator.pop(
                                                                          context,
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        S
                                                                            .of(
                                                                              context,
                                                                            )
                                                                            .save,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                      child: Padding(
                                                        padding: EdgeInsets.all(
                                                          20,
                                                        ),
                                                        child: Row(
                                                          spacing: 10,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                productSpecifications[index]
                                                                    .subTitles[subIndex]
                                                                    .title,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: textColor
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                            // const Spacer(),
                                                            Text(
                                                              'AED ${productSpecifications[index].subTitles[subIndex].price.toString()}',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: textColor
                                                                    .withOpacity(
                                                                      0.7,
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
                                          ),
                                          separatorBuilder: (context, index) =>
                                              SizedBox(height: 10),
                                          itemCount:
                                              productSpecifications[index]
                                                  .subTitles
                                                  .length,
                                        ),
                                        SizedBox(height: 15),
                                        InkWell(
                                          onTap: () {
                                            TextEditingController
                                            subTitleController =
                                                TextEditingController();
                                            TextEditingController
                                            priceController =
                                                TextEditingController();
                                            AlertDialog alert = AlertDialog(
                                              title: Text(
                                                S.of(context).add_option,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CustomFormField(
                                                    hasTitle: false,
                                                    textColor: textColor,
                                                    keyboardType:
                                                        TextInputType.text,
                                                    hint: S
                                                        .of(context)
                                                        .option_title_hint,
                                                    onTap: () {},
                                                    controller:
                                                        subTitleController,
                                                  ),
                                                  SizedBox(height: 15),
                                                  CustomFormField(
                                                    hasTitle: false,
                                                    textColor: textColor,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    hint: S
                                                        .of(context)
                                                        .option_price_hint,
                                                    onTap: () {},
                                                    controller: priceController,
                                                  ),
                                                  SizedBox(height: 15),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    S.of(context).cancel,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    final subtitle =
                                                        subTitleController.text
                                                            .trim();
                                                    final price =
                                                        priceController.text
                                                            .trim();

                                                    if (subtitle.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            S
                                                                .of(context)
                                                                .option_title_validation,
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    if (price.isEmpty ||
                                                        double.tryParse(
                                                              price,
                                                            ) ==
                                                            null) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            S
                                                                .of(context)
                                                                .option_price_validation,
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    addSubTitle(
                                                      subtitle: subtitle,
                                                      price: double.parse(
                                                        price,
                                                      ),
                                                      index: index,
                                                    );
                                                    setState(() {
                                                      hasChanged = true;
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    S.of(context).add,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return alert;
                                              },
                                            );
                                          },
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 60,
                                            child: Material(
                                              borderRadius:
                                                  BorderRadius.circular(15.r),
                                              color: Colors.green,
                                              child: Center(
                                                child: Text(
                                                  S.of(context).add_option,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    separatorBuilder: (context, index) =>
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 15,
                                            bottom: 5,
                                          ),
                                          child: Divider(
                                            thickness: 2,
                                            color: greyColor.withOpacity(0.3),
                                          ),
                                        ),
                                  ),
                                  if (productSpecifications.isEmpty)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(10.w),
                                      onTap: () {
                                        TextEditingController titleController =
                                            TextEditingController();
                                        // TextEditingController subTitleController =
                                        //     TextEditingController();
                                        AlertDialog alert = AlertDialog(
                                          title: Text(
                                            S.of(context).add_new_specification,
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CustomFormField(
                                                hasTitle: false,
                                                textColor: textColor,
                                                hint: S
                                                    .of(context)
                                                    .specification_title_hint,
                                                onTap: () {},
                                                controller: titleController,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                S.of(context).cancel,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final title = titleController
                                                    .text
                                                    .trim();

                                                if (title.isEmpty) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        S
                                                            .of(context)
                                                            .specification_title_validation,
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                addSpecification(title: title);
                                                detectChanges(); // ✅ mark draft as changed
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                S.of(context).add,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return alert;
                                          },
                                        );
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 10.h,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.add,
                                              color: textColor.withOpacity(0.4),
                                            ),
                                            SizedBox(width: 10.w),
                                            Text(
                                              S
                                                  .of(context)
                                                  .add_new_specification,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: textColor.withOpacity(
                                                  0.6,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 170),
                ],
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
                            color: !hasChanged ? Colors.grey : primaryColor,
                            elevation: 15,
                            shadowColor: !hasChanged
                                ? Colors.grey.withOpacity(0.5)
                                : primaryColor.withOpacity(0.5),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(17.r),
                              onTap: !hasChanged
                                  ? null
                                  : () async {
                                      // Check connection first
                                      if (!isInitialInternetAvailable) {
                                        log("NO Connection");
                                        snack(context);
                                        return;
                                      } else {
                                        if ((!formKey.currentState!
                                                .validate()) &&
                                            (productImages.isNotEmpty)) {
                                          setState(() {
                                            showImageError = true;
                                            isUploading = true;
                                          });
                                          return;
                                        }

                                        setState(() {
                                          showImageError = false;
                                        });

                                        if (widget.edit!) {
                                          await ProductCubit.get(
                                            context,
                                          ).editProduct(
                                            context: context,
                                            productModel: widget.draftProduct!,
                                            newTitle: titleController.text,
                                            newDescription: descController.text,
                                            newPrice: num.parse(
                                              priceController.text,
                                            ),
                                            newDiscount:
                                                discountController.text
                                                    .trim()
                                                    .isEmpty
                                                ? 0
                                                : int.parse(
                                                    discountController.text
                                                        .replaceAll('%', '')
                                                        .trim(),
                                                  ),
                                            newQuantity: num.parse(
                                              quantityController.text,
                                            ),
                                            newSpecifications:
                                                productSpecifications,
                                            newProductCategory:
                                                subCategories[selectedSubCategory],
                                            remainingNetworkImages:
                                                networkImageUrls,
                                            newFileImages: fileImages,
                                          );
                                        } else {
                                          await ProductCubit.get(
                                            context,
                                          ).addProduct(
                                            context: context,
                                            shopModel: widget.shopModel!,
                                            title: capitalizeWords(
                                              titleController.text.trim(),
                                            ),
                                            description: descController.text
                                                .trim(),
                                            images: fileImages,
                                            price: num.parse(
                                              priceController.text,
                                            ),
                                            discount:
                                                discountController.text
                                                    .trim()
                                                    .isEmpty
                                                ? 0
                                                : int.parse(
                                                    discountController.text
                                                        .replaceAll('%', '')
                                                        .trim(),
                                                  ),
                                            quantity: num.parse(
                                              quantityController.text,
                                            ),
                                            specifications:
                                                productSpecifications,
                                            productCategory:
                                                subCategories[selectedSubCategory],
                                          );
                                        }

                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                      }
                                    },
                              child: ConditionalBuilder(
                                condition: !isUploading,
                                builder: (context) => Center(
                                  child: Text(
                                    state is ProductAddProductSuccessState
                                        ? widget.edit!
                                              ? S.of(context).successfully_saved
                                              : S
                                                    .of(context)
                                                    .successfully_created
                                        : state is ProductAddProductLoadingState
                                        ? "${S.of(context).loading}..."
                                        : widget.edit!
                                        ? S.of(context).save_changes
                                        : S.of(context).publish,
                                    style: TextStyle(
                                      height: 0.8,
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                fallback: (context) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
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
          ),
        );
      },
    );
  }

  void addSpecification({required String title}) {
    productSpecifications.add(
      ProductSpecificationModel(title: title, subTitles: []),
    );
  }

  void addSubTitle({
    required String subtitle,
    required num price,
    required int index,
  }) {
    productSpecifications[index].subTitles.add(
      ProductSpecificationValueModel(title: subtitle, price: price),
    );
    setState(() {});
  }

  Widget _buildRemovableImage({
    required BuildContext context,
    required Widget imageWidget,
    required VoidCallback onRemove,
    required VoidCallback onPreview,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onPreview,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: imageWidget,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> get displayedImages {
    List<Widget> widgets = [];

    if (widget.edit! && networkImageUrls.isNotEmpty) {
      widgets.addAll(
        networkImageUrls.map(
          (url) => Padding(
            padding: const EdgeInsets.only(right: 7),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.network(
                    url,
                    height: 0.23.sh,
                    width: 0.5.sw,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        networkImageUrls.remove(url);
                        detectChanges();
                      });
                    },
                    child: const CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    widgets.addAll(
      fileImages.map(
        (xfile) => Padding(
          padding: const EdgeInsets.only(right: 7),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Image.file(
                  File(xfile.path),
                  height: 0.23.sh,
                  width: 0.5.sw,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      fileImages.remove(xfile);
                      detectChanges();
                    });
                  },
                  child: const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return widgets;
  }
}
