import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/models/shop_model.dart';

class ManageShopPage extends StatefulWidget {
  final ShopModel shopModel;

  const ManageShopPage({super.key, required this.shopModel});

  @override
  State<ManageShopPage> createState() => _ManageShopPageState();
}

class _ManageShopPageState extends State<ManageShopPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController shopNameController;
  late TextEditingController shopCategoryController;
  late TextEditingController shopDescriptionController;
  late TextEditingController deliveryDaysController;
  late TextEditingController avgResponseTimeController;
  late TextEditingController licenseNumberController;

  File? newLogoFile;
  File? newBannerFile;
  File? newLicenseFile;

  bool autoAcceptOrders = false;
  ShopActivityStatus activityStatus = ShopActivityStatus.online;

  @override
  void initState() {
    super.initState();
    final shop = currentShopModel!;

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
    activityStatus = shop.activityStatus;
  }

  @override
  void dispose() {
    shopNameController.dispose();
    shopCategoryController.dispose();
    shopDescriptionController.dispose();
    deliveryDaysController.dispose();
    avgResponseTimeController.dispose();
    licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source, String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        if (type == 'logo') newLogoFile = File(picked.path);
        if (type == 'banner') newBannerFile = File(picked.path);
        if (type == 'license') newLicenseFile = File(picked.path);
      });
    }
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final shopDoc = FirebaseFirestore.instance
          .collection('shops')
          .doc(currentShopModel!.shopId);

      // Upload new images if selected
      String logoUrl = currentShopModel!.shopLogoUrl;
      String bannerUrl = currentShopModel!.shopBannerUrl;
      String licenseUrl = currentShopModel!.sellerLicenseImageUrl;

      if (newLogoFile != null) {
        logoUrl = await UserCubit.get(context).uploadImage(
          image: XFile(newLogoFile!.path),
          docId: shopDoc.id,
          imageName: 'shopLogo',
        );
      }
      if (newBannerFile != null) {
        bannerUrl = await UserCubit.get(context).uploadImage(
          image: XFile(newBannerFile!.path),
          docId: shopDoc.id,
          imageName: 'shopBanner',
        );
      }
      if (newLicenseFile != null) {
        licenseUrl = await UserCubit.get(context).uploadImage(
          image: XFile(newLicenseFile!.path),
          docId: shopDoc.id,
          imageName: 'sellerLicense',
        );
      }

      final updatedShop = currentShopModel!.copyWith(
        shopName: shopNameController.text.trim(),
        shopCategory: shopCategoryController.text.trim(),
        shopDescription: shopDescriptionController.text.trim(),
        deliveryDays: num.tryParse(deliveryDaysController.text.trim()) ?? 0,
        avgResponseTime:
            num.tryParse(avgResponseTimeController.text.trim()) ?? 0,
        sellerLicenseNumber:
            num.tryParse(licenseNumberController.text.trim()) ?? 0,
        shopLogoUrl: logoUrl,
        shopBannerUrl: bannerUrl,
        sellerLicenseImageUrl: licenseUrl,
        autoAcceptOrders: autoAcceptOrders,
        activityStatus: activityStatus,
      );

      await shopDoc.update(updatedShop.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      log('ManageShopPage Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update shop: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Shop'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => pickImage(ImageSource.gallery, 'logo'),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: newLogoFile != null
                          ? FileImage(newLogoFile!)
                          : NetworkImage(currentShopModel!.shopLogoUrl)
                                as ImageProvider,
                    ),
                  ),
                  InkWell(
                    onTap: () => pickImage(ImageSource.gallery, 'banner'),
                    child: Container(
                      width: 120,
                      height: 60,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: newBannerFile != null
                              ? FileImage(newBannerFile!)
                              : NetworkImage(currentShopModel!.shopBannerUrl)
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => pickImage(ImageSource.gallery, 'license'),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: newLicenseFile != null
                          ? Image.file(newLicenseFile!, fit: BoxFit.cover)
                          : Image.network(
                              currentShopModel!.sellerLicenseImageUrl,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Shop Name
              TextFormField(
                controller: shopNameController,
                decoration: const InputDecoration(labelText: 'Shop Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Shop Category
              TextFormField(
                controller: shopCategoryController,
                decoration: const InputDecoration(labelText: 'Shop Category'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Shop Description
              TextFormField(
                controller: shopDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Shop Description',
                ),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Delivery Days & Avg Response Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: deliveryDaysController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Days',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: avgResponseTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Avg Response Time',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // License Number
              TextFormField(
                controller: licenseNumberController,
                decoration: const InputDecoration(labelText: 'License Number'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),

              // Auto Accept Orders Toggle
              SwitchListTile(
                title: const Text('Auto Accept Orders'),
                value: autoAcceptOrders,
                onChanged: (v) => setState(() => autoAcceptOrders = v),
              ),

              // Activity Status
              DropdownButtonFormField<ShopActivityStatus>(
                value: activityStatus,
                items: ShopActivityStatus.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => activityStatus = v!),
                decoration: const InputDecoration(labelText: 'Activity Status'),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
