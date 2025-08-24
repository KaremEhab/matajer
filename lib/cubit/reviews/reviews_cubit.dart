import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/models/reviews_model.dart';
import 'package:matajer/cubit/reviews/reviews_state.dart';

class ReviewsCubit extends Cubit<ReviewsState> {
  ReviewsCubit() : super(ReviewsInitialState());

  static ReviewsCubit get(context) => BlocProvider.of(context);

  List<ReviewsModel> reviews = [];

  Future<void> getReviewsByProductId(String productId) async {
    emit(ReviewsLoadingState());

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .get();

      reviews = querySnapshot.docs
          .map((doc) => ReviewsModel.fromJson(doc.data()))
          .toList();

      emit(ReviewsSuccessState());
    } catch (e) {
      emit(ReviewsErrorState(error: e.toString()));
    }
  }
}
