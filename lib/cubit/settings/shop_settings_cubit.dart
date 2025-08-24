import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShopSettingsCubit extends Cubit<bool> {
  ShopSettingsCubit() : super(false);

  void loadAutoAccept(String shopId) {
    FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            emit(doc['autoAcceptOrders'] ?? false);
          }
        });
  }

  Future<void> toggleAutoAccept(String shopId, bool value) async {
    await FirebaseFirestore.instance.collection('shops').doc(shopId).update({
      'autoAcceptOrders': value,
    });
  }
}
