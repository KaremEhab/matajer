import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/search/widgets/serach_shop_card.dart';

class FilterShopsListScreen extends StatefulWidget {
  const FilterShopsListScreen({super.key, required this.shops});

  final List<ShopModel> shops;

  @override
  State<FilterShopsListScreen> createState() => _FilterShopsListScreenState();
}

class _FilterShopsListScreenState extends State<FilterShopsListScreen> {
  List<String> selectedShopIds = [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Filtered Products')),
          body: ListView.builder(
            itemCount: widget.shops.length,
            padding: EdgeInsets.symmetric(horizontal: 7),
            itemBuilder: (context, index) {
              final shopModel = widget.shops[index];
              // final isSelected = selectedShopIds.contains(shopModel.shopId);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: SearchShopCard(shop: shopModel),
              );
              // return ShopProductsCard(
              //   productModel: productModel,
              //   isSelected: isSelected,
              //   onTap: () {
              //     setState(() {
              //       if (selectedProductIds.isNotEmpty) {
              //         // Toggle selection
              //         if (isSelected) {
              //           selectedProductIds.remove(productModel.id);
              //         } else {
              //           selectedProductIds.add(productModel.id);
              //         }
              //       } else {
              //         slideAnimation(
              //           context: context,
              //           destination: ProductDetailsScreen(
              //             productModel: productModel,
              //           ),
              //           rightSlide: true,
              //         );
              //       }
              //     });
              //   },
              //   onLongPress: () {
              //     setState(() {
              //       if (isSelected) {
              //         selectedProductIds.remove(productModel.id);
              //       } else {
              //         selectedProductIds.add(productModel.id);
              //       }
              //     });
              //   },
              //   deleteButton:
              //       selectedProductIds.isNotEmpty
              //           ? () => MultiProductDeleter.show(
              //             context: context,
              //             selectedProductIds: selectedProductIds,
              //             onDeleteComplete: () {
              //               setState(() {
              //                 selectedProductIds.clear();
              //               });
              //             },
              //           )
              //           : null,
              // );
            },
          ),
        );
      },
    );
  }
}
