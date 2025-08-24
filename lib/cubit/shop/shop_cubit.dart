import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/cubit/shop/shop_state.dart';
import 'package:matajer/models/shop_model.dart';

class ShopCubit extends Cubit<ShopState> {
  ShopCubit() : super(ShopInitialState());

  static ShopCubit get(context) => BlocProvider.of(context);

  Future<void> createShop(ShopModel shopModel, String userId) async {
    final docRef = FirebaseFirestore.instance.collection('shops').doc();

    await docRef.set({...shopModel.toMap(), 'sellerId': userId});

    // Optional: Update userType to 'seller' in users collection
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'userType': 'seller',
    });
  }
}
