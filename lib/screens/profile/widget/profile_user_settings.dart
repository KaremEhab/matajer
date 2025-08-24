import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/profile/notifications.dart';
import 'package:matajer/screens/profile/orders.dart';
import 'package:matajer/screens/profile/wallet.dart';
import 'package:matajer/screens/settings/account_settings.dart';
import 'package:matajer/screens/settings/address.dart';
import 'package:matajer/screens/settings/change_email.dart';
import 'package:matajer/screens/settings/change_password.dart';
import 'package:matajer/screens/whatsApp/offers.dart';

class UserSettings extends StatelessWidget {
  const UserSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> userSettings = [
      {'title': S.of(context).orders, 'widget': const OrdersHistory()},
      {
        'title': S.of(context).offers,
        'widget': OffersPage(userId: isSeller ? currentShopModel!.shopId : uId),
      },
      {'title': S.of(context).my_wallet, 'widget': const Wallet()},
      {'title': S.of(context).notifications, 'widget': const Notifications()},
      {'title': S.of(context).change_email, 'widget': const ChangeEmail()},
      {
        'title': S.of(context).change_password,
        'widget': const ChangePassword(),
      },
      {'title': S.of(context).saved_addresses, 'widget': const SavedAddress()},
      {
        'title': S.of(context).account_settings,
        'widget': const AccountSettings(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).user_settings,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: greyColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              itemCount: userSettings.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final setting = userSettings[index];
                return _buildSettingTile(
                  context: context,
                  title: setting['title'],
                  destination: setting['widget'],
                  isFirst: index == 0,
                  isLast: index == userSettings.length - 1,
                );
              },
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Divider(thickness: 2, color: greyColor.withOpacity(0.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required String title,
    required Widget destination,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () => slideAnimation(
        context: context,
        destination: destination,
        rightSlide: true,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          15,
          isFirst ? 20 : 15,
          10,
          isLast ? 20 : 15,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(forwardIcon(), color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
