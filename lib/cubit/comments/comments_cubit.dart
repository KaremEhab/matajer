import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/comments/comments_state.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/comments_model.dart';
import 'package:matajer/models/shop_model.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit() : super(CommentsInitialState());

  static CommentsCubit get(context) => BlocProvider.of(context);

  List<CommentsModel> comments = [];
  Map<String, Map<String, dynamic>> commentsCache = {};

  Future<void> getCommentsByShopId(String shopId) async {
    emit(CommentsLoadingState());

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      comments = querySnapshot.docs
          .map((doc) => CommentsModel.fromJson(doc.data()))
          .toList();

      // 🔹 Log the fetched comments
      for (var c in comments) {
        debugPrint("Fetched Comment => ${c.toMap()}");
      }

      emit(CommentsSuccessState());
    } catch (e) {
      debugPrint("❌ Error fetching comments: $e");
      emit(CommentsErrorState(error: e.toString()));
    }
  }

  Future<void> submitShopComment({
    required ShopModel shopModel,
    required String comment,
    double rating = 5,
  }) async {
    try {
      final newComment = CommentsModel(
        comment: comment,
        rating: rating,
        userId: currentUserModel.uId,
        createdAt: Timestamp.now(),
      );

      // 1. Update rating counters
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopModel.shopId)
          .update({
            'numberOfRating': FieldValue.increment(1),
            'sumOfRating': FieldValue.increment(rating),
          });

      // 2. Save in Firestore
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopModel.shopId)
          .collection('comments')
          .add(newComment.toMap());

      // 3. Add to local list for instant UI update
      comments.insert(0, newComment); // show latest on top
      emit(CommentsUpdatedState(comments));

      // 4. Notifications
      await NotificationCubit.instance.sendNotification(
        title: "${currentUserModel.username} commented on your shop",
        body: comment,
        userId: shopModel.shopId,
        notificationType: NotificationTypes.comment,
        payload: jsonEncode({
          'type': NotificationTypes.comment.name,
          'shopId': shopModel.shopId,
        }),
      );

      await NotificationCubit.instance.createNotification(
        receiverId: shopModel.shopId,
        receiverType: 'shop',
        title: "${currentUserModel.username} commented on your shop",
        body: comment,
        type: NotificationTypes.comment,
        payload: {'shopModel': shopModel.toMap()},
      );

      emit(CommentsSubmitRatingSuccessState());
    } catch (e) {
      log(e.toString());
      emit(CommentsSubmitRatingErrorState(error: e.toString()));
    }
  }

  void showShopCommentModal({
    required BuildContext context,
    required ShopModel shopModel,
  }) {
    final shopCommentsCache = commentsCache;

    // Load or initialize cached values
    final cached = shopCommentsCache[shopModel.shopId];
    final comments = cached?['comments']?.cast<String>() ?? [''];
    final ratings = cached?['ratings']?.cast<double>() ?? [0.0]; // default 0

    final TextEditingController commentController = TextEditingController(
      text: comments[0],
    );
    double currentRating = ratings[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: scaffoldColor,
      enableDrag: false,
      isDismissible: false,
      builder: (BuildContext context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              // Submit button state
              bool isSubmitEnabled() {
                return currentRating > 0 ||
                    commentController.text.trim().isNotEmpty;
              }

              void cacheValues() {
                shopCommentsCache[shopModel.shopId] = {
                  'comments': [commentController.text],
                  'ratings': [currentRating],
                };
              }

              return WillPopScope(
                onWillPop: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: Text(S.of(context).save_progress),
                        content: Text(S.of(context).save_review_as_draft_tip),
                        actions: [
                          TextButton(
                            onPressed: () {
                              if (!context.mounted) return;
                              Navigator.of(ctx).pop(false);
                            },
                            child: Text(S.of(context).discard),
                          ),
                          TextButton(
                            onPressed: () {
                              if (!context.mounted) return;
                              Navigator.of(ctx).pop(false);
                            },
                            child: Text(S.of(context).keep),
                          ),
                        ],
                      );
                    },
                  );

                  if (result == true) {
                    cacheValues();
                  } else {
                    shopCommentsCache.remove(shopModel.shopId);
                  }

                  return result != null;
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 40,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        S.of(context).write_your_review,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Rating Bar
                      RatingBar(
                        glowColor: primaryColor,
                        initialRating: currentRating,
                        minRating: 0,
                        allowHalfRating: true,
                        direction: Axis.horizontal,
                        itemCount: 5,
                        ratingWidget: RatingWidget(
                          full: const Icon(
                            CupertinoIcons.star_fill,
                            color: primaryColor,
                          ),
                          half: const Icon(
                            CupertinoIcons.star_lefthalf_fill,
                            color: primaryColor,
                          ),
                          empty: const Icon(
                            CupertinoIcons.star,
                            color: primaryColor,
                          ),
                        ),
                        itemPadding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            currentRating = rating;
                            cacheValues();
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // Comment TextField
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: TextFormField(
                          controller: commentController,

                          decoration: InputDecoration(
                            labelText: S.of(context).write_your_review,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                          onChanged: (_) => setState(() {
                            cacheValues();
                          }),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              isSubmitEnabled() ? primaryColor : Colors.grey,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              Colors.white,
                            ),
                          ),
                          onPressed: isSubmitEnabled()
                              ? () async {
                                  final comment = commentController.text.trim();
                                  if (comment.isEmpty && currentRating == 0) {
                                    return;
                                  }

                                  await submitShopComment(
                                    shopModel: shopModel,
                                    comment: comment,
                                    rating: currentRating,
                                  );

                                  shopCommentsCache.remove(shopModel.shopId);

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                }
                              : null,
                          child: Text(
                            S.of(context).submit,
                            style: const TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
