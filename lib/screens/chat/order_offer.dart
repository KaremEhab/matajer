import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/new_chat/chat_cubit.dart';
import 'package:matajer/new_chat/chat_states.dart';
import 'package:matajer/widgets/custom_form_field.dart';

class OrderOffer extends StatefulWidget {
  const OrderOffer({
    super.key,
    required this.productModel,
    required this.shopModel,
    required this.receiverId,
    required this.chatId,
  });

  final ProductModel productModel;
  final ShopModel shopModel;
  final String chatId, receiverId;

  @override
  OrderOfferState createState() => OrderOfferState();
}

class OrderOfferState extends State<OrderOffer> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController numberOfDaysContoller = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatStates>(
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
              S.of(context).create_new_offer,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              spacing: 20,
              children: [
                SizedBox.shrink(),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {},
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 7),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: textColor.withOpacity(0.1),
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          widget.productModel.images.first,
                                      progressIndicatorBuilder:
                                          (
                                            context,
                                            url,
                                            downloadProgress,
                                          ) => Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  const CircularProgressIndicator(
                                                    color: primaryColor,
                                                  ),
                                            ),
                                          ),
                                      height: 110,
                                      width: 110,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 15,
                                    left: 5,
                                  ),
                                  child: Column(
                                    spacing: 2,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 230,
                                        child: Text(
                                          widget.productModel.title,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        widget.productModel.description,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: textColor.withOpacity(0.45),
                                        ),
                                      ),
                                      if (widget.productModel.discount <= 0)
                                        Text(
                                          'AED ${formatNumberWithCommas(widget.productModel.price.toDouble())}',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 23,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),

                                      if (widget.productModel.discount > 0)
                                        Flex(
                                          spacing: 5,
                                          // crossAxisAlignment:
                                          //     WrapCrossAlignment.end,
                                          direction: Axis.horizontal,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'AED ${formatNumberWithCommas(widget.productModel.price.toDouble())}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  decorationColor: Colors.red,
                                                  color: Colors.red.withOpacity(
                                                    0.5,
                                                  ),
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                'AED ${formatNumberWithCommas(widget.productModel.price - widget.productModel.price * (widget.productModel.discount / 100))}',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Discount badge
                          if (widget.productModel.discount > 0)
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
                                  '${widget.productModel.discount}% ${S.of(context).off}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Form(
                  key: formKey,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      spacing: 15,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomFormField(
                          hasTitle: true,
                          textColor: textColor,
                          maxLines: 5,
                          title: S.of(context).offer_description,
                          hint: S.of(context).offer_description_hint,
                          onTap: () {},
                          validator: (value) {
                            if (value!.isEmpty) {
                              return S.of(context).description_validation;
                            }
                            return null;
                          },
                          controller: descController,
                        ),
                        CustomFormField(
                          hasTitle: true,
                          textColor: textColor,
                          title: S.of(context).price,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).please_enter_price;
                            }
                            final price = double.tryParse(value);
                            if (price == null) {
                              return S
                                  .of(context)
                                  .please_enter_price; // invalid number
                            }
                            if (price <= 0) {
                              return 'Price cannot be 0 or negative';
                            }
                            return null; // valid
                          },
                          keyboardType: TextInputType.number,
                          prefix: const Icon(
                            Icons.attach_money_rounded,
                            color: textColor,
                          ),
                          hint: '- -',
                          onTap: () {},
                          controller: priceController,
                        ),
                        CustomFormField(
                          hasTitle: true,
                          textColor: textColor,
                          keyboardType: TextInputType.number,
                          title: S.of(context).number_of_days,
                          hint: S.of(context).unlimited_default,
                          onTap: () {},
                          validator: (value) {
                            return null;
                          },
                          controller: numberOfDaysContoller,
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Material(
              color: transparentColor,
              child: AnimatedContainer(
                height: 0.1.sh,
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 0.07.sh,
                        width: 0.9.sw,
                        child: Material(
                          borderRadius: BorderRadius.circular(17.r),
                          color: primaryColor,
                          elevation: 15,
                          shadowColor: primaryColor.withOpacity(0.5),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(17.r),
                            onTap: () {
                              Timestamp? expireDate;
                              if (numberOfDaysContoller.text.isNotEmpty) {
                                expireDate = Timestamp.fromDate(
                                  DateTime.now().add(
                                    Duration(
                                      days: int.parse(
                                        numberOfDaysContoller.text,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              if (formKey.currentState!.validate()) {
                                ChatsCubit.instance
                                    .sendOfferMessage(
                                      chatId: widget.chatId,
                                      senderId: widget.shopModel.shopId,
                                      receiverId: widget.receiverId,
                                      product: widget.productModel,
                                      newPrice: num.parse(priceController.text),
                                      description: descController.text,
                                      expireDate: expireDate,
                                    )
                                    .then((value) {
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    });
                              }
                            },
                            child: Center(
                              child: Text(
                                S.of(context).send_offer,
                                style: TextStyle(
                                  height: 0.8,
                                  color: Colors.white,
                                  fontSize: 21.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
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
