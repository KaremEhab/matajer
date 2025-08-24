import 'package:cached_network_image/cached_network_image.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/order/order_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/widgets/custom_elevated_button.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  int totalQuantity = 0;
  bool display = false;
  @override
  void initState() {
    super.initState();
    totalQuantity = widget.order.products.fold(
      0,
      (sum, product) => sum + product.quantity,
    );
    display = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            leadingWidth: 53,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(7, 6, 0, 6),
              child: Material(
                color: lightGreyColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Icon(backIcon(), color: textColor, size: 26),
                  ),
                ),
              ),
            ),
            title: Text(
              S.of(context).order_details,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              spacing: 10,
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        spacing: 5,
                        children: [
                          Text(
                            S.of(context).total_quantity,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                          Text(
                            '$totalQuantity',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        spacing: 5,
                        children: [
                          Text(
                            S.of(context).total_price,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                          Text(
                            'AED ${formatNumberWithCommas(widget.order.price.toDouble())}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ConditionalBuilder(
                  condition: display,
                  builder: (context) => widget.order.products.isNotEmpty
                      ? ListView.builder(
                          itemCount: widget.order.products.length,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final product = widget.order.products[index];
                            print(product.selectedSpecifications);

                            return Column(
                              children: [
                                if (index != 0) SizedBox(height: 10),
                                Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 7,
                                      ),
                                      child: Material(
                                        color: formFieldColor,
                                        borderRadius: BorderRadius.circular(
                                          22.r,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            22.r,
                                          ),
                                          onLongPress: null,
                                          onTap: null,
                                          child: Container(
                                            width: double.infinity,
                                            clipBehavior:
                                                Clip.antiAliasWithSaveLayer,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 140,
                                                  child: Padding(
                                                    padding: EdgeInsets.all(10),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      child: CachedNetworkImage(
                                                        imageUrl: product
                                                            .product
                                                            .images
                                                            .first,
                                                        fit: BoxFit.cover,
                                                        height: 120,
                                                        width: double.infinity,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                          lang == 'ar' ? 15 : 0,
                                                          10,
                                                          lang == 'en' ? 15 : 0,
                                                          10,
                                                        ),
                                                    child: Column(
                                                      spacing: 5,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          product.product.title,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        Text(
                                                          "${S.of(context).quantity}: ${product.quantity}",
                                                          style: TextStyle(
                                                            fontSize: 17,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        Text(
                                                          "AED ${formatNumberWithCommas(product.totalPrice.toDouble())}",
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        if (product
                                                            .selectedSpecifications
                                                            .isNotEmpty)
                                                          Wrap(
                                                            spacing: 5,
                                                            runSpacing: 2,
                                                            children: product.selectedSpecifications.map<Widget>((
                                                              spec,
                                                            ) {
                                                              final title =
                                                                  spec['title'] ??
                                                                  '';
                                                              final value =
                                                                  spec['value'] ??
                                                                  '';
                                                              return Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          3,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: primaryColor
                                                                      .withOpacity(
                                                                        0.08,
                                                                      ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  value,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        primaryColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconlyLight.bag,
                                size: 100,
                                color: primaryColor,
                              ),
                              Text(
                                S.of(context).cart_empty,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                  fallback: (context) => const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
                // ListView.separated(
                //   shrinkWrap: true,
                //   padding: EdgeInsets.zero,
                //   physics: const NeverScrollableScrollPhysics(),
                //   itemBuilder: (context, index) {
                //     final product = widget.order.products[index];
                //     print(product.selectedSpecifications);
                //     return Container(
                //       margin: EdgeInsets.symmetric(horizontal: 10),
                //       padding: EdgeInsets.all(15),
                //       decoration: BoxDecoration(
                //         color: primaryColor.withOpacity(0.07),
                //         borderRadius: BorderRadius.circular(25),
                //       ),
                //       child: Column(
                //         spacing: 10,
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           ClipRRect(
                //             borderRadius: BorderRadius.circular(15),
                //             child: CachedNetworkImage(
                //               imageUrl: product.product.images.first,
                //               width: double.infinity,
                //               height: 250,
                //               fit: BoxFit.cover,
                //               placeholder:
                //                   (context, url) => const Center(
                //                     child: CircularProgressIndicator(),
                //                   ),
                //               errorWidget:
                //                   (context, url, error) =>
                //                       const Icon(Icons.error),
                //             ),
                //           ),
                //           Padding(
                //             padding: EdgeInsets.symmetric(horizontal: 5),
                //             child: Column(
                //               spacing: 5,
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   product.product.title,
                //                   style: TextStyle(
                //                     fontSize: 23,
                //                     fontWeight: FontWeight.w900,
                //                     color: textColor,
                //                   ),
                //                 ),
                //                 Row(
                //                   mainAxisAlignment:
                //                       MainAxisAlignment.spaceBetween,
                //                   children: [
                //                     Row(
                //                       spacing: 5,
                //                       children: [
                //                         Text(
                //                           'Quantity:',
                //                           overflow: TextOverflow.ellipsis,
                //                           style: TextStyle(
                //                             fontSize: 17,
                //                             color: textColor.withOpacity(0.5),
                //                           ),
                //                         ),
                //                         Text(
                //                           '${product.quantity}',
                //                           overflow: TextOverflow.ellipsis,
                //                           style: TextStyle(
                //                             color: primaryColor,
                //                             fontSize: 23,
                //                             fontWeight: FontWeight.w800,
                //                           ),
                //                         ),
                //                       ],
                //                     ),
                //                     Text(
                //                       'AED ${product.totalPrice}',
                //                       overflow: TextOverflow.ellipsis,
                //                       style: TextStyle(
                //                         color: primaryColor,
                //                         fontSize: 28,
                //                         fontWeight: FontWeight.w800,
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //                 SingleChildScrollView(
                //                   child: Row(
                //                     children: [
                //                       ...product.selectedSpecifications.map((
                //                         specification,
                //                       ) {
                //                         return Container(
                //                           margin: EdgeInsets.only(right: 5),
                //                           padding: EdgeInsets.symmetric(
                //                             horizontal: 15,
                //                             vertical: 8,
                //                           ),
                //                           decoration: BoxDecoration(
                //                             color: primaryColor,
                //                             borderRadius: BorderRadius.circular(
                //                               13,
                //                             ),
                //                           ),
                //                           child: Text(
                //                             specification['value']!,
                //                             overflow: TextOverflow.ellipsis,
                //                             style: const TextStyle(
                //                               color: Colors.white,
                //                               fontWeight: FontWeight.w700,
                //                             ),
                //                           ),
                //                         );
                //                       }),
                //                     ],
                //                   ),
                //                 ),
                //                 SizedBox(height: 7),
                //               ],
                //             ),
                //           ),
                //         ],
                //       ),
                //     );
                //   },
                //   separatorBuilder: (context, index) => SizedBox(height: 10),
                //   itemCount: widget.order.products.length,
                // ),
              ],
            ),
          ),
          bottomNavigationBar:
              widget.order.orderStatus == OrderStatus.delivered ||
                  widget.order.orderStatus == OrderStatus.rejected
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    height: 0.09.sh,
                    width: double.infinity,
                    child: state is OrderChangeOrderStatusLoadingState
                        ? Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              if (widget.order.orderStatus ==
                                  OrderStatus.pending)
                                Expanded(
                                  child: CustomElevatedButton(
                                    function: () {
                                      OrderCubit.get(context).changeOrderStatus(
                                        order: widget.order,
                                        shopId: widget.order.shopId,
                                        status: OrderStatus.accepted,
                                        context: context,
                                      );
                                    },
                                    backColor: Colors.green,
                                    label: S.of(context).accept_order,
                                  ),
                                ),
                              if (widget.order.orderStatus ==
                                  OrderStatus.accepted)
                                Expanded(
                                  child: CustomElevatedButton(
                                    function: () {
                                      OrderCubit.get(context).changeOrderStatus(
                                        order: widget.order,
                                        shopId: widget.order.shopId,
                                        status: OrderStatus.shipped,
                                        context: context,
                                      );
                                    },
                                    backColor: Colors.orange,
                                    label: S.of(context).order_shipped,
                                  ),
                                ),
                              if (widget.order.orderStatus ==
                                  OrderStatus.shipped)
                                Expanded(
                                  child: CustomElevatedButton(
                                    function: () {
                                      OrderCubit.get(context).changeOrderStatus(
                                        order: widget.order,
                                        shopId: widget.order.shopId,
                                        status: OrderStatus.delivered,
                                        context: context,
                                      );
                                    },
                                    backColor: Colors.teal,
                                    label: S.of(context).order_delivered,
                                  ),
                                ),
                              const SizedBox(width: 10),
                              if (widget.order.orderStatus ==
                                  OrderStatus.pending)
                                Expanded(
                                  child: CustomElevatedButton(
                                    backColor: Colors.red,
                                    label: S.of(context).reject_order,
                                    function: () {
                                      OrderCubit.get(context).changeOrderStatus(
                                        order: widget.order,
                                        shopId: widget.order.shopId,
                                        status: OrderStatus.rejected,
                                        context: context,
                                      );
                                    },
                                  ),
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
