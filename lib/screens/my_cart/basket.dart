import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/cubit/user/user_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/home.dart';
import 'package:matajer/screens/home/shop_screen.dart';
import 'package:matajer/screens/home/widgets/home/home_appBar.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/screens/paypal/success_payment.dart';
import 'package:matajer/screens/settings/address.dart';
import 'package:matajer/screens/whatsApp/chat_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:uuid/uuid.dart';

class Basket extends StatefulWidget {
  const Basket({super.key, required this.shopId});

  final String shopId;

  @override
  State<Basket> createState() => _BasketState();
}

class _BasketState extends State<Basket> {
  final GlobalKey<HomeState> homeKey = GlobalKey<HomeState>();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  bool isPaymentExpanded = false;

  late ShopModel shopModel;

  int _currentIndex = 0;

  List<num> payPrice = [0, 5, 10, 0];

  num total = 0;
  num appCommission = 0;

  final userEmirate = currentUserModel.emirate;

  num deliveryDays = 0;
  num deliveryPrice = 0;

  @override
  void initState() {
    super.initState();

    getShopData();

    _scrollController.addListener(() {
      final width =
          MediaQuery.of(context).size.width * 0.96 + 7; // item + spacing
      final index = (_scrollController.offset + width / 2) ~/ width;
      if (_currentIndex != index && mounted) {
        setState(() {
          _currentIndex = index;
        });
      }
    });

    final productCubit = ProductCubit.get(context);
    final userCubit = UserCubit.get(context);

    // Load commission
    productCubit.getAppCommission();

    // 🟢 Immediately fetch shop info
    userCubit.getShopInfoById(widget.shopId);
  }

