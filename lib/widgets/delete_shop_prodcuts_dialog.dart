import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/main.dart';
import 'package:matajer/models/shop_model.dart';

class DeleteShopAndAllProductsDialog {
  static Future<void> show({
    required BuildContext context,
    required ShopModel shopModel,
    required String currentUserId,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            S.of(context).are_you_sure,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        content: Column(
          spacing: 5,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.of(context).clear_or_delete_shop,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            // Row with two options: delete products OR delete shop
            Row(
              spacing: 5,
              children: [
                // 🧹 Delete Products Only
                if(ProductCubit.get(context).products.isNotEmpty)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // close loading{
                      await ProductCubit.get(
                        context,
                      ).deleteAllProductsAndRefreshUI(shopModel: shopModel);

                      await ProductCubit.get(context).getSellers(shopType: '');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).products_deleted)),
                      );
                    },
                    child: Text(S.of(context).products),
                  ),
                ),

                // 🏪 Delete Shop
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      final dialogContext = context; // dialog context
                      final cubitContext =
                          navigatorKey.currentContext ?? context; // app context

                      final userCubit = UserCubit.get(cubitContext);
                      final productCubit = ProductCubit.get(cubitContext);

                      Navigator.pop(dialogContext); // close dialog first

                      await userCubit.deleteShop(
                        context: cubitContext,
                        shopModel: shopModel,
                        userId: currentUserId,
                        onShopDeleted: () async {
                          await productCubit.getSellers(shopType: '');
                        },
                      );

                      await userCubit.getUserData();
                      await productCubit.getSellers(shopType: '');

                      if (cubitContext.mounted) {
                        ScaffoldMessenger.of(cubitContext).showSnackBar(
                          SnackBar(
                            content: Text(S.of(cubitContext).shop_deleted),
                          ),
                        );
                      }
                    },
                    child: Text(S.of(context).shop),
                  ),
                ),
              ],
            ),

            // ❌ Cancel button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  S.of(context).cancel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
