import 'dart:convert';
import 'dart:developer';

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
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/cart_product_item_model.dart';
import 'package:matajer/models/notification_model.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:matajer/screens/orders/order_details_screen.dart';
import 'package:matajer/screens/profile/order_details.dart';
import 'package:matajer/widgets/order_card.dart';

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
          appBar: _buildAppBar(context),
          body: _buildBody(context, state),
        );
      },
    );
  }

  // ----------------- UI BUILDERS -----------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      forceMaterialTransparency: true,
      leadingWidth: 53,
      leading: _buildBackButton(context),
      title: Text(
        S.of(context).notifications,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
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
          onTap: () => Navigator.pop(context),
          child: Center(child: Icon(backIcon(), color: textColor, size: 26)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state is NotificationGetNotificationsLoadingState) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifications = NotificationCubit.instance.notifications;
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          S.of(context).no_notifications_yet,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: greyColor,
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView.builder(
        itemCount: notifications.length,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return _buildNotificationTile(notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Material(
      color: notification.isRead ? transparentColor : secondaryColor,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          margin: const EdgeInsets.symmetric(vertical: 13),
          child: Column(
            spacing: 5,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNotificationAvatar(notification),
                  const SizedBox(width: 10),
                  _buildNotificationContent(notification),
                ],
              ),
              if (notification.notificationType == NotificationTypes.newProduct)
                NotificationProductCard(
                  productId: notification.payload['productId'],
                ),

              if (notification.notificationType ==
                      NotificationTypes.orderStatus ||
                  notification.notificationType == NotificationTypes.newProduct)
                SizedBox(
                  height: 50,
                  child: Builder(
                    builder: (context) {
                      NotificationTypes type = notification.notificationType;
                      OrderModel? orderModel;
                      ProductModel? productModel;
                      if (notification.payload['orderModel'] != null) {
                        orderModel = _parseOrder(
                          notification.payload['orderModel'],
                        );
                      }
                      if (notification.payload['productModel'] != null) {
                        productModel = _parseProduct(
                          notification.payload['productModel'],
                        );
                      }

                      if (type == NotificationTypes.orderStatus &&
                          notification.payload['orderStatus'] == 4) {
                        return Row(
                          children: [
                            Expanded(
                              child: buildReOrderButton(context, orderModel!),
                            ),
                            Expanded(
                              child: buildRateButton(context, orderModel.id),
                            ),
                          ],
                        );
                      }

                      if (type == NotificationTypes.newProduct) {
                        return Row(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Material(
                                borderRadius: BorderRadius.circular(10),
                                color: primaryColor,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(17.r),
                                  onTap: () async {
                                    await ProductCubit.get(
                                      context,
                                    ).getCartProducts();
                                    if (!context.mounted) return;

                                    bool proceed = true;

                                    // Check if cart has products from another shop
                                    if (ProductCubit.get(
                                          context,
                                        ).cartProducts.isNotEmpty &&
                                        ProductCubit.get(context)
                                                .cartProducts
                                                .first
                                                .product
                                                .shopId !=
                                            productModel!.shopId) {
                                      // Await dialog result
                                      proceed =
                                          await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                S.of(context).different_seller,
                                              ),
                                              content: Text(
                                                S.of(context).clear_cart_prompt,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text(
                                                    S.of(context).cancel,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    await ProductCubit.get(
                                                      context,
                                                    ).clearCart();
                                                    if (!context.mounted)
                                                      return;
                                                    Navigator.pop(
                                                      context,
                                                      true,
                                                    ); // return true = proceed
                                                  },
                                                  child: Text(
                                                    S.of(context).clear_cart,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false; // default false if dialog dismissed
                                    }

                                    if (!proceed) return;

                                    // Helper method to get default selected specifications (first of each)
                                    List<Map<String, String>>
                                    _getDefaultSelectedSpecifications(
                                      ProductModel productModel,
                                    ) {
                                      List<Map<String, String>> selectedSpecs =
                                          [];

                                      for (var spec
                                          in productModel.specifications) {
                                        if (spec.subTitles.isNotEmpty) {
                                          selectedSpecs.add({
                                            'title': spec.title,
                                            'value': spec
                                                .subTitles
                                                .first
                                                .title, // Always select the first subTitle
                                          });
                                        }
                                      }

                                      return selectedSpecs;
                                    }

                                    final cartProduct = CartProductItemModel(
                                      product: productModel!,
                                      quantity: 1,
                                      selectedSpecifications:
                                          _getDefaultSelectedSpecifications(
                                            productModel,
                                          ),
                                    );

                                    // Add products to cart
                                    await Future.wait([
                                      ProductCubit.get(
                                        context,
                                      ).addProductToCart(product: cartProduct),
                                    ]);

                                    if (!context.mounted) return;

                                    // Show success snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          S.of(context).products_added_cart,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: primaryColor,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Center(
                                    child: Text(
                                      S.current.place_order,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Material(
                                borderRadius: BorderRadius.circular(10),
                                color: primaryColor.withOpacity(0.2),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(17.r),
                                  child: Center(
                                    child: Text(
                                      S.current.view_details,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return SizedBox.shrink();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationAvatar(NotificationModel notification) {
    final type = notification.notificationType;

    if (type == NotificationTypes.newOrder ||
        type == NotificationTypes.newProduct) {
      final imageUrl = type == NotificationTypes.newOrder
          ? notification.payload['senderProfile']
          : notification.payload['shopModel']['shopLogoUrl'];

      return _buildCircleImageAvatar(imageUrl);
    }

    if (type == NotificationTypes.orderStatus) {
      final rawStatus = notification.payload['orderStatus'];

      late OrderStatus status;
      if (rawStatus is int) {
        status = OrderStatus.values[rawStatus];
      } else if (rawStatus is String) {
        // in case some old notifications still have string
        final parsed = int.tryParse(rawStatus);
        if (parsed != null &&
            parsed >= 0 &&
            parsed < OrderStatus.values.length) {
          status = OrderStatus.values[parsed];
        } else {
          status = OrderStatus.pending; // fallback
        }
      } else {
        status = OrderStatus.pending;
      }

      return _buildOrderStatusAvatar(status);
    }

    return CircleAvatar(
      backgroundColor: greyColor.withOpacity(0.2),
      radius: 35,
      child: SvgPicture.asset(
        'images/matajr_logo.svg',
        color: textColor,
        height: 25,
      ),
    );
  }

  Widget _buildNotificationContent(NotificationModel notification) {
    final actionText =
        (notification.notificationType == NotificationTypes.newOrder)
        ? S.current.see_it_now
        : notification.notificationType == NotificationTypes.orderStatus
        ? S.current.track_your_order
        : S.current.place_order;

    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                Text(
                  formatNotificationDate(notification.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- AVATAR HELPERS -----------------

  Widget _buildCircleImageAvatar(String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: senderColor,
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(imageUrl),
        ),
      ),
    );
  }

  Widget _buildOrderStatusAvatar(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: getStatusBackgroundColor(status),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: getStatusBackgroundColor(status),
        child: Icon(
          Icons.checklist_rounded,
          color: getStatusTextColor(status),
          size: 25,
        ),
      ),
    );
  }

  // ----------------- HANDLERS -----------------

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    try {
      switch (notification.notificationType) {
        case NotificationTypes.newOrder:
          final order = _parseOrder(notification.payload['orderModel']);
          navigateTo(
            context: context,
            screen: OrderDetailsScreen(order: order),
          );
          break;

        case NotificationTypes.newProduct:
          final product = _parseProduct(notification.payload['productModel']);
          final shop = _parseShop(notification.payload['shopModel']);
          navigateTo(
            context: context,
            screen: ProductDetailsScreen(
              productModel: product,
              fromNotif: true,
              shopModel: shop,
            ),
          );
          break;

        case NotificationTypes.orderStatus:
          final order = _parseOrder(notification.payload['orderModel']);
          final rawStatus = notification.payload['orderStatus'];

          late OrderStatus status;
          if (rawStatus is int) {
            status = OrderStatus.values[rawStatus];
          } else if (rawStatus is String) {
            // in case some old notifications still have string
            final parsed = int.tryParse(rawStatus);
            if (parsed != null &&
                parsed >= 0 &&
                parsed < OrderStatus.values.length) {
              status = OrderStatus.values[parsed];
            } else {
              status = OrderStatus.pending; // fallback
            }
          } else {
            status = OrderStatus.pending;
          }
          log("ORRRDDDEEEEERRRR ${status.name}");
          navigateTo(
            context: context,
            screen: OrderDetails(order: order, orderStatus: status),
          );
          break;

        default:
          break;
      }
    } catch (e, st) {
      debugPrint("❌ Error handling notification: $e\n$st");
    }

    await NotificationCubit.instance.markNotificationAsRead(
      receiverId: isSeller ? currentShopModel!.shopId : uId,
      receiverType: isSeller ? 'shop' : 'user',
      notificationId: notification.id,
      localNotifications: NotificationCubit.instance.notifications,
      updateLocalList: (updatedList) {
        setState(() => NotificationCubit.instance.notifications = updatedList);
      },
    );

    setState(() {});
  }

  // ----------------- PARSERS -----------------

  OrderModel _parseOrder(dynamic raw) {
    final map = _ensureMap(raw);
    return OrderModel.fromJson(map, map['id']);
  }

  ProductModel _parseProduct(dynamic raw) {
    return ProductModel.fromJson(_ensureMap(raw));
  }

  ShopModel _parseShop(dynamic raw) {
    return ShopModel.fromJson(_ensureMap(raw));
  }

  Map<String, dynamic> _ensureMap(dynamic raw) {
    return raw is String ? jsonDecode(raw) : Map<String, dynamic>.from(raw);
  }
}

class NotificationProductCard extends StatefulWidget {
  final String productId;
  const NotificationProductCard({super.key, required this.productId});

  @override
  State<NotificationProductCard> createState() =>
      _NotificationProductCardState();
}

class _NotificationProductCardState extends State<NotificationProductCard> {
  late Future<ProductModel?> _productFuture;

  @override
  void initState() {
    super.initState();
    // fetch once only
    _productFuture = ProductCubit.get(
      context,
    ).getProductById(productId: widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductModel?>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return shimmerPlaceholder(
            height: 150,
            width: double.infinity,
            radius: 10,
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Chip(
              side: BorderSide.none,
              backgroundColor: Colors.red.withOpacity(0.07),
              label: const Text(
                "This product has been deleted",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final product = snapshot.data!;
        final images = product.images;

        if (images.isEmpty || images.first.isEmpty) {
          return Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: formFieldColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(IconlyLight.image, size: 40, color: Colors.grey),
            ),
          );
        }

        return Container(
          height: 150,
          width: double.infinity,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: CachedNetworkImage(
            imageUrl: images.first,
            errorWidget: (context, error, stackTrace) {
              return const Center(
                child: Icon(IconlyLight.image, size: 40, color: Colors.grey),
              );
            },
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                Center(
                  child: shimmerPlaceholder(
                    height: 150,
                    width: double.infinity,
                    radius: 10,
                  ),
                ),
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
