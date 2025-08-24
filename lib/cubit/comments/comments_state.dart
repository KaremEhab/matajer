abstract class CommentsState {}

class CommentsInitialState extends CommentsState {}

class CommentsLoadingState extends CommentsState {}

class CommentsSuccessState extends CommentsState {}

class CommentsErrorState extends CommentsState {
  final String error;
  CommentsErrorState({required this.error});
}

class CommentsSubmitRatingLoadingState extends CommentsState {}

class CommentsSubmitRatingSuccessState extends CommentsState {}

class CommentsSubmitRatingErrorState extends CommentsState {
  final String error;
  CommentsSubmitRatingErrorState({required this.error});
}
