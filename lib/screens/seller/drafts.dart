import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/draft_storage.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/seller/add_products.dart';
import 'package:matajer/widgets/clear_dialog.dart';

class DraftsPage extends StatefulWidget {
  final ShopModel shopModel;
  const DraftsPage({super.key, required this.shopModel});

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  TextEditingController searchController = TextEditingController();
  List<ProductModel> allDrafts = []; // original unfiltered list
  List<ProductModel> filteredDrafts = []; // filtered list to display

  @override
  void initState() {
    super.initState();
    loadDrafts();
  }

  Future<void> loadDrafts() async {
    final shopId = widget.shopModel.shopId;
    final drafts = await DraftsStorage.getDrafts(shopId);

    drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      allDrafts = drafts;
      filteredDrafts = List.from(allDrafts);
    });
  }

  void searchDrafts(String query) {
    query = query.toLowerCase();

    final results = allDrafts.where((draft) {
      final titleMatch = draft.title.toLowerCase().contains(query);
      final priceMatch = draft.price.toString().contains(query);
      return titleMatch || priceMatch;
    }).toList();

    setState(() {
      filteredDrafts = results;
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
          S.of(context).drafts,
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
                  clearBtn: () async {
                    Navigator.pop(context); // Close the dialog
                    DraftsStorage.clearDrafts(widget.shopModel.shopId);
                    await DraftsStorage.getDrafts(widget.shopModel.shopId);
                  },
                ),
              );
            },
          ),
          // IconButton(
          //   icon: Icon(Icons.delete, color: Colors.red),
          //   onPressed: () async {
          //     await DraftsStorage.clearDrafts(widget.shopModel.shopId);
          //     await DraftsStorage.getDrafts(widget.shopModel.shopId);
          //   },
          // ),
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
              allDrafts.isEmpty || filteredDrafts.isEmpty
                  ? Center(child: Text(S.of(context).no_drafts_found))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredDrafts.length,
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemBuilder: (context, index) {
                        final product = filteredDrafts[index];

                        final filteredSubtitles = product.specifications
                            .expand((spec) => spec.subTitles)
                            .where(
                              (sub) => colorNames.containsKey(
                                sub.title.toLowerCase().replaceAll(' ', ''),
                              ),
                            )
                            .toList();

                        final hasColors = filteredSubtitles.isNotEmpty;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddProducts(
                                  shopModel: widget.shopModel,
                                  draftProduct: product,
                                ),
                              ),
                            ).then((_) => loadDrafts());
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
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: product.images.isNotEmpty
                                            ? product.images.first.contains(
                                                    'http',
                                                  )
                                                  ? Image.network(
                                                      product.images.first,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    )
                                                  : Image.file(
                                                      File(
                                                        product.images.first,
                                                      ),
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    )
                                            : Container(
                                                color: lightGreyColor,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  IconlyLight.image,
                                                  size: 65,
                                                ),
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
                                            final colorNum =
                                                product.discount <= 0 ? 5 : 2;
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
                                                .take(colorNum)
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
                                                    final colorNum =
                                                        product.discount <= 0
                                                        ? 5
                                                        : 2;
                                                    final colorWidgets =
                                                        <Widget>[];

                                                    for (
                                                      int i = 0;
                                                      i <
                                                              filteredSubtitles
                                                                  .length &&
                                                          i < colorNum;
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
                                                        colorNum;
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
                                                child: Text(
                                                  product.description,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                        if (product.discount <= 0)
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
                                    SizedBox(height: 5),
                                    if (product.discount > 0)
                                      Row(
                                        spacing: 5,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'AED ${NumberFormat('#,###').format(product.price)}',
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: Colors.red,
                                              color: Colors.red.withOpacity(
                                                0.5,
                                              ),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'AED ${NumberFormat('#,###').format(product.price - product.price * (product.discount / 100))}',
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

                              // Delete button
                              Positioned(
                                top: 6,
                                right: 6,
                                child: InkWell(
                                  onTap: () async {
                                    await DraftsStorage.removeDraft(
                                      widget.shopModel.shopId,
                                      product.id,
                                    );
                                    await loadDrafts();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.white,
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
