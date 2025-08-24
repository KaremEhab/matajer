import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/cubit/wallet/wallet_state.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/models/wallet_model.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit() : super(WalletInitialState());

  static WalletCubit get(context) => BlocProvider.of(context);
  final userCubit = UserCubit();

  List<WalletModel> walletList = [];
  final Map<String, ShopModel?> _shopInfoCache = {};

  Future<ShopModel?> getShopInfo(String shopId) async {
    if (_shopInfoCache.containsKey(shopId)) {
      return _shopInfoCache[shopId];
    }

    final shop = await userCubit.getShopInfoById(
      shopId,
    ); // ✅ no userCubit.get here
    _shopInfoCache[shopId] = shop;
    return shop;
  }

  Future<void> getWalletData() async {
    walletList = [];
    emit(WalletGetWalletDataLoadingState());
    try {
      var result = await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('wallet')
          .orderBy('createdAt', descending: true)
          .get();
      for (var element in result.docs) {
        walletList.add(WalletModel.fromJson(element.data(), element.id));
      }
      emit(WalletGetWalletDataSuccessState());
    } catch (e) {
      emit(WalletGetWalletDataErrorState(e.toString()));
    }
  }

  Future<void> addWithdrawRequest({
    required num amount,
    required String paypalEmail,
  }) async {
    emit(WalletAddWithdrawRequestLoadingState());
    try {
      await FirebaseFirestore.instance.collection('withdrawals').add({
        'amount': amount,
        'paypalEmail': paypalEmail,
        'createdAt': Timestamp.now(),
        'status': 'PENDING',
        'sellerId': uId,
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('wallet')
          .add({
            'amount': -amount,
            'title': 'Withdraw',
            'createdAt': Timestamp.now(),
          });
      await getWalletData();
      emit(WalletAddWithdrawRequestSuccessState());
    } catch (e) {
      emit(WalletAddWithdrawRequestErrorState(e.toString()));
    }
  }
}
