import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart' as direction;
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/cart_product_item_model.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/layout.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OrderDetails extends StatefulWidget {
  const OrderDetails({
    super.key,
    this.goBack = true,
    required this.order,
    this.orderStatus,
  });

  final bool goBack;
  final OrderModel order;
  final OrderStatus? orderStatus;

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  final PageController _pageController = PageController();
  int totalQuantity = 0;
  int _currentProductIndex = 0; // Track current page

  List<num> payPrice = [0, 5, 10, 0];

  num total = 0;
  num appCommission = 0;

  // void calculations() {
  //   totalQuantity = widget.order.products.fold(
  //     0,
  //     (sum, product) => sum + product.quantity,
  //   );
  //
  //   total = 0;
  //   payPrice[0] = widget.order.price;
  //   for (int i = 0; i < payPrice.length - 2; i++) {
  //     total += payPrice[i];
  //   }
  //   payPrice[2] = total * appCommission / 100;
  //   payPrice[3] = total * 5 / 100;
  //   total += payPrice[3] + payPrice[2];
  // }

  late ShopModel shopModel;
  late CartProductItemModel currentProduct;
  final userEmirate = currentUserModel.emirate;

  num deliveryDays = 0;
  num deliveryPrice = 0;

  @override
  void initState() {
    super.initState();

    currentProduct = widget.order.products[_currentProductIndex];
    getShopData();
  }

  Future<void> getShopData() async {
    // Load commission
    ProductCubit.get(context).getAppCommission();

    shopModel = (await ProductCubit.get(
      context,
    ).getShop(sellerId: widget.order.shopId))!;

    // قائمة الـ options
    final options = shopModel.deliveryOptions ?? [];

    // نحاول نلاقي الإمارة بتاعت المستخدم
    final selectedOption = options.cast<Map<String, dynamic>?>().firstWhere(
      (opt) => opt?['emirate'] == userEmirate,
      orElse: () => null,
    );

    deliveryDays = selectedOption?['days'] ?? 0;
    deliveryPrice = selectedOption?['price'] ?? 0;

    payPrice = [0, deliveryPrice, 10, 0];
  }

  @override
  Widget build(BuildContext context) {
    List<String> paySummary = [
      S.of(context).subtotal,
      S.of(context).delivery_fees,
      S.of(context).service_fees,
      S.of(context).payment_fees,
    ];

    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductGetAppCommissionSuccessState) {
          appCommission = state.commission;
        }
      },
      builder: (context, state) {
        List<String> paySummary = [
          S.of(context).subtotal,
          S.of(context).delivery_fees,
          S.of(context).service_fees,
          S.of(context).payment_fees,
        ];
        total = 0;
        totalQuantity = widget.order.products.fold(
          0,
          (sum, product) => sum + product.quantity,
        );
        payPrice[0] = widget.order.products.fold<num>(
          0,
          (sum, product) => sum + product.totalPrice,
        );

        for (int i = 0; i < payPrice.length - 2; i++) {
          total += payPrice[i];
        }

        // عمولة المتجر
        payPrice[2] = (payPrice[0] * appCommission) / 100;

        // رسوم الدفع
        payPrice[3] = payPrice[0] * 5 / 100;

        total += payPrice[2] + payPrice[3];
        return PopScope(
          onPopInvokedWithResult: (result, _) async {
            if (!widget.goBack) {
              navigateAndFinish(
                context: context,
                screen: const Layout(getUserData: true),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              forceMaterialTransparency: true,
              leadingWidth: 53,
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
                    onTap: widget.goBack
                        ? () => Navigator.pop(context)
                        : () => navigateAndFinish(
                            context: context,
                            screen: const Layout(getUserData: true),
                          ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 160,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.order.products.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentProductIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        var product = widget.order.products[index];
                        return _buildProductCard(product, index);
                      },
                    ),
                  ),

                  if (widget.order.products.length > 1) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: widget.order.products.length,
                        effect: WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          activeDotColor: primaryColor,
                          dotColor: Colors.grey.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                    child: Text(
                      S.of(context).order_details,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Column(
                      spacing: 10,
                      children: [
                        _buildSpecificationsSection(currentProduct),
                        Container(
                          width: 1.sw,
                          margin: EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    S.of(context).total_quantity,
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    totalQuantity.toString(),
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    paySummary[1],
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    formatNumberWithCommas(
                                      payPrice[1].toDouble(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    paySummary[2],
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    formatNumberWithCommas(
                                      payPrice[2].toDouble(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    paySummary[3],
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    formatNumberWithCommas(
                                      payPrice[3].toDouble(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(
                                  color: greyColor.withOpacity(0.15),
                                  thickness: 3,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    S.of(context).total_price,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: textColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    "AED ${formatNumberWithCommas(widget.order.price.toDouble())}",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: textColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(
                                  color: greyColor.withOpacity(0.15),
                                  thickness: 3,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    spacing: 5,
                                    children: [
                                      const Icon(
                                        Icons.credit_score_rounded,
                                        color: textColor,
                                      ),
                                      Text(
                                        S.of(context).payment_method,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.paypal,
                                        color: primaryColor,
                                        size: 26,
                                      ),
                                      Text(
                                        S.of(context).paypal,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.timelapse_rounded,
                                        color: textColor,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        S.of(context).delivery_days,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${widget.order.deliveryTime} ${S.of(context).days}",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildProductCard(product, int index) {
    // Your existing product card widget logic here
    return Padding(
      padding: EdgeInsets.only(
        left: lang == 'en'
            ? index == 0
                  ? 7
                  : 0
            : 7,
        right: lang == 'ar'
            ? index == 0
                  ? 7
                  : 0
            : 7,
        bottom: 5,
        top: 5,
      ),
      child: Padding(
        padding: index == 0 ? EdgeInsets.only(left: 7) : EdgeInsets.zero,
        child: Material(
          color: lightGreyColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(22.r),
          child: Container(
            height: 170,
            width: 0.98.sw,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: textColor.withOpacity(0.1),
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: CachedNetworkImage(
                        imageUrl: product.product.images.first,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: const CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              ),
                            ),
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: lang == 'en' ? 5 : 15,
                      right: lang == 'ar' ? 5 : 15,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            product.product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '${S.current.ordered}: ${DateFormat.yMMMd().format(widget.order.createdAt.toDate())}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 13),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Material(
                              color: getStatusBackgroundColor(
                                widget.order.orderStatus,
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      IconlyLight.document,
                                      color: getStatusTextColor(
                                        widget.order.orderStatus,
                                      ),
                                      size: 20,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      getTranslatedOrderStatus(
                                        context,
                                        widget.order.orderStatus,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: getStatusTextColor(
                                          widget.order.orderStatus,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                "Q: ${product.quantity}",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Text(
                          "ID: #${widget.order.id}",
                          textDirection: direction.TextDirection.ltr,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
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
    );
  }

  Widget _buildSpecificationsSection(product) {
    return Center(
      child: Container(
        width: 1.sw,
        margin: EdgeInsets.symmetric(horizontal: 7),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        decoration: BoxDecoration(
          color: lightGreyColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: textColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).location,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconlyBold.location, color: primaryColor, size: 18),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    widget.order.buyerAddress,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: greyColor.withOpacity(0.15), thickness: 3),
            ),

            // Selected Specifications
            Text(
              S.of(context).specification_details,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            SizedBox(height: 5),
            Wrap(
              spacing: 5,
              runSpacing: 2,
              children: product.selectedSpecifications.map<Widget>((spec) {
                final title = spec['title'] ?? '';
                final value = spec['value'] ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            // if (product.product.description.isNotEmpty)
            //   CustomExpandableRichText(
            //     textWidth: double.infinity,
            //     textHeight: 1.1,
            //     fontWeight: FontWeight.w400,
            //     maxLines: 4,
            //     text: product.product.description,
            //   ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: greyColor.withOpacity(0.15), thickness: 3),
            ),
            // Price breakdown
            _buildPriceRow(
              S.of(context).base_price,
              "AED ${formatNumberWithCommas(product.totalPrice.toDouble())}",
            ),
            _buildPriceRow(S.of(context).quantity, "${product.quantity}"),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
