import 'package:matajer/models/comments_model.dart';

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

/// This will be used when a new comment is added
class CommentsUpdatedState extends CommentsState {
  final List<CommentsModel> comments;

  CommentsUpdatedState(this.comments);
}