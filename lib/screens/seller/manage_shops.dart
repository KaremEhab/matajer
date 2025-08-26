import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
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

  bool autoAcceptOrders = false;

  File? newLogoFile;
  File? newBannerFile;
  File? newLicenseFile;

  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
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
        deliveryDays: int.tryParse(deliveryDaysController.text) ?? 0,
        avgResponseTime: int.tryParse(avgResponseTimeController.text) ?? 0,
        sellerLicenseNumber: num.parse(licenseNumberController.text.trim()),
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

  Widget buildImagePreview(String url, File? file, String type) {
    return Column(
      children: [
        InkWell(
          onTap: () => pickImage(type),
          child: CircleAvatar(
            radius: 40,
            backgroundImage: file != null
                ? FileImage(file)
                : NetworkImage(url) as ImageProvider,
          ),
        ),
        Text(type.toUpperCase()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shopModel;

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Shop")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildImagePreview(shop.shopLogoUrl, newLogoFile, 'logo'),
                  buildImagePreview(
                    shop.shopBannerUrl,
                    newBannerFile,
                    'banner',
                  ),
                  buildImagePreview(
                    shop.sellerLicenseImageUrl,
                    newLicenseFile,
                    'license',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Text Fields
              TextFormField(
                controller: shopNameController,
                decoration: const InputDecoration(labelText: "Shop Name"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                onChanged: (_) => checkForChanges(),
              ),
              TextFormField(
                controller: shopCategoryController,
                decoration: const InputDecoration(labelText: "Category"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                onChanged: (_) => checkForChanges(),
              ),
              TextFormField(
                controller: shopDescriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                onChanged: (_) => checkForChanges(),
              ),
              TextFormField(
                controller: deliveryDaysController,
                decoration: const InputDecoration(labelText: "Delivery Days"),
                keyboardType: TextInputType.number,
                onChanged: (_) => checkForChanges(),
              ),
              TextFormField(
                controller: avgResponseTimeController,
                decoration: const InputDecoration(
                  labelText: "Avg Response Time (mins)",
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => checkForChanges(),
              ),
              TextFormField(
                controller: licenseNumberController,
                decoration: const InputDecoration(labelText: "License Number"),
                onChanged: (_) => checkForChanges(),
              ),

              const SizedBox(height: 16),

              // Toggles
              SwitchListTile(
                title: const Text("Auto Accept Orders"),
                value: autoAcceptOrders,
                onChanged: (val) {
                  setState(() => autoAcceptOrders = val);
                  checkForChanges();
                },
              ),

              const SizedBox(height: 20),

              // Save button
              ElevatedButton(
                onPressed: hasChanges ? saveChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasChanges ? primaryColor : Colors.grey,
                ),
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
