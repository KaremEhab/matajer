import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/seller/manage_shops.dart';

class ShopSettings extends StatefulWidget {
  const ShopSettings({super.key});

  @override
  State<ShopSettings> createState() => _ShopSettingsState();
}

class _ShopSettingsState extends State<ShopSettings> {
  // bool shopStatus = true;
  bool gulfDelivery = true;
  bool autoAcceptOrders = true;

  @override
  Widget build(BuildContext context) {
    final List<_AppSettingItem> settings = [
      _AppSettingItem(
        title: S.of(context).shop_status,
        subtitle: '',
        isToggleButton: true,
        toggleType: ToggleType.shopStatus,
      ),
      _AppSettingItem(
        title: S.of(context).gulf_delivery,
        subtitle: '',
        isToggleButton: true,
        toggleType: ToggleType.gulfDelivery,
      ),
      _AppSettingItem(
        title: S.of(context).manage_shop,
        subtitle: '',
        widget: ManageShopPage(shopModel: currentShopModel!),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).shop_settings,
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
              itemCount: settings.length,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Divider(thickness: 2, color: greyColor.withOpacity(0.2)),
              ),
              itemBuilder: (context, index) {
                final setting = settings[index];

                String getSubtitle() {
                  switch (setting.toggleType) {
                    case ToggleType.shopStatus:
                      return shopStatus ? 'Online' : 'Offline';
                    case ToggleType.gulfDelivery:
                      return gulfDelivery ? 'ON' : 'OFF';
                    default:
                      return setting.subtitle;
                  }
                }

                bool getValue() {
                  switch (setting.toggleType) {
                    case ToggleType.shopStatus:
                      return shopStatus;
                    case ToggleType.gulfDelivery:
                      return gulfDelivery;
                    default:
                      return false;
                  }
                }

                void toggleValue(bool value) {
                  setState(() {
                    switch (setting.toggleType) {
                      case ToggleType.shopStatus:
                        shopStatus = value;
                        CacheHelper.saveData(
                          key: 'shopStatus',
                          value: shopStatus,
                        );

                        // 🔴 If switched OFF → mark user & shop offline everywhere
                        final userId = currentUserModel.uId;
                        final shopId = currentShopModel!.shopId;

                        UserCubit.get(context).setActivityStatus(
                          userId: userId,
                          shopIdIfSeller: shopId,
                          statusValue: shopStatus
                              ? UserActivityStatus.online.name
                              : UserActivityStatus.offline.name,
                        );
                        log(
                          '🔴 Shop status turned OFF → setActivityStatus called',
                        );

                        break;

                      case ToggleType.gulfDelivery:
                        gulfDelivery = value;
                        break;

                      default:
                        break;
                    }
                  });
                }

                return ListTile(
                  contentPadding: EdgeInsets.fromLTRB(
                    15,
                    index == 0 ? 8 : 0,
                    10,
                    index == settings.length - 1 ? 8 : 0,
                  ),
                  onTap: setting.isToggleButton || setting.widget == null
                      ? null
                      : () => slideAnimation(
                          context: context,
                          destination: setting.widget!,
                          rightSlide: true,
                        ),
                  title: Text(
                    setting.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: setting.isToggleButton
                      ? Text(
                          getSubtitle(),
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : setting.subtitle.isNotEmpty
                      ? Text(
                          setting.subtitle,
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                  trailing: setting.isToggleButton
                      ? Switch.adaptive(
                          activeColor: primaryColor,
                          value: getValue(),
                          onChanged: toggleValue,
                        )
                      : Icon(forwardIcon(), color: Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum ToggleType { shopStatus, gulfDelivery, none }

class _AppSettingItem {
  final String title;
  final String subtitle;
  final Widget? widget;
  final bool isToggleButton;
  final ToggleType toggleType;

  const _AppSettingItem({
    required this.title,
    required this.subtitle,
    this.widget,
    this.isToggleButton = false,
    this.toggleType = ToggleType.none,
  });
}
