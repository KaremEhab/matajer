import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/wallet/wallet_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/profile/wallet.dart';
import 'constants/colors.dart';
import 'cubit/wallet/wallet_cubit.dart';
import 'models/wallet_model.dart';

class WalletTransactions extends StatefulWidget {
  const WalletTransactions({super.key});

  @override
  State<WalletTransactions> createState() => _WalletTransactionsState();
}

class _WalletTransactionsState extends State<WalletTransactions> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletCubit, WalletState>(
      listener: (context, state) {},
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
              S.of(context).transactions,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),

          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Transactions list
              if (WalletCubit.get(context).walletList.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 300),
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
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        );
      },
    );
  }
}
