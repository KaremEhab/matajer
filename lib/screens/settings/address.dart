
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
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
  late List<String> originalAddresses;
  late String originalCurrentAddress;

  late String selectedAddress; // local selection
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    originalAddresses = List<String>.from(currentUserModel.addresses);
    originalCurrentAddress = currentUserModel.currentAddress;
    selectedAddress = currentUserModel.currentAddress;
  }

  void checkForChanges() {
    final currentList = currentUserModel.addresses;
    final listChanged =
        currentList.length != originalAddresses.length ||
        !ListEquality().equals(currentList, originalAddresses);

    final addressChanged = selectedAddress != originalCurrentAddress;

    setState(() {
      hasChanges = listChanged || addressChanged;
    });
  }

  Future<void> saveChanges() async {
    // Update both addresses and currentAddress in Firebase
    await ProductCubit.get(context).setCurrentAddress(address: selectedAddress);

    // Reset original state
    originalAddresses = List<String>.from(currentUserModel.addresses);
    originalCurrentAddress = selectedAddress;
    checkForChanges();
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
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
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
                  SizedBox(height: 20),
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
                              await ProductCubit.get(
                                context,
                              ).addNewAddress(address: selected);
                              setState(() {
                                selectedAddress = selected;
                              });
                              checkForChanges();
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
                                    SizedBox(width: 15),
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

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentUserModel.addresses.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final address = currentUserModel.addresses[index];
                            final isSingleAddress =
                                currentUserModel.addresses.length == 1;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedAddress =
                                      address; // update local UI state
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
                                      // <-- This allows wrapping and prevents overflow
                                      child: Row(
                                        children: [
                                          isSingleAddress
                                              ? Icon(
                                                  IconlyLight.location,
                                                  size: 28,
                                                  color: textColor,
                                                )
                                              : Radio<String>(
                                                  value: address,
                                                  activeColor: primaryColor,
                                                  groupValue: selectedAddress,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedAddress = value!;
                                                    });
                                                    checkForChanges();
                                                  },
                                                ),
                                          SizedBox(width: 15),
                                          Expanded(
                                            // <-- This ensures the text wraps instead of overflowing
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.your_delivery_address,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: textColor,
                                                  ),
                                                  overflow: TextOverflow
                                                      .ellipsis, // optional
                                                ),
                                                Text(
                                                  address,
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
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
                                        TextEditingController
                                        addressController =
                                            TextEditingController(
                                              text: address,
                                            );
                                        AlertDialog alert = AlertDialog(
                                          title: Text(s.edit_address),
                                          content: TextFormField(
                                            controller: addressController,
                                            decoration: InputDecoration(
                                              hintText: s.enter_your_address,
                                              hintStyle: TextStyle(
                                                color: textColor.withOpacity(
                                                  0.5,
                                                ),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                                borderSide: BorderSide(
                                                  color: textColor.withOpacity(
                                                    0.5,
                                                  ),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                                borderSide: const BorderSide(
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                s.cancel,
                                                style: TextStyle(
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await ProductCubit.get(
                                                  context,
                                                ).changeSpecificAddress(
                                                  index: index,
                                                  newAddress:
                                                      addressController.text,
                                                );
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
      },
    );
  }
}
