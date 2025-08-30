import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/wallet/wallet_cubit.dart';
import 'package:matajer/cubit/wallet/wallet_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/models/wallet_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/widgets/sticky_header_delegate.dart';
import 'package:matajer/wallet_transactions.dart';
import 'package:matajer/widgets/custom_form_field.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  final ValueNotifier<double> actionLabelOpacity = ValueNotifier(1.0);

  bool display = false;
  num balance = 0;
  late ScrollController _scrollController;

  final ValueNotifier<double> balanceOpacity = ValueNotifier(0.0);
  final ValueNotifier<bool> showActions = ValueNotifier(false); // NEW

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_updateOpacity);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WalletCubit.get(context).getWalletData();
  }

  void _updateOpacity() {
    double offset = _scrollController.offset;

    // Show/hide AppBar actions
    bool shouldShow = offset > 200.h;
    if (showActions.value != shouldShow) showActions.value = shouldShow;

    // Wallet balance opacity
    if (balance > 0) {
      double startOffset = 180.h;
      double fadeRange = 100.h;
      balanceOpacity.value = ((offset - startOffset) / fadeRange).clamp(
        0.0,
        1.0,
      );
    } else {
      balanceOpacity.value = 0;
    }

    // Action labels fade out after 210.h, fully hidden 60.h later
    double actionFadeStart = 210.h;
    double actionFadeRange = 60.h; // how fast it disappears
    double newOpacity = (1 - (offset - actionFadeStart) / actionFadeRange)
        .clamp(0.0, 1.0);
    if ((newOpacity - actionLabelOpacity.value).abs() > 0.01) {
      actionLabelOpacity.value = newOpacity;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateOpacity);
    _scrollController.dispose();
    balanceOpacity.dispose();
    showActions.dispose(); // Dispose new ValueNotifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletCubit, WalletState>(
      listener: (context, state) {
        if (state is WalletGetWalletDataSuccessState) {
          balance = 0;
          for (var element in WalletCubit.get(context).walletList) {
            balance += element.amount;
          }
          display = !display;
        }
      },
      builder: (context, state) {
        return Scaffold(
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
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: Icon(backIcon(), color: textColor, size: 26),
                  ),
                ),
              ),
            ),
            centerTitle: true,
            title: Text(
              S.of(context).my_wallet,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: showActions,
                builder: (context, visible, _) {
                  if (!visible || balance <= 0) return SizedBox.shrink();
                  return ValueListenableBuilder<double>(
                    valueListenable: balanceOpacity,
                    builder: (context, opacity, _) {
                      return Opacity(
                        opacity: opacity,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Center(
                            child: Text(
                              'AED ${formatNumberWithCommas(balance.toDouble())}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Wallet card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildWalletCard(
                        context,
                        balance.toDouble(),
                      ), // Extracted your visa card widget
                      SizedBox(height: 25.h),
                    ],
                  ),
                ),
              ),

              // Actions
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyHeaderDelegate(
                  height: 90,
                  child: _buildActionButtons(context, () {
                    _showWithdrawDialog(context, balance);
                  }), // Withdraw / Activity / Bank
                ),
              ),

              // Transactions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildTransactionsHeader(
                        context,
                      ), // Transactions + See all
                    ],
                  ),
                ),
              ),

              // Transactions list
              if (WalletCubit.get(context).walletList.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 100),
                        const Icon(
                          Icons.error_outline_rounded,
                          color: primaryColor,
                          size: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          S.of(context).empty_transactions,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (display)
                SliverSafeArea(
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      WalletModel walletModel = WalletCubit.get(
                        context,
                      ).walletList[index];
                      String shopId = walletModel.shopId;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: index == 0 ? 10 : 10,
                        ),
                        child: FutureBuilder<ShopModel?>(
                          future: WalletCubit.get(context).getShopInfo(shopId),
                          builder: (context, snapshot) {
                            final shopModel = snapshot.data;
                            return buildTransactionTile(
                              context,
                              shopModel,
                              walletModel,
                            );
                          },
                        ),
                      );
                    }, childCount: WalletCubit.get(context).walletList.length),
                  ),
                )
              else
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        );
      },
    );
  }

  Widget buildActionButton(
    BuildContext context, {
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Column(
        spacing: 5,
        children: [
          Material(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: double.infinity,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: onTap,
                child: Padding(padding: const EdgeInsets.all(14), child: icon),
              ),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: actionLabelOpacity,
            builder: (context, opacity, _) {
              return Opacity(
                opacity: opacity,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

void _showWithdrawDialog(BuildContext context, num balance) {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final paypalEmailController = TextEditingController();

  num remainingBalance = balance;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          S.of(context).withdraw,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount + Balance
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomFormField(
                            hint: S.of(context).amount,
                            controller: amountController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return S.of(context).amount_validation;
                              }
                              if (double.parse(value) > balance) {
                                return S.of(context).amount_too_high;
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                final enteredAmount =
                                    double.tryParse(value!) ?? 0;
                                remainingBalance = balance - enteredAmount;
                                if (remainingBalance < 0) remainingBalance = 0;
                              });
                            },
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).balance,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'AED ${formatNumberWithCommas(remainingBalance.toDouble())}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // PayPal Email
                    CustomFormField(
                      hint: S.of(context).paypal_email,
                      controller: paypalEmailController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return S.of(context).paypal_email_validation;
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return S.of(context).paypal_email_invalid;
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[800],
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              S.of(context).cancel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              await WalletCubit.get(context).addWithdrawRequest(
                                amount: double.parse(amountController.text),
                                paypalEmail: paypalEmailController.text,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: Text(
                              S.of(context).withdraw,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildActionButton(
  BuildContext context, {
  required Widget icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: Column(
      spacing: 5,
      children: [
        Material(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            width: double.infinity,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(14), child: icon),
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildWalletCard(BuildContext context, double balance) {
  return Center(
    child: Stack(
      children: [
        SvgPicture.asset(
          'images/visa-card.svg',
          width: double.infinity,
          height: 0.53.sw,
        ),
        Container(
          height: 0.53.sw,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset('images/visa-chip.svg'),
                  SvgPicture.asset('images/visa-word.svg'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).your_wallet_balance,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'AED ${formatNumberWithCommas(balance.toDouble())}',
                    style: TextStyle(
                      height: 1.1,
                      fontSize: 43.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButtons(BuildContext context, void Function() onTap) {
  return Container(
    width: 1.sw,
    color: Colors.white,
    margin: EdgeInsets.symmetric(horizontal: 7),
    child: Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          context,
          icon: SvgPicture.asset(
            'images/transfer.svg',
            color: primaryColor,
            height: 24,
          ),
          label: S.of(context).withdraw,
          onTap: onTap,
        ),
        _buildActionButton(
          context,
          icon: const Icon(
            Icons.av_timer_rounded,
            color: primaryColor,
            size: 24,
          ),
          label: S.of(context).activity,
          onTap: () {},
        ),
        _buildActionButton(
          context,
          icon: const Icon(Icons.credit_card, color: primaryColor, size: 24),
          label: S.of(context).bank,
          onTap: () {},
        ),
      ],
    ),
  );
}

Widget _buildTransactionsHeader(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        S.of(context).transactions,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
      InkWell(
        onTap: () =>
            navigateTo(context: context, screen: const WalletTransactions()),
        child: Row(
          children: [
            Text(
              S.of(context).see_all,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const Icon(Icons.arrow_right_alt_rounded, color: primaryColor),
          ],
        ),
      ),
    ],
  );
}

Widget buildTransactionTile(
  BuildContext context,
  ShopModel? shopModel,
  WalletModel walletModel,
) {
  final logoUrl = shopModel?.shopLogoUrl;

  return InkWell(
    borderRadius: BorderRadius.circular(14.r),
    onTap: () {}, // Add your tap handler
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoUrl != null ? buildShopLogo(logoUrl) : buildPlaceholderLogo(),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: shop name + date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      shopModel?.shopName ?? "",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    formatDateHeader(walletModel.createdAt.toDate(), context),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor.withOpacity(0.5)),
                  ),
                ],
              ),
              // Second row: chip + amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Chip(
                      side: BorderSide.none,
                      backgroundColor: secondaryColor,
                      label: Text(
                        getTranslatedWalletType(
                          context,
                          walletModel.walletTypes,
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          height: 0.8,
                          fontSize: 13,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AED ${formatNumberWithCommas(walletModel.amount.toDouble())}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      color: walletModel.amount > 0
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
      ],
    ),
  );
}

Widget buildShopLogo(String logoUrl) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: senderColor, shape: BoxShape.circle),
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 28,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(200.r),
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            progressIndicatorBuilder: (context, url, progress) =>
                shimmerPlaceholder(height: 60, width: 60, radius: 200.r),
            height: 60,
            width: 60,
            fit: BoxFit.cover,
          ),
        ),
      ),
    ),
  );
}

Widget buildPlaceholderLogo() {
  return Material(
    color: greyColor.withOpacity(0.15),
    borderRadius: BorderRadius.circular(100),
    child: const Padding(
      padding: EdgeInsets.all(13),
      child: Icon(IconlyLight.bag, color: textColor, size: 36),
    ),
  );
}
