import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:collection/collection.dart'; // for DeepCollectionEquality
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/maps/map_picker.dart';

class SavedAddress extends StatefulWidget {
  const SavedAddress({super.key});

  @override
  State<SavedAddress> createState() => _SavedAddressState();
}

class _SavedAddressState extends State<SavedAddress> {
  late List<Map<String, dynamic>> originalAddresses;
  late Map<String, dynamic>? originalCurrentAddress;

  late Map<String, dynamic> selectedAddress; // local selection
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    originalAddresses = List<Map<String, dynamic>>.from(
      currentUserModel.addresses,
    );
    originalCurrentAddress = currentUserModel.currentAddress;
    selectedAddress = currentUserModel.currentAddress ?? {};
  }

  void checkForChanges() {
    final currentList = currentUserModel.addresses;
    final listChanged =
        currentList.length != originalAddresses.length ||
        !const DeepCollectionEquality().equals(currentList, originalAddresses);

    final addressChanged = !const DeepCollectionEquality().equals(
      selectedAddress,
      originalCurrentAddress,
    );

    setState(() {
      hasChanges = listChanged || addressChanged;
    });
  }

  Future<void> saveChanges() async {
    if (selectedAddress.isNotEmpty) {
      await ProductCubit.get(
        context,
      ).setCurrentAddress(addressObj: selectedAddress);
      originalAddresses = List<Map<String, dynamic>>.from(
        currentUserModel.addresses,
      );
      originalCurrentAddress = Map<String, dynamic>.from(selectedAddress);
      checkForChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductSaveAddressSuccessState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.address_saved_success)));
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
            title: Text(
              s.delivery_address,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Text(
                    s.delivery_address_subtitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  Text(
                    s.delivery_address_hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      height: 1.1,
                      color: textColor.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: greyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15.r),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            final selected = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MapPickerScreen(),
                              ),
                            );
                            if (selected != null && selected.isNotEmpty) {
                              final nameController = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (_) {
                                  return AlertDialog(
                                    title: Text(s.enter_address_name),
                                    content: TextFormField(
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        hintText: s.enter_address_name,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(s.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final newAddress = {
                                            "name": nameController.text,
                                            "address": selected,
                                          };
                                          await ProductCubit.get(
                                            context,
                                          ).addNewAddress(
                                            name: nameController.text,
                                            address: selected,
                                          );
                                          setState(() {
                                            selectedAddress = newAddress;
                                          });
                                          checkForChanges();
                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                        },
                                        child: Text(s.save),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 25,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.add, size: 25, color: textColor),
                                    const SizedBox(width: 15),
                                    Text(
                                      s.add_new_location,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.add_location_outlined,
                                  size: 25,
                                  color: textColor,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Address list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentUserModel.addresses.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final addressMap =
                                currentUserModel.addresses[index];
                            final name = addressMap['name'] ?? 'Address';
                            final address = addressMap['address'] ?? '';
                            final isSingleAddress =
                                currentUserModel.addresses.length == 1;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedAddress = addressMap;
                                });
                                checkForChanges();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          isSingleAddress
                                              ? Icon(
                                                  IconlyLight.location,
                                                  size: 28,
                                                  color: textColor,
                                                )
                                              : Radio<Map<String, dynamic>>(
                                                  value: addressMap,
                                                  activeColor: primaryColor,
                                                  groupValue: selectedAddress,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedAddress = value!;
                                                    });
                                                    checkForChanges();
                                                  },
                                                ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              spacing: 5,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: textColor,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  address,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        final nameController =
                                            TextEditingController(text: name);
                                        final addressController =
                                            TextEditingController(
                                              text: address,
                                            );

                                        AlertDialog alert = AlertDialog(
                                          title: Text(s.edit_address),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextFormField(
                                                controller: nameController,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      s.enter_address_name,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: addressController,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      s.enter_your_address,
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(s.cancel),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final updated = {
                                                  "name": nameController.text,
                                                  "address":
                                                      addressController.text,
                                                };
                                                await ProductCubit.get(
                                                  context,
                                                ).changeSpecificAddress(
                                                  index: index,
                                                  addressObj: updated,
                                                );
                                                setState(() {
                                                  selectedAddress = updated;
                                                });
                                                checkForChanges();
                                                if (!context.mounted) return;
                                                Navigator.pop(context);
                                              },
                                              child: Text(s.update),
                                            ),
                                          ],
                                        );
                                        showDialog(
                                          context: context,
                                          builder: (_) => alert,
                                        );
                                      },
                                      icon: Icon(
                                        Icons.edit,
                                        color: textColor,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                child: Column(
                  children: [
                    SizedBox(
                      height: 0.07.sh,
                      width: 0.9.sw,
                      child: Material(
                        borderRadius: BorderRadius.circular(17.r),
                        color: hasChanges
                            ? primaryColor
                            : Colors.grey.withOpacity(0.5),
                        elevation: hasChanges ? 15 : 0,
                        shadowColor: primaryColor.withOpacity(0.5),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17.r),
                          onTap: hasChanges ? saveChanges : null,
                          child: Center(
                            child: Text(
                              s.save_changes,
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
        );
      },
    );
  }
}
