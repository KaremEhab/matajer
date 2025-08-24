abstract class ReviewsState {}

class ReviewsInitialState extends ReviewsState {}

class ReviewsLoadingState extends ReviewsState {}

class ReviewsSuccessState extends ReviewsState {}

class ReviewsErrorState extends ReviewsState {
  final String error;
  ReviewsErrorState({required this.error});
}
