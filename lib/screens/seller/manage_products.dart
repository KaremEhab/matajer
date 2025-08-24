
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/product_list_screen.dart';
import 'package:matajer/screens/seller/add_products.dart';
import 'package:matajer/widgets/clear_dialog.dart';

class ManageProductsPage extends StatefulWidget {
  final ShopModel shopModel;
  const ManageProductsPage({super.key, required this.shopModel});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  TextEditingController searchController = TextEditingController();
  List<String> selectedProductIds = [];
  List<ProductModel> filteredProducts = []; // filtered list to display

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final shopId = widget.shopModel.shopId;

    // Call Cubit method
    await ProductCubit.get(context).getProductsByShopId(shopId: shopId);

    final state = ProductCubit.get(context).state;
    if (state is ProductGetAllProductsSuccessState) {
      final products = state.products;

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        ProductCubit.get(context).allProducts = products;
        filteredProducts = List.from(products);
      });
    }
  }

  void searchDrafts(String query) {
    query = query.toLowerCase();

    final results = ProductCubit.get(context).allProducts.where((draft) {
      final titleMatch = draft.title.toLowerCase().contains(query);
      final priceMatch = draft.price.toString().contains(query);
      return titleMatch || priceMatch;
    }).toList();

    setState(() {
      filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leadingWidth: 52,
        leading: Padding(
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
              onTap: () {
                Navigator.pop(context);
              },
              child: Center(
                child: Icon(backIcon(), color: textColor, size: 26),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          S.of(context).manage_products,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ClearDialog(
                  title: S.of(context).are_you_sure,
                  subtitle: S.of(context).clear_or_delete_shop,
                  clearBtn: () {
                    Navigator.pop(context); // Close the dialog
                    ProductCubit.get(context).deleteAllProductsAndRefreshUI(
                      shopModel: widget.shopModel,
                    ); // Clear products
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 10,
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: S.of(context).searching_for,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 20,
                    ),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                    fillColor: greyColor.withOpacity(0.1),

                    suffixIcon: IconButton(
                      onPressed: () {
                        searchController.clear();
                        searchDrafts('');
                      },
                      icon: Icon(Icons.close),
                      color: greyColor,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) {},
                  onChanged: (value) {
                    searchDrafts(value);
                  },
                ),
              ),
              ProductCubit.get(context).allProducts.isEmpty ||
                      filteredProducts.isEmpty
                  ? Center(child: Text(S.of(context).empty_products))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredProducts.length,
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];

                        final filteredSubtitles = product.specifications
                            .expand((spec) => spec.subTitles)
                            .where(
                              (sub) => colorNames.containsKey(
                                sub.title.toLowerCase().replaceAll(' ', ''),
                              ),
                            )
                            .toList();

                        final hasColors = filteredSubtitles.isNotEmpty;

                        final isSelected = selectedProductIds.contains(
                          product.id,
                        );

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selectedProductIds.isNotEmpty) {
                                // Toggle selection
                                if (isSelected) {
                                  selectedProductIds.remove(product.id);
                                } else {
                                  selectedProductIds.add(product.id);
                                }
                              } else {
                                // If nothing is selected, open details screen
                                navigateTo(
                                  context: context,
                                  screen: AddProducts(
                                    edit: true,
                                    draftProduct: product,
                                    shopModel: widget.shopModel,
                                  ),
                                );
                              }
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              if (isSelected) {
                                selectedProductIds.remove(product.id);
                              } else {
                                selectedProductIds.add(product.id);
                              }
                            });
                          },
                          child: Stack(
                            clipBehavior: Clip.antiAlias,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product image
                                    Expanded(
                                      // aspectRatio: 1,
                                      child: product.images.first == null
                                          ? Center(
                                              child: Icon(
                                                IconlyLight.image,
                                                size: 65,
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                product.images.first,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      product.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      spacing: 5,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          product.quantity > 0
                                              ? S.of(context).in_stock
                                              : S.of(context).out_stock,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: textColor,
                                          ),
                                        ),

                                        Text(
                                          '${product.quantity} ${S.of(context).pieces}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final filteredSpecs = product
                                                .specifications
                                                .where((spec) {
                                                  final lowerTitle = spec.title
                                                      .toLowerCase();
                                                  return !(lowerTitle ==
                                                          'color' ||
                                                      lowerTitle == 'colour' ||
                                                      lowerTitle == 'colors' ||
                                                      lowerTitle == 'colours');
                                                })
                                                .toList();

                                            if (filteredSpecs.isEmpty) {
                                              return SizedBox.shrink();
                                            }

                                            final spec = filteredSpecs.first;
                                            final title = spec.title;
                                            final subtitles =
                                                List<
                                                  ProductSpecificationValueModel
                                                >.from(spec.subTitles);

                                            final joinedSubtitles = subtitles
                                                .map((s) => s.title.toString())
                                                .take(2)
                                                .join(' • '); // Max 2 subtitles

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      joinedSubtitles,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.end,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),

                                    Row(
                                      spacing: 15,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        hasColors
                                            ? Expanded(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: () {
                                                    final colorWidgets =
                                                        <Widget>[];

                                                    for (
                                                      int i = 0;
                                                      i <
                                                              filteredSubtitles
                                                                  .length &&
                                                          i < 2;
                                                      i++
                                                    ) {
                                                      final sub =
                                                          filteredSubtitles[i];
                                                      final color =
                                                          colorNames[sub.title
                                                              .toLowerCase()
                                                              .replaceAll(
                                                                ' ',
                                                                '',
                                                              )]!;

                                                      colorWidgets.add(
                                                        Container(
                                                          height: 20,
                                                          width: 20,
                                                          margin:
                                                              const EdgeInsets.only(
                                                                right: 4,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.all(
                                                                2,
                                                              ),
                                                          decoration: ShapeDecoration(
                                                            color: color,
                                                            shape: OvalBorder(
                                                              side: BorderSide(
                                                                width: 0.8,
                                                                color:
                                                                    color
                                                                            .computeLuminance() >
                                                                        0.5
                                                                    ? Colors
                                                                          .black
                                                                    : Colors
                                                                          .grey
                                                                          .shade300,
                                                              ),
                                                            ),
                                                          ),
                                                          child: Container(
                                                            decoration: ShapeDecoration(
                                                              color: color,
                                                              shape: OvalBorder(
                                                                side: BorderSide(
                                                                  width: 1,
                                                                  color:
                                                                      color
                                                                              .computeLuminance() >
                                                                          0.5
                                                                      ? Colors
                                                                            .black
                                                                      : Colors
                                                                            .grey
                                                                            .shade300,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    final extraCount =
                                                        filteredSubtitles
                                                            .length -
                                                        2;
                                                    if (extraCount > 0) {
                                                      colorWidgets.add(
                                                        Container(
                                                          height: 20,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  25,
                                                                ),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              '+$extraCount',
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    return colorWidgets;
                                                  }(),
                                                ),
                                              )
                                            : Flexible(
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: buildStyledText(
                                                      product.description,
                                                      12,
                                                    ),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),

                                        Text(
                                          'AED ${NumberFormat('#,###').format(product.price)}',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Text(
                                    //   'AED ${product.price.toStringAsFixed(0)}',
                                    //   style: const TextStyle(
                                    //     fontWeight: FontWeight.bold,
                                    //     fontSize: 15,
                                    //     color: Colors.black,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),

                              // Discount badge
                              if (product.discount > 0)
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      '${product.discount}% ${S.of(context).off}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),

                              if (isSelected)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),

                              // delete button top left
                              if (isSelected)
                                Positioned(
                                  top: 5,
                                  left: 5,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    child: GestureDetector(
                                      onTap: selectedProductIds.isNotEmpty
                                          ? () => MultiProductDeleter.show(
                                              context: context,
                                              shopModel: widget.shopModel,
                                              selectedProductIds:
                                                  selectedProductIds,
                                              onDeleteComplete: () {
                                                setState(() {
                                                  selectedProductIds.clear();
                                                });
                                              },
                                            )
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          IconlyLight.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
