import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/paypal/success_payment.dart';
import 'package:uuid/uuid.dart';

class Checkout extends StatefulWidget {
  const Checkout({
    super.key,
    required this.total,
    required this.shopId,
    required this.deliveryTime,
  });

  final num total;
  final num deliveryTime;
  final String shopId;

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductPaypalPaySuccessState) {
          // navigateTo(
          //   context: context,
          //   screen: PayPalPage(paypalLink: state.paymentLink, shopId: widget.shopId),
          // );
          final String randomOrderId = const Uuid().v4();

          navigateTo(
            context: context,
            screen: SuccessPayment(
              orderId: randomOrderId,
              shopId: widget.shopId,
              deliveryTime: widget.deliveryTime,
            ),
          );
        }
        if (state is ProductPlaceOrderErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: primaryColor),
          );
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
                lang == 'ar' ? 7 : 0,
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
              S.of(context).checkout,
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Material(
                    color: greyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15.r),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            TextEditingController addressController =
                                TextEditingController();
                            AlertDialog alert = AlertDialog(
                              title: Text(S.of(context).add_address_title),
                              content: TextFormField(
                                controller: addressController,
                                decoration: InputDecoration(
                                  hintText: S.of(context).enter_your_address,
                                  hintStyle: TextStyle(
                                    color: textColor.withOpacity(0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                    borderSide: BorderSide(
                                      color: textColor.withOpacity(0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                    borderSide: const BorderSide(
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    S.of(context).cancel,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await ProductCubit.get(
                                      context,
                                    ).addNewAddress(
                                      address: addressController.text,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  },
                                  child: Text(S.of(context).add),
                                ),
                              ],
                            );
                            showDialog(context: context, builder: (_) => alert);
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
                                      S.of(context).add_new_location,
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
                              onTap: () async {
                                await ProductCubit.get(
                                  context,
                                ).setCurrentAddress(address: address);
                                log(
                                  "1- Current Address is: ${currentUserModel.currentAddress}",
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        isSingleAddress
                                            ? Icon(
                                                IconlyLight.location,
                                                size: 28,
                                                color: textColor,
                                              )
                                            : Radio<String>(
                                                value: address,
                                                groupValue: currentUserModel
                                                    .currentAddress,
                                                onChanged: (value) async {
                                                  await ProductCubit.get(
                                                    context,
                                                  ).setCurrentAddress(
                                                    address: value!,
                                                  );
                                                  log(
                                                    "2- Current Address is: ${currentUserModel.currentAddress}",
                                                  );
                                                },
                                              ),
                                        SizedBox(width: 15),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              S
                                                  .of(context)
                                                  .your_delivery_address,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: textColor,
                                              ),
                                            ),
                                            Text(
                                              address,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: textColor.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        TextEditingController
                                        addressController =
                                            TextEditingController(
                                              text: address,
                                            );
                                        AlertDialog alert = AlertDialog(
                                          title: Text(
                                            S.of(context).edit_address,
                                          ),
                                          content: TextFormField(
                                            controller: addressController,
                                            decoration: InputDecoration(
                                              hintText: S
                                                  .of(context)
                                                  .enter_your_address,
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
                                                S.of(context).cancel,
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
                                              child: Text(S.of(context).update),
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
                  // Container(
                  //   width: double.infinity,
                  //   decoration: BoxDecoration(
                  //     color: greyColor.withOpacity(0.15),
                  //     borderRadius: BorderRadius.circular(15.r),
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       InkWell(
                  //         borderRadius: BorderRadius.vertical(
                  //           top: Radius.circular(15.r),
                  //         ),
                  //         onTap: () {},
                  //         child: Padding(
                  //           padding: EdgeInsets.symmetric(
                  //             horizontal: 20.w,
                  //             vertical: 26.h,
                  //           ),
                  //           child: Column(
                  //             children: [
                  //               Row(
                  //                 mainAxisAlignment:
                  //                     MainAxisAlignment.spaceBetween,
                  //                 children: [
                  //                   Row(
                  //                     children: [
                  //                       Icon(
                  //                         IconlyLight.location,
                  //                         size: 28.h,
                  //                         color: textColor,
                  //                       ),
                  //                       SizedBox(width: 15.w),
                  //                       Column(
                  //                         crossAxisAlignment:
                  //                             CrossAxisAlignment.start,
                  //                         children: [
                  //                           Text(
                  //                             S
                  //                                 .of(context)
                  //                                 .your_delivery_address,
                  //                             style: TextStyle(
                  //                               fontSize: 17.sp,
                  //                               fontWeight: FontWeight.w700,
                  //                               color: textColor,
                  //                             ),
                  //                           ),
                  //                           Text(
                  //                             currentUserModel.currentAddress,
                  //                             style: TextStyle(
                  //                               fontSize: 15.sp,
                  //                               fontWeight: FontWeight.w500,
                  //                               color: textColor.withOpacity(
                  //                                 0.7,
                  //                               ),
                  //                             ),
                  //                           ),
                  //                         ],
                  //                       ),
                  //                     ],
                  //                   ),
                  //                   Material(
                  //                     color: transparentColor,
                  //                     shape: const CircleBorder(),
                  //                     child: InkWell(
                  //                       borderRadius: BorderRadius.circular(
                  //                         200,
                  //                       ),
                  //                       onTap: () {
                  //                         TextEditingController
                  //                         addressController =
                  //                             TextEditingController();
                  //                         AlertDialog alert = AlertDialog(
                  //                           title: Text(
                  //                             S.of(context).add_address_title,
                  //                           ),
                  //                           content: TextField(
                  //                             controller: addressController,
                  //                             decoration: InputDecoration(
                  //                               hintText: S
                  //                                   .of(context)
                  //                                   .enter_your_address,
                  //                             ),
                  //                           ),
                  //                           actions: [
                  //                             TextButton(
                  //                               onPressed: () {
                  //                                 Navigator.pop(context);
                  //                               },
                  //                               child: Text(
                  //                                 S.of(context).cancel,
                  //                                 style: TextStyle(
                  //                                   color: Colors.black,
                  //                                 ),
                  //                               ),
                  //                             ),
                  //                             TextButton(
                  //                               onPressed: () {
                  //                                 setState(() {
                  //                                   currentUserModel
                  //                                           .currentAddress =
                  //                                       addressController.text;
                  //                                 });
                  //                                 Navigator.pop(context);
                  //                               },
                  //                               child: Text(S.of(context).add),
                  //                             ),
                  //                           ],
                  //                         );
                  //                         showDialog(
                  //                           context: context,
                  //                           builder: (BuildContext context) {
                  //                             return alert;
                  //                           },
                  //                         );
                  //                       },
                  //                       child: Padding(
                  //                         padding: const EdgeInsets.all(6),
                  //                         child:
                  //                             currentUserModel.currentAddress !=
                  //                                 ''
                  //                             ? Icon(
                  //                                 Icons.edit,
                  //                                 color: textColor,
                  //                                 size: 22.h,
                  //                               )
                  //                             : Icon(
                  //                                 Icons.add,
                  //                                 color: textColor,
                  //                                 size: 22.h,
                  //                               ),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //       // Padding(
                  //       //   padding: EdgeInsets.symmetric(horizontal: 20.w),
                  //       //   child: Divider(
                  //       //     color: greyColor.withOpacity(0.2),
                  //       //     thickness: 2,
                  //       //   ),
                  //       // ),
                  //       // Padding(
                  //       //   padding: EdgeInsets.symmetric(
                  //       //       horizontal: 20.w, vertical: 25.h),
                  //       //   child: Column(
                  //       //     children: [
                  //       //       Row(
                  //       //         children: [
                  //       //           Icon(
                  //       //             Icons.delivery_dining_rounded,
                  //       //             size: 28.h,
                  //       //             color: textColor,
                  //       //           ),
                  //       //           SizedBox(
                  //       //             width: 15.w,
                  //       //           ),
                  //       //           Column(
                  //       //             crossAxisAlignment: CrossAxisAlignment.start,
                  //       //             children: [
                  //       //               Text(
                  //       //                 'Your Order Status',
                  //       //                 style: TextStyle(
                  //       //                   fontSize: 17.sp,
                  //       //                   fontWeight: FontWeight.w700,
                  //       //                   color: textColor,
                  //       //                 ),
                  //       //               ),
                  //       //               Text(
                  //       //                 'Shipped',
                  //       //                 style: TextStyle(
                  //       //                   fontSize: 15.sp,
                  //       //                   fontWeight: FontWeight.w500,
                  //       //                   color: textColor.withOpacity(0.7),
                  //       //                 ),
                  //       //               ),
                  //       //             ],
                  //       //           ),
                  //       //         ],
                  //       //       ),
                  //       //       SizedBox(
                  //       //         height: 6.h,
                  //       //       ),
                  //       //     ],
                  //       //   ),
                  //       // ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: greyColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 15.h,
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 10.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.paypal_rounded,
                                          size: 32.h,
                                          color: Colors.blueAccent,
                                        ),
                                        SizedBox(width: 15.w),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              S.of(context).paypal,
                                              style: TextStyle(
                                                fontSize: 20.sp,
                                                fontWeight: FontWeight.w800,
                                                color: textColor,
                                              ),
                                            ),
                                            Text(
                                              S.of(context).your_payment_method,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w500,
                                                color: textColor.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Padding(
                        //   padding: EdgeInsets.symmetric(
                        //       horizontal: 20.w, vertical: 15.h),
                        //   child: Column(
                        //     children: [
                        //       // InkWell(
                        //       //   onTap: () {},
                        //       //   child: Row(
                        //       //     children: [
                        //       //       SvgPicture.asset(
                        //       //         'images/mastercard_icon.svg',
                        //       //         height: 32.h,
                        //       //       ),
                        //       //       SizedBox(
                        //       //         width: 15.w,
                        //       //       ),
                        //       //       Row(
                        //       //         mainAxisAlignment: MainAxisAlignment.center,
                        //       //         children: [
                        //       //           Icon(
                        //       //             Icons.add,
                        //       //             size: 23.h,
                        //       //             color: textColor.withOpacity(0.5),
                        //       //           ),
                        //       //           SizedBox(
                        //       //             width: 3.w,
                        //       //           ),
                        //       //           Text(
                        //       //             'Add new mastercard',
                        //       //             style: TextStyle(
                        //       //               fontSize: 16.sp,
                        //       //               fontWeight: FontWeight.w600,
                        //       //               color: textColor.withOpacity(0.5),
                        //       //             ),
                        //       //           ),
                        //       //         ],
                        //       //       ),
                        //       //     ],
                        //       //   ),
                        //       // ),
                        //       // SizedBox(
                        //       //   height: 10.h,
                        //       // ),
                        //       // InkWell(
                        //       //   onTap: () {},
                        //       //   child: Row(
                        //       //     children: [
                        //       //       Icon(
                        //       //         Icons.apple_rounded,
                        //       //         size: 32.h,
                        //       //         color: textColor,
                        //       //       ),
                        //       //       SizedBox(
                        //       //         width: 15.w,
                        //       //       ),
                        //       //       Row(
                        //       //         mainAxisAlignment: MainAxisAlignment.center,
                        //       //         children: [
                        //       //           Icon(
                        //       //             Icons.add,
                        //       //             size: 23.h,
                        //       //             color: textColor.withOpacity(0.5),
                        //       //           ),
                        //       //           SizedBox(
                        //       //             width: 3.w,
                        //       //           ),
                        //       //           Text(
                        //       //             'Use Apple Pay',
                        //       //             style: TextStyle(
                        //       //               fontSize: 16.sp,
                        //       //               fontWeight: FontWeight.w600,
                        //       //               color: textColor.withOpacity(0.5),
                        //       //             ),
                        //       //           ),
                        //       //         ],
                        //       //       ),
                        //       //     ],
                        //       //   ),
                        //       // ),
                        //       // SizedBox(
                        //       //   height: 10.h,
                        //       // ),
                        //
                        //       InkWell(
                        //         onTap: () {},
                        //         child: Row(
                        //           children: [
                        //             Icon(
                        //               Icons.paypal_rounded,
                        //               size: 32.h,
                        //               color: Colors.blueAccent,
                        //             ),
                        //             SizedBox(
                        //               width: 15.w,
                        //             ),
                        //             Row(
                        //               mainAxisAlignment:
                        //                   MainAxisAlignment.center,
                        //               children: [
                        //                 Icon(
                        //                   Icons.add,
                        //                   size: 23.h,
                        //                   color: textColor.withOpacity(0.5),
                        //                 ),
                        //                 SizedBox(
                        //                   width: 3.w,
                        //                 ),
                        //                 Text(
                        //                   'Use PayPal',
                        //                   style: TextStyle(
                        //                     fontSize: 16.sp,
                        //                     fontWeight: FontWeight.w600,
                        //                     color: textColor.withOpacity(0.5),
                        //                   ),
                        //                 ),
                        //               ],
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //       SizedBox(
                        //         height: 10.h,
                        //       ),
                        //       InkWell(
                        //         onTap: () {},
                        //         child: Row(
                        //           children: [
                        //             Icon(
                        //               Icons.delivery_dining_rounded,
                        //               size: 32.h,
                        //               color: textColor,
                        //             ),
                        //             SizedBox(
                        //               width: 15.w,
                        //             ),
                        //             Row(
                        //               mainAxisAlignment:
                        //                   MainAxisAlignment.center,
                        //               children: [
                        //                 Icon(
                        //                   Icons.add,
                        //                   size: 23.h,
                        //                   color: textColor.withOpacity(0.5),
                        //                 ),
                        //                 SizedBox(
                        //                   width: 3.w,
                        //                 ),
                        //                 Text(
                        //                   'Cash on Delivery',
                        //                   style: TextStyle(
                        //                     fontSize: 16.sp,
                        //                     fontWeight: FontWeight.w600,
                        //                     color: textColor.withOpacity(0.5),
                        //                   ),
                        //                 ),
                        //               ],
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //       SizedBox(
                        //         height: 10.h,
                        //       ),
                        //     ],
                        //   ),
                        // ),
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (state is ProductPaypalPayLoadingState)
                        const CircularProgressIndicator(color: primaryColor)
                      else
                        SizedBox(
                          height: 0.07.sh,
                          width: 0.9.sw,
                          child: Material(
                            borderRadius: BorderRadius.circular(17.r),
                            color: primaryColor,
                            elevation: 15,
                            shadowColor: primaryColor.withOpacity(0.5),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(17.r),
                              onTap: () async {
                                await ProductCubit.get(
                                  context,
                                ).paypal(val: widget.total);
                              },
                              child: Center(
                                child: Text(
                                  S.of(context).pay_now,
                                  style: TextStyle(
                                    height: 0.8,
                                    color: Colors.white,
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
}
