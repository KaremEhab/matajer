import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/chat/order_offer.dart';
import 'package:matajer/screens/home/categories/shop_products_card.dart';

import 'constants/colors.dart';
import 'constants/vars.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    super.key,
    required this.shopModel,
    required this.receiverId,
    required this.chatId,
  });

  final ShopModel shopModel;
  final String chatId, receiverId;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<String> selectedProductIds = [];

  @override
  void initState() {
    super.initState();
    ProductCubit.get(context).getProducts(
      sellerId: currentShopModel!.sellerId,
      sellerCategory: currentShopModel!.shopCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            leadingWidth: 53,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(7, 6, 0, 6),
              child: Material(
                color: lightGreyColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color: textColor,
                      size: 27,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              S.of(context).choose_a_product,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: ProductCubit.get(context).products.length,
                    itemBuilder: (context, index) {
                      final productModel = ProductCubit.get(
                        context,
                      ).products[index];
                      final isSelected = selectedProductIds.contains(
                        productModel.id,
                      );

                      return ShopProductsCard(
                        productModel: productModel,
                        isSelected: isSelected,
                        onTap: productModel.sellerId != currentUserModel.uId
                            ? () {
                                navigateTo(
                                  context: context,
                                  screen: OrderOffer(
                                    productModel: productModel,
                                    shopModel: widget.shopModel,
                                    chatId: widget.chatId,
                                    receiverId: widget.receiverId,
                                  ),
                                );
                              }
                            : () {
                                setState(() {
                                  if (selectedProductIds.isNotEmpty) {
                                    // Toggle selection
                                    if (isSelected) {
                                      selectedProductIds.remove(
                                        productModel.id,
                                      );
                                    } else {
                                      selectedProductIds.add(productModel.id);
                                    }
                                  } else {
                                    navigateTo(
                                      context: context,
                                      screen: OrderOffer(
                                        productModel: productModel,
                                        shopModel: widget.shopModel,
                                        chatId: widget.chatId,
                                        receiverId: widget.receiverId,
                                      ),
                                    );
                                  }
                                });
                              },
                        onLongPress:
                            productModel.sellerId != currentUserModel.uId
                            ? null
                            : () {
                                setState(() {
                                  if (isSelected) {
                                    selectedProductIds.remove(productModel.id);
                                  } else {
                                    selectedProductIds.add(productModel.id);
                                  }
                                });
                              },
                        deleteButton:
                            selectedProductIds.isNotEmpty &&
                                widget.shopModel.sellerId ==
                                    currentUserModel.uId
                            ? () => MultiProductDeleter.show(
                                context: context,
                                shopModel: widget.shopModel,
                                selectedProductIds: selectedProductIds,
                                onDeleteComplete: () {
                                  setState(() {
                                    selectedProductIds.clear();
                                  });
                                },
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MultiProductDeleter {
  static void show({
    required BuildContext context,
    ShopModel? shopModel,
    required List<String> selectedProductIds,
    required VoidCallback onDeleteComplete,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            'Delete Selected Products',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        content: Column(
          spacing: 5,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete ${selectedProductIds.length} selected product(s)?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Row(
              spacing: 5,
              children: [
                Expanded(
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, // Text and icon color
                      side: const BorderSide(
                        color: Colors.red,
                      ), // 🔴 Red border
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ProductCubit.get(context)
                          .deleteProductsAndRefreshUI(
                            shopModel: shopModel!,
                            productIds: selectedProductIds,
                          )
                          .then((_) {
                            // Clear selection after deletion
                            onDeleteComplete();
                          });
                    },
                    child: Text(S.of(context).delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