  Future<void> getShopData() async {
    shopModel = (await ProductCubit.get(
      context,
    ).getShop(sellerId: widget.shopId))!;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductGetAppCommissionSuccessState) {
          UserCubit.get(context).getShopInfoById(widget.shopId);
          appCommission = state.commission;
        }
        if (state is ProductPaypalPaySuccessState) {
          // navigateTo(
          //   context: context,
          //   screen: PayPalPage(paypalLink: state.paymentLink, shopId: widget.shopId),
          // );
          final String randomOrderId = const Uuid().v4();

          navigateTo(
            context: context,
            screen: SuccessPayment(
              orderId: randomOrderId,
              shopId: widget.shopId,
              deliveryTime: deliveryDays,
              price:
                  total.toDouble() + deliveryPrice, // لو عايز تضيف سعر التوصيل
            ),
          );
        }
        if (state is ProductPlaceOrderErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: primaryColor),
          );
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
        payPrice[0] = ProductCubit.get(context).totalCartPrice;

        for (int i = 0; i < payPrice.length - 2; i++) {
          total += payPrice[i];
        }

        // عمولة المتجر
        payPrice[2] = (payPrice[0] * appCommission) / 100;

        // رسوم الدفع
        payPrice[3] = payPrice[0] * 5 / 100;

        total += payPrice[2] + payPrice[3];
        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            forceMaterialTransparency: true,
            leadingWidth: 53,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(
                lang == 'en' ? 7 : 0,
                6,
                lang == 'ar' ? 7 : 0,
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
            title: buildAddressMenu(context, -15),
            actions: [
              Padding(
                padding: EdgeInsets.only(
                  right: lang == 'en' ? 7 : 0,
                  left: lang == 'ar' ? 7 : 0,
                ),
                child: Material(
                  color: lightGreyColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () async {
                      if (cartShopId != null) {
                        chatReceiverName = shopModel.shopName;
                        chatReceiverImage = shopModel.shopLogoUrl;

                        if (!context.mounted) return;
                        slideAnimation(
                          context: context,
                          destination: ShopScreen(shopModel: shopModel),
                        );
                      } else {
                        setState(() {
                          layoutPageController!
                              .animateToPage(
                                0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.ease,
                              )
                              .then((_) => homeKey.currentState?.scrollToTop());
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Icon(
                        Icons.add_shopping_cart_rounded,
                        color: textColor,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // title: Text(
            //   S.of(context).basket,
            //   style: TextStyle(
            //     fontSize: 21,
            //     fontWeight: FontWeight.w700,
            //     color: textColor,
            //   ),
            // ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                SizedBox(
                  height: 125,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: ProductCubit.get(context).cartProducts.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final product = ProductCubit.get(
                        context,
                      ).cartProducts[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        child: Material(
                          color: formFieldColor,
                          borderRadius: BorderRadius.circular(15),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: 0.98.sw,
                              padding: EdgeInsets.all(10),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: textColor.withOpacity(0.1),
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 9,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          product.product.title,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          "${S.of(context).quantity}: ${product.quantity}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'AED ${formatNumberWithCommas(product.piecePrice.toDouble())}',
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: product.product.images.isEmpty
                                          ? Material(
                                              color: lightGreyColor.withOpacity(
                                                0.4,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  IconlyLight.image,
                                                  size: 50,
                                                ),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl:
                                                  product.product.images.first,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (ProductCubit.get(context).cartProducts.length > 1) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: ProductCubit.get(context).cartProducts.length,
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
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 0),
                      RepaintBoundary(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: formFieldColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                spacing: 5,
                                children: [
                                  SvgPicture.asset(
                                    "images/special-requests-illustration.svg",
                                    height: 70,
                                    width: 70,
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (context) =>
                                        const SizedBox(
                                          height: 70,
                                          width: 70,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                          ),
                                        ),
                                  ),
                                  Text(
                                    S.of(context).go_to_chat_tip,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Material(
                                color: Color(0xffEBE6F6),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () async {
                                    final shopId = widget.shopId;
                                    final shopName = shopModel.shopName;
                                    final shopLogo = shopModel.shopLogoUrl;
                                    final userId = currentUserModel.uId;
                                    final chatId = '${userId}_$shopId';

                                    final chatCubit = ChatsCubit.instance;
                                    await chatCubit.createChatRoom(
                                      userId: userId,
                                      shopId: shopId,
                                    );

                                    if (!context.mounted) return;

                                    // Navigate immediately 🚀
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatDetailPage(
                                          chatId: chatId,
                                          receiverId: shopId,
                                          clearSendMessage: true,
                                          receiverName: shopName,
                                          receiverImage: shopLogo,
                                        ),
                                      ),
                                    );

                                    // Fire-and-forget message (don’t await)
                                    unawaited(
                                      chatCubit.sendProductMentionMessage(
                                        chatId: chatId,
                                        senderId: userId,
                                        receiverId: shopId,
                                        message: "",
                                        product: ProductCubit.get(context)
                                            .cartProducts[_pageController.page!
                                                .toInt()]
                                            .product,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          S.of(context).chat,
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.arrow_right_alt_rounded,
                                          color: primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      RepaintBoundary(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: formFieldColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            spacing: 15,
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 30),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize
                                      .min, // Keep column size minimal
                                  children: [
                                    Text(
                                      S.of(context).delivery_days,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    BlocBuilder<UserCubit, UserState>(
                                      buildWhen: (previous, current) =>
                                          current is GetShopByIdSuccessState ||
                                          current is UserInitialState,
                                      builder: (context, state) {
                                        if (deliveryDays != null &&
                                            deliveryDays != 0 &&
                                            deliveryPrice != null &&
                                            deliveryPrice != 0) {
                                          return Text(
                                            "${S.of(context).arriving_in_approx} $deliveryDays ${S.of(context).days} - ${S.of(context).price}: $deliveryPrice AED",
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                            maxLines: 2,
                                          );
                                        } else {
                                          return Text(
                                            S.of(context).loading_delivery,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        S.of(context).pay_with,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      PaymentOptions(),
                    ],
                  ),
                ),
                if (isPaymentExpanded) SizedBox(height: 370),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Material(
              color: transparentColor,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                margin: EdgeInsets.symmetric(horizontal: 7, vertical: 10),
                decoration: BoxDecoration(
                  color: formFieldColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: greyColor.withOpacity(0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          isPaymentExpanded = !isPaymentExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            S.of(context).payment_summary,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPaymentExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPaymentExpanded) ...[
                      SizedBox(height: 5),
                      ListView.builder(
                        itemCount: paySummary.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              if (index != 0) SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    paySummary[index],
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: textColor.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "AED ${formatNumberWithCommas(payPrice[index].toDouble())}",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Divider(
                          color: greyColor.withOpacity(0.3),
                          thickness: 3,
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          S.of(context).total_amount,
                          style: TextStyle(
                            fontSize: 19,
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "AED ${formatNumberWithCommas(total.toDouble())}",
                          style: TextStyle(
                            fontSize: 19,
                            color: textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              borderRadius: BorderRadius.circular(17.r),
                              color: primaryColor.withOpacity(0.1),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(17.r),
                                onTap: () async {
                                  ShopModel? seller = await ProductCubit.get(
                                    context,
                                  ).getShop(sellerId: widget.shopId);

                                  chatReceiverName = seller!.shopName;
                                  chatReceiverImage = seller.shopLogoUrl;

                                  if (!context.mounted) return;
                                  slideAnimation(
                                    context: context,
                                    destination: ShopScreen(shopModel: seller),
                                  );
                                },
                                child: Center(
                                  child: Text(
                                    S.of(context).add_item,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              borderRadius: BorderRadius.circular(17.r),
                              color: primaryColor,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(17.r),
                                onTap: state is ProductPaypalPayLoadingState
                                    ? null
                                    : () async {
                                        if (currentUserModel.currentAddress ==
                                                null ||
                                            currentUserModel
                                                .currentAddress!
                                                .isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                S
                                                    .of(context)
                                                    .please_select_address_before_cont,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 2),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadiusGeometry.circular(
                                                      15,
                                                    ),
                                              ),
                                              action: SnackBarAction(
                                                label: S.of(context).select,
                                                textColor: Colors.white,
                                                onPressed: () {
                                                  // Navigate to address selection screen
                                                  navigateTo(
                                                    context: context,
                                                    screen: SavedAddress(),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        // ✅ Proceed if address is selected
                                        await ProductCubit.get(
                                          context,
                                        ).paypal(val: total);
                                      },
                                // onTap: () {
                                //   slideAnimation(
                                //     context: context,
                                //     destination: Checkout(
                                //       total: total,
                                //       shopId: widget.shopId,
                                //     ),
                                //   );
                                // },
                                child: Center(
                                  child: state is ProductPaypalPayLoadingState
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          S.of(context).proceed_to_buy,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PaymentOptions extends StatefulWidget {
  const PaymentOptions({super.key});

  @override
  State<PaymentOptions> createState() => _PaymentOptionsState();
}

class _PaymentOptionsState extends State<PaymentOptions> {
  int? selectedPaymentMethod = 1; // 0 = new card, 1 = PayPal

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: formFieldColor,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    selectedPaymentMethod = index;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 5),
                          if (index == 0)
                            const Icon(Icons.credit_card, size: 30)
                          else
                            const Icon(
                              Icons.paypal_outlined,
                              size: 30,
                              color: Colors.blue,
                            ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                index == 0
                                    ? S.of(context).new_card
                                    : S.of(context).paypal,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                index == 0
                                    ? S.of(context).lets_add_new_card
                                    : "243** **** ***** *****",
                                style: const TextStyle(fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Radio<int>(
                        value: index,
                        activeColor: primaryColor,
                        groupValue: selectedPaymentMethod,
                        onChanged: (val) {
                          setState(() {
                            selectedPaymentMethod = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
