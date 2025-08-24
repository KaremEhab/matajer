import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/seller/drafts.dart';
import 'package:matajer/screens/seller/manage_products.dart';

class ProductSettings extends StatefulWidget {
  const ProductSettings({super.key, required this.shopModel});

  final ShopModel shopModel;

  @override
  State<ProductSettings> createState() => _ProductSettingsState();
}

class _ProductSettingsState extends State<ProductSettings> {
  bool autoAcceptOrders = true;

  @override
  Widget build(BuildContext context) {
    final List<_AppSettingItem> settings = [
      _AppSettingItem(
        title: S.of(context).draft_products,
        subtitle: S.of(context).draft_products_tip,
        widget: DraftsPage(shopModel: widget.shopModel),
      ),
      _AppSettingItem(
        title: S.of(context).manage_products,
        subtitle: S.of(context).manage_products_tip,
        widget: ManageProductsPage(shopModel: widget.shopModel),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).product_settings,
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
                final isAutoToggle = setting.isAutoAcceptOrdersToggle;

                return ListTile(
                  contentPadding: EdgeInsets.fromLTRB(
                    15,
                    8,
                    10,
                    index == settings.length - 1 ? 8 : 0,
                  ),
                  onTap: isAutoToggle || setting.widget == null
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
                  subtitle: isAutoToggle
                      ? Text(
                          autoAcceptOrders ? "ON" : "OFF",
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          setting.subtitle,
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  trailing: isAutoToggle
                      ? Switch.adaptive(
                          activeColor: primaryColor,
                          value: autoAcceptOrders,
                          onChanged: (value) {
                            setState(() => autoAcceptOrders = value);
                          },
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

class _AppSettingItem {
  final String title;
  final String subtitle;
  final Widget? widget;
  final bool isAutoAcceptOrdersToggle;

  const _AppSettingItem({
    required this.title,
    required this.subtitle,
    this.widget,
    this.isAutoAcceptOrdersToggle = false,
  });
}
