import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/cubit/notifications/notification_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/notification_model.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:matajer/screens/orders/order_details_screen.dart';
import 'package:matajer/screens/profile/order_details.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  void initState() {
    super.initState();
    NotificationCubit.instance.getNotifications(
      receiverId: isSeller ? currentShopModel!.shopId : uId,
      receiverType: isSeller ? 'shop' : 'user',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
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
              S.of(context).notifications,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: state is NotificationGetNotificationsLoadingState
              ? const Center(child: CircularProgressIndicator())
              : NotificationCubit.instance.notifications.isEmpty
              ? Center(
                  child: Text(
                    S.of(context).no_notifications_yet,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: greyColor,
                    ),
                  ),
                )
              : SafeArea(
                  child: ListView.builder(
                    itemCount: NotificationCubit.instance.notifications.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      NotificationModel notification =
                          NotificationCubit.instance.notifications[index];

                      return Material(
                        color: notification.isRead
                            ? transparentColor
                            : secondaryColor,
                        child: InkWell(
                          onTap: () async {
                            if (notification.notificationType ==
                                NotificationTypes.newOrder) {
                              try {
                                // Extract payload
                                final dynamic orderRaw =
                                    notification.payload['orderModel'];

                                // Decode if it's a JSON string
                                final Map<String, dynamic> orderMap =
                                    orderRaw is String
                                    ? Map<String, dynamic>.from(
                                        jsonDecode(orderRaw),
                                      )
                                    : Map<String, dynamic>.from(orderRaw);

                                // Build model instances
                                final OrderModel orderModel =
                                    OrderModel.fromJson(
                                      orderMap,
                                      orderMap['id'],
                                    );

                                navigateTo(
                                  context: context,
                                  screen: OrderDetailsScreen(order: orderModel),
                                );
                              } catch (e, st) {
                                print(
                                  '❌ Error handling newOrder notification: $e',
                                );
                                print(st);
                              }
                            } else if (notification.notificationType ==
                                NotificationTypes.newProduct) {
                              try {
                                // Extract payload
                                final dynamic productRaw =
                                    notification.payload['productModel'];
                                final dynamic shopRaw =
                                    notification.payload['shopModel'];

                                // Decode if it's a JSON string
                                final Map<String, dynamic> productMap =
                                    productRaw is String
                                    ? Map<String, dynamic>.from(
                                        jsonDecode(productRaw),
                                      )
                                    : Map<String, dynamic>.from(productRaw);

                                final Map<String, dynamic> shopMap =
                                    shopRaw is String
                                    ? Map<String, dynamic>.from(
                                        jsonDecode(shopRaw),
                                      )
                                    : Map<String, dynamic>.from(shopRaw);

                                // Build model instances
                                final ProductModel productModel =
                                    ProductModel.fromJson(productMap);
                                final ShopModel shopModel = ShopModel.fromJson(
                                  shopMap,
                                );

                                navigateTo(
                                  context: context,
                                  screen: ProductDetailsScreen(
                                    productModel: productModel,
                                    shopModel: shopModel,
                                  ),
                                );
                              } catch (e, st) {
                                print(
                                  '❌ Error handling newProduct notification: $e',
                                );
                                print(st);
                              }
                            } else if (notification.notificationType ==
                                NotificationTypes.orderStatus) {
                              try {
                                // Extract payload
                                final dynamic orderRaw =
                                    notification.payload['orderModel'];

                                // Decode if it's a JSON string
                                final Map<String, dynamic> orderMap =
                                    orderRaw is String
                                    ? Map<String, dynamic>.from(
                                        jsonDecode(orderRaw),
                                      )
                                    : Map<String, dynamic>.from(orderRaw);

                                // Build model instances
                                final OrderModel orderModel =
                                    OrderModel.fromJson(
                                      orderMap,
                                      orderMap['id'],
                                    );

                                navigateTo(
                                  context: context,
                                  screen: OrderDetails(order: orderModel),
                                );
                              } catch (e, st) {
                                print(
                                  '❌ Error handling newOrder notification: $e',
                                );
                                print(st);
                              }
                            }
                            await NotificationCubit.instance
                                .markNotificationAsRead(
                                  receiverId: isSeller
                                      ? currentShopModel!.shopId
                                      : uId,
                                  receiverType: isSeller ? 'shop' : 'user',
                                  notificationId: notification.id,
                                  localNotifications:
                                      NotificationCubit.instance.notifications,
                                  updateLocalList: (updatedList) {
                                    setState(() {
                                      NotificationCubit.instance.notifications =
                                          updatedList;
                                    });
                                  },
                                );
                            setState(() {});
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 7),
                            margin: EdgeInsets.symmetric(vertical: 13),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                notification.payload['senderProfile'] == null
                                    ? CircleAvatar(
                                        backgroundColor: greyColor.withOpacity(
                                          0.2,
                                        ),
                                        radius: 35,

                                        child: Material(
                                          shape: CircleBorder(),
                                          color: lightGreyColor.withOpacity(
                                            0.4,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              IconlyLight.image,
                                              size: 35,
                                            ),
                                          ),
                                        ),
                                      )
                                    : notification.notificationType ==
                                              NotificationTypes.newOrder ||
                                          notification.notificationType ==
                                              NotificationTypes.newProduct
                                    ? Container(
                                        padding: EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: senderColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: CircleAvatar(
                                            radius: 30,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(200),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    notification
                                                            .notificationType ==
                                                        NotificationTypes
                                                            .newOrder
                                                    ? notification
                                                          .payload['senderProfile']
                                                    : notification
                                                          .payload['shopModel']['shopLogoUrl'],
                                                progressIndicatorBuilder:
                                                    (context, url, progress) =>
                                                        shimmerPlaceholder(
                                                          height: 150,
                                                          width: 150,
                                                          radius: 200.r,
                                                        ),
                                                height: 150,
                                                width: 150,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : notification.notificationType ==
                                          NotificationTypes.orderStatus
                                    ? Container(
                                        padding: EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: getStatusBackgroundColor(
                                            OrderStatusParser.fromString(
                                              notification
                                                  .payload['orderStatus'],
                                            )!,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: getStatusTextColor(
                                              OrderStatusParser.fromString(
                                                notification
                                                    .payload['orderStatus'],
                                              )!,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Material(
                                            color: Colors.white,
                                            shape: CircleBorder(),
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  getStatusBackgroundColor(
                                                    OrderStatusParser.fromString(
                                                      notification
                                                          .payload['orderStatus'],
                                                    )!,
                                                  ),
                                              radius: 30,
                                              child: Icon(
                                                Icons.checklist_rounded,
                                                color: getStatusTextColor(
                                                  OrderStatusParser.fromString(
                                                    notification
                                                        .payload['orderStatus'],
                                                  )!,
                                                ),
                                                size: 25,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: greyColor.withOpacity(
                                          0.2,
                                        ),
                                        radius: 35,
                                        child: SvgPicture.asset(
                                          'images/matajr_logo.svg',
                                          color: textColor,
                                          height: 25,
                                        ),
                                      ),
                                SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          height: 1.2,
                                          fontSize: 17,
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              notification.notificationType ==
                                                          NotificationTypes
                                                              .newOrder ||
                                                      notification
                                                              .notificationType ==
                                                          NotificationTypes
                                                              .orderStatus
                                                  ? "See it now"
                                                  : "Place order",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                decoration:
                                                    TextDecoration.underline,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                            Text(
                                              formatNotificationDate(
                                                notification.createdAt,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
