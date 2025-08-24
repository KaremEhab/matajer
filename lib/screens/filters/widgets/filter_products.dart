import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/home/categories/shop_products_card.dart';
import 'package:matajer/screens/home/product_details.dart';


class FilterProductsListScreen extends StatefulWidget {
  const FilterProductsListScreen({super.key, required this.products});

  final List<ProductModel> products;

  @override
  State<FilterProductsListScreen> createState() =>
      _FilterProductsListScreenState();
}

class _FilterProductsListScreenState extends State<FilterProductsListScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Filtered Products')),
          body: ListView.builder(
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              final productModel = widget.products[index];

              return ShopProductsCard(
                productModel: productModel,
                isSelected: false,
                onTap: () {
                  navigateTo(
                    context: context,
                    screen: ProductDetailsScreen(productModel: productModel),
                  );
                },
                deleteButton: () {},
              );
            },
          ),
        );
      },
    );
  }
}
