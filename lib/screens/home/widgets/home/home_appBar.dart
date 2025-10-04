import 'package:flutter/cupertino.dart';
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
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/favourites/fav_shops.dart';
import 'package:matajer/screens/maps/map_picker.dart';
import 'package:matajer/screens/profile/notifications.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      forceMaterialTransparency: true,
      // systemOverlayStyle: const SystemUiOverlayStyle(
      //   statusBarColor: Colors.white,
      //   systemNavigationBarColor: Colors.transparent,
      //   systemNavigationBarDividerColor: Colors.red
      // ),
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 7),
        child: Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIconButton(
              context,
              icon: IconlyLight.notification,
              onTap: () => slideAnimation(
                context: context,
                destination: const Notifications(),
              ),
            ),
            Expanded(child: buildAddressMenu(context, 0)),
            _buildIconButton(
              context,
              icon: CupertinoIcons.heart,
              onTap: () => slideAnimation(
                context: context,
                destination: const Favourites(),
                rightSlide: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: lightGreyColor.withOpacity(0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: textColor, size: 22),
        ),
      ),
    );
  }
}

Widget buildAddressMenu(BuildContext context, double xAxis) {
  return BlocSelector<ProductCubit, ProductState, String>(
    selector: (_) => currentUserModel.currentAddress?['name'] ?? '',
    builder: (context, currentAddress) {
      final addressText = SizedBox(
        width: 0.55.sw,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              S.of(context).deliveries_made_to,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              currentAddress.isNotEmpty
                  ? currentAddress
                  : S.of(context).department_city_country,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ],
        ),
      );

      final arrowIcon = Container(
        decoration: BoxDecoration(
          color: lightGreyColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(7.r),
        ),
        padding: const EdgeInsets.all(2),
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: textColor,
          size: 20,
        ),
      );

      if (isGuest) {
        // Guest view
        return InkWell(
          onTap: () {
            slideAnimation(context: context, destination: const SignUp());
          },
          child: Column(
            children: [
              Text(
                S.of(context).guest,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              Text(
                S.of(context).guest_home_tip,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }

      // Interactive address menu
      return PopupMenuButton<Map<String, dynamic>>(
        tooltip: S.of(context).address_menu,
        offset: Offset(xAxis, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        onSelected: (value) async {
          final cubit = ProductCubit.get(context);
          if (value['type'] == 'add_new') {
            final selected = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const MapPickerScreen()),
            );
            if (selected != null && selected.isNotEmpty) {
              await cubit.addNewAddress(name: "", address: selected);
            }
          } else {
            await cubit.setCurrentAddress(addressObj: value);
          }
        },
        itemBuilder: (context) => buildAddressItems(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [addressText, const SizedBox(width: 5), arrowIcon],
        ),
      );
    },
  );
}

List<PopupMenuEntry<Map<String, dynamic>>> buildAddressItems(
  BuildContext context,
) {
  final addresses = currentUserModel.addresses;

  return [
    PopupMenuItem<Map<String, dynamic>>(
      value: {'type': 'add_new'},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            S.of(context).plus_add_new_address,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Icon(Icons.add_location_alt_outlined, size: 20, color: primaryColor),
        ],
      ),
    ),
    if (addresses.isNotEmpty)
      PopupMenuDivider(thickness: 1.5, color: Colors.grey.withOpacity(0.3)),

    ...addresses.map(
      (address) => PopupMenuItem<Map<String, dynamic>>(
        value: address,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: 0.8.sw,
          child: Row(
            children: [
              Radio<Map<String, dynamic>>(
                value: address,
                activeColor: primaryColor,
                groupValue: currentUserModel.currentAddress,
                onChanged: (val) {
                  Navigator.pop(context, val);
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 5),
                  child: Text(
                    "${address['name'] ?? ''} - ${address['address'] ?? ''}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color:
                          currentUserModel.currentAddress != null &&
                              currentUserModel.currentAddress!['address'] ==
                                  address['address']
                          ? primaryColor
                          : textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ];
}
