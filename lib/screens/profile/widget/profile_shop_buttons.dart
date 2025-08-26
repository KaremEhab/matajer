import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/auth/login.dart';
import 'package:matajer/screens/auth/register_as_seller.dart';
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/layout.dart';

class ShopManagement extends StatelessWidget {
  const ShopManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: !isGuest
            ? [
                _buildNewShopTile(context),
                if (currentUserModel.shops.isNotEmpty)
                  _buildSwitchShopTile(context),
              ]
            : [_buildLogInTile(context), _buildSignUpTile(context)],
      ),
    );
  }

  Widget _buildNewShopTile(BuildContext context) {
    final hasShops = currentUserModel.shops.isNotEmpty;
    return ListTile(
      onTap: () =>
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterAsSeller()),
          ).then((value) {
            UserCubit.get(context).markShouldRefreshSellers();
          }),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      tileColor: hasShops ? formFieldColor : primaryColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(
            "images/shop-icon-outlined.svg",
            color: hasShops ? textColor : Colors.white,
            height: 28,
            width: 28,
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: -8,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: hasShops ? formFieldColor : primaryColor,
              child: Text(
                "+",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: hasShops ? textColor : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        hasShops
            ? S.of(context).add_new_matjar
            : S.of(context).establish_first_shop,
        style: TextStyle(
          color: hasShops ? textColor : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        hasShops
            ? S.of(context).expand_business
            : S.of(context).setup_first_shop,
        style: TextStyle(
          color: hasShops ? textColor.withOpacity(0.5) : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        forwardIcon(),
        color: hasShops ? textColor.withOpacity(0.5) : Colors.white,
      ),
    );
  }

  Widget _buildLogInTile(BuildContext context) {
    return ListTile(
      onTap: () => navigateTo(context: context, screen: Login()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      tileColor: secondaryColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      leading: Icon(IconlyLight.login, color: primaryColor, size: 28),
      title: Text(
        S.of(context).sign_in,
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(forwardIcon(), color: primaryColor.withOpacity(0.7)),
    );
  }

  Widget _buildSignUpTile(BuildContext context) {
    return ListTile(
      onTap: () => navigateTo(context: context, screen: SignUp()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      tileColor: primaryColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      leading: Icon(IconlyLight.login, color: Colors.white, size: 28),
      title: Text(
        S.of(context).create_an_account,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(forwardIcon(), color: Colors.white.withOpacity(0.7)),
    );
  }

  Widget _buildSwitchShopTile(BuildContext context) {
    return ListTile(
      onTap: () => handleSwitchTap(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      tileColor: secondaryColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      leading: SvgPicture.asset(
        'images/switch-shops.svg',
        height: 28,
        width: 28,
      ),
      title: Text(
        isSeller ? S.of(context).switch_to_buyer : S.of(context).switch_to_shop,
        style: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        S.of(context).switch_accounts_tip,
        style: TextStyle(
          color: primaryColor.withOpacity(0.7),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: !isSeller
          ? StreamBuilder<int>(
              stream: ChatsCubit.instance.getTotalUnseenMessagesCount(uId),
              builder: (context, chatSnapshot) {
                final chatCount = chatSnapshot.data ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('sellerId', isEqualTo: uId)
                      .where(
                        'orderStatus',
                        whereIn: [
                          OrderStatus.pending.index,
                          OrderStatus.accepted.index,
                          OrderStatus.shipped.index,
                          // add any other non-delivered statuses
                        ],
                      )
                      .snapshots(),
                  builder: (context, orderSnapshot) {
                    int totalProducts = 0;

                    if (orderSnapshot.hasData) {
                      for (var doc in orderSnapshot.data!.docs) {
                        final products =
                            doc['products'] as List<dynamic>? ?? [];
                        totalProducts += products.length;
                      }
                    }

                    final totalCount = totalProducts + chatCount;

                    if (totalCount > 0) {
                      return CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 12,
                        child: Text(
                          totalCount > 99 ? '+99' : '$totalCount',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    return Icon(
                      forwardIcon(),
                      color: primaryColor.withOpacity(0.7),
                    );
                  },
                );
              },
            )
          : Icon(forwardIcon(), color: primaryColor.withOpacity(0.7)),
    );
  }
}

Widget buildShopTile(BuildContext context, String shopId) {
  final isCurrentShop =
      currentShopModel != null && currentShopModel!.shopId == shopId;

  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('shops').doc(shopId).get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return shimmerPlaceholder(height: 80, width: double.infinity);
      }

      if (!snapshot.data!.exists) {
        return const SizedBox.shrink(); // skip if shop not found
      }

      final shopData = snapshot.data!.data() as Map<String, dynamic>;
      final shopModel = ShopModel.fromJson(shopData);

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: isCurrentShop ? secondaryColor : Colors.grey[100],
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: CachedNetworkImage(
            imageUrl: shopModel.shopLogoUrl.isNotEmpty
                ? shopModel.shopLogoUrl
                : currentUserModel.profilePicture!,
            progressIndicatorBuilder: (_, __, ___) =>
                shimmerPlaceholder(height: 60, width: 60, radius: 100),
            height: 60,
            width: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shopModel.shopName,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isCurrentShop ? primaryColor : textColor,
              ),
            ),
            Text(
              '${S.of(context).category}: ${shopModel.shopCategory}',
              style: TextStyle(color: isCurrentShop ? primaryColor : textColor),
            ),
          ],
        ),
        trailing: StreamBuilder<int>(
          stream: ChatsCubit.instance.getTotalUnseenMessagesCount(uId),
          builder: (context, chatSnapshot) {
            final chatCount = chatSnapshot.data ?? 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('shopId', isEqualTo: shopId)
                  .where(
                    'orderStatus',
                    whereIn: [
                      OrderStatus.pending.index,
                      OrderStatus.accepted.index,
                      OrderStatus.shipped.index,
                    ],
                  )
                  .snapshots(),
              builder: (context, orderSnapshot) {
                int totalProducts = 0;
                if (orderSnapshot.hasData) {
                  for (var doc in orderSnapshot.data!.docs) {
                    final products = doc['products'] as List<dynamic>? ?? [];
                    totalProducts += products.length;
                  }
                }

                final totalCount = totalProducts + chatCount;

                if (totalCount > 0) {
                  return CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 12,
                    child: Text(
                      totalCount > 99 ? '+99' : '$totalCount',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  );
                }

                return Icon(forwardIcon(), color: textColor.withOpacity(0.7));
              },
            );
          },
        ),
        onTap: () async {
          await UserCubit.get(context).getShopById(shopId);
          Navigator.pop(context);
          isSeller = true;
          navigateAndFinish(
            context: context,
            screen: const Layout(getUserData: false),
          );
        },
      );
    },
  );
}

Future<void> showShopSelectionSheet(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: currentUserModel.shops.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final shop = currentUserModel.shops[index];
          final shopId = shop['id'];
          return buildShopTile(context, shopId);
        },
      ),
    ),
  );
}

Future<void> handleSwitchTap(BuildContext context) async {
  if (!isSeller) {
    if (!currentUserModel.hasShop) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RegisterAsSeller()),
      ).then((value) {
        UserCubit.get(context).markShouldRefreshSellers();
      });
    } else if (currentUserModel.shops.length > 1) {
      await showShopSelectionSheet(context);
    } else {
      await UserCubit.get(context).getShopById(currentUserModel.shops[0]['id']);
      isSeller = true;
      navigateAndFinish(
        context: context,
        screen: const Layout(getUserData: false),
      );
    }
  } else {
    isSeller = false;
    navigateAndFinish(
      context: context,
      screen: const Layout(getUserData: true),
    );
  }
}
