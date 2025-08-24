import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/cart_product_item_model.dart';
import 'package:matajer/screens/my_cart/basket.dart';
import 'package:matajer/cubit/product/product_cubit.dart';

class OffersPage extends StatefulWidget {
  final String userId;

  const OffersPage({super.key, required this.userId});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late final Stream<QuerySnapshot> _offersStream;
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _offersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('offers')
        .orderBy('timestamp', descending: true)
        .snapshots();

    // Optional: If you want to do something with incoming data
    _subscription = _offersStream.listen((snapshot) {
      // handle snapshot updates if needed
    });
  }

  @override
  void dispose() {
    // Dispose the subscription to avoid memory leaks
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        title: const Text("My Offers"),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _offersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No offers yet"));
          }

          final offers = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final data = offers[index].data() as Map<String, dynamic>;
              final product = ProductModel.fromJson(data['product']);
              final newPrice = data['newPrice'] as num;
              final description = data['description'] as String;
              final expireDate = data['expireDate'] != null
                  ? data['expireDate'] as Timestamp
                  : null;
              final timestamp = data['timestamp'] as Timestamp;
              final senderId = data['senderId'] as String;
              final isMe = senderId == currentUserModel.uId;

              return SpecialOfferProductCard(
                product: product,
                newPrice: newPrice,
                description: description,
                expireDate: expireDate,
                timestamp: timestamp,
                isMe: isMe,
                senderId: senderId,
              );
            },
          );
        },
      ),
    );
  }
}

class SpecialOfferProductCard extends StatelessWidget {
  final ProductModel product;
  final num newPrice;
  final String description;
  final Timestamp? expireDate;
  final Timestamp timestamp;
  final bool isMe;
  final String senderId;

  const SpecialOfferProductCard({
    super.key,
    required this.product,
    required this.newPrice,
    required this.description,
    required this.expireDate,
    required this.timestamp,
    required this.isMe,
    required this.senderId,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 7.w),
              padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: textColor.withOpacity(0.1),
                  width: 2.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat("MMMM d").format(timestamp.toDate()),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            DateFormat("hh:mma").format(timestamp.toDate()),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.more_horiz, size: 30),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: textColor.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(product.shopLogo),
                          radius: 25.r,
                          onBackgroundImageError: (_, __) =>
                              const Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                Text(
                                  product.discount < 0
                                      ? 'AED ${formatNumberWithCommas(product.price.toDouble())}'
                                      : 'AED ${formatNumberWithCommas(product.price - product.price * (product.discount / 100))}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 1.5,
                                  ),
                                ),
                                Text(
                                  'AED ${formatNumberWithCommas(newPrice.toDouble())}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (expireDate != null &&
                      Timestamp.now().toDate().isAfter(expireDate!.toDate()))
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 17.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'OFFER EXPIRED',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 10.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 17,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (!isMe &&
                      (expireDate == null ||
                          Timestamp.now().toDate().isBefore(
                            expireDate!.toDate(),
                          )))
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {},
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 17.h),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: const Center(
                                child: Text(
                                  "DECLINE",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (ProductCubit.get(
                                context,
                              ).cartProducts.isNotEmpty) {
                                await ProductCubit.get(context).clearCart();
                              }
                              await ProductCubit.get(context).addProductToCart(
                                product: CartProductItemModel(
                                  product: product,
                                  quantity: 1,
                                  isOffer: true,
                                ),
                              );
                              navigateReplacement(
                                context: context,
                                screen: Basket(shopId: product.shopId),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 17.h),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Center(
                                child: Text(
                                  "ACCEPT OFFER",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.sp,
                                  ),
                                ),
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
    );
  }
}
