import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/comments/comments_cubit.dart';
import 'package:matajer/cubit/comments/comments_state.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/shop/comments_appBar.dart';
import 'package:matajer/widgets/expandable_text.dart';
import 'package:matajer/widgets/half_filled_icon.dart';

class ShopComments extends StatefulWidget {
  const ShopComments({super.key, required this.shopModel});

  final ShopModel shopModel;

  @override
  State<ShopComments> createState() => _ShopCommentsState();
}

class _ShopCommentsState extends State<ShopComments>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<double> scrollOffsetNotifier = ValueNotifier(0);
  final ScrollController _scrollController = ScrollController();
  int totalComments = 0;
  // bool display = false;

  @override
  bool get wantKeepAlive => true; // ✅ Keeps the state alive

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      scrollOffsetNotifier.value = _scrollController.offset;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to use context here for inherited widgets
    // CommentsCubit.get(context).getCommentsByShopId(widget.shopModel.shopId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    scrollOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: BlocConsumer<CommentsCubit, CommentsState>(
        listener: (context, state) {
          // if (state is CommentsSuccessState) {
          //   display = !display;
          // }
        },
        builder: (context, state) {
          final comments = CommentsCubit.get(context).comments;
          final totalRatings = comments.length;

          // Calculate average rating (avoid division by zero)
          final averageRating = totalRatings == 0
              ? 0
              : comments.map((r) => r.rating).reduce((a, b) => a + b) /
                    totalRatings;

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              CommentsAppBar(
                totalRatings: totalRatings,
                shopModel: widget.shopModel,
                commentsScrollOffsetNotifier: scrollOffsetNotifier,
              ),

              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ★★★★★ row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final filled = index < averageRating.floor();
                              final half =
                                  index + 1 > averageRating &&
                                  index < averageRating;
                              if (filled) {
                                return Icon(
                                  IconlyBold.star,
                                  size: 30,
                                  color: Colors.amber,
                                );
                              } else if (half) {
                                return HalfFilledStarIcon(
                                  size: 30,
                                  color: Colors.amber,
                                );
                              } else {
                                return Icon(
                                  IconlyLight.star,
                                  size: 30,
                                  color: Colors.amber,
                                );
                              }
                            }),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              '${S.of(context).based_on_the_previous} ($totalRatings) ${totalRatings == 1 ? S.of(context).rating : S.of(context).ratings}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Star Summary Breakdown
              SliverPadding(
                padding: EdgeInsetsGeometry.only(top: 0),
                sliver: SliverList.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final comment = CommentsCubit.get(context).comments;

                    int star = 5 - index; // Show 5-star first, then 4, etc.
                    int totalComments = comment.length;

                    // Count how many users gave this exact rounded rating
                    int count = comment
                        .where((r) => r.rating.round() == star)
                        .length;

                    // Calculate progress bar percent
                    double percent = totalComments == 0
                        ? 0
                        : count / totalComments;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text('$star'),
                          Icon(IconlyBold.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: secondaryColor,
                                color: primaryColor,
                                minHeight: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('$count'),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Divider(
                    color: primaryColor.withOpacity(0.1),
                    thickness: 7,
                  ),
                ),
              ),

              CommentsCubit.get(context).comments.isEmpty
                  ? SliverToBoxAdapter(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 60),
                          SvgPicture.asset(
                            'images/no-reviews.svg',
                            height: 250,
                          ),
                          Text(
                            "No comments has been added yet",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SliverList.builder(
                      itemCount: CommentsCubit.get(context).comments.length,
                      itemBuilder: (context, index) {
                        final comment = CommentsCubit.get(
                          context,
                        ).comments[index];

                        return Center(
                          child: FutureBuilder<UserModel>(
                            future: UserCubit.get(
                              context,
                            ).getUserInfoById(comment.userId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return commentShimmer();
                              }

                              final user = snapshot.data!;

                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  10,
                                  10,
                                  16,
                                ),
                                child: Column(
                                  spacing: 10,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Profile + Name + Emirate + Rating + Time
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: CircleAvatar(
                                            radius: 22,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              child: CachedNetworkImage(
                                                imageUrl: user.profilePicture
                                                    .toString(),
                                                progressIndicatorBuilder:
                                                    (context, url, progress) =>
                                                        shimmerPlaceholder(
                                                          height: 140,
                                                          width: 140,
                                                          radius: 100,
                                                        ),
                                                height: 140,
                                                width: 140,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.username,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                user.emirate,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              children: List.generate(5, (i) {
                                                if (i <
                                                    comment.rating.floor()) {
                                                  return Icon(
                                                    IconlyBold.star,
                                                    size: 20,
                                                    color: Colors.amber,
                                                  );
                                                } else if (i ==
                                                        comment.rating
                                                            .floor() &&
                                                    comment.rating -
                                                            comment.rating
                                                                .floor() >=
                                                        0.5) {
                                                  return HalfFilledStarIcon(
                                                    size: 20,
                                                    color: Colors.amber,
                                                  );
                                                } else {
                                                  return Icon(
                                                    IconlyLight.star,
                                                    size: 20,
                                                    color: Colors.amber,
                                                  );
                                                }
                                              }),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('d MMM yyyy').format(
                                                comment.createdAt.toDate(),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Comment
                                    CustomExpandableRichText(
                                      textWidth: double.infinity,
                                      textHeight: 1.5,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      maxLines: 3,
                                      text: comment.comment,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

              SliverToBoxAdapter(child: SizedBox(height: 210)),
            ],
          );
        },
      ),
      floatingActionButton:
          currentUserModel.shopsVisibleToComment.contains(
            widget.shopModel.shopId,
          )
          ? FloatingActionButton(
              shape: CircleBorder(),
              onPressed: () {
                CommentsCubit.get(context).showShopCommentModal(
                  context: context,
                  shopModel: widget.shopModel,
                );
              },
              backgroundColor: primaryColor,
              child: Icon(IconlyLight.chat, color: Colors.white),
            )
          : null,
    );
  }
}

Widget commentShimmer() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Avatar + Name/Location + Stars/Date
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar shimmer
            Container(
              padding: EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: shimmerPlaceholder(height: 44, width: 44, radius: 100),
              ),
            ),
            const SizedBox(width: 10),
            // Username & emirate
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shimmerPlaceholder(width: 100, height: 16, radius: 4),
                  const SizedBox(height: 4),
                  shimmerPlaceholder(width: 60, height: 13, radius: 4),
                ],
              ),
            ),
            // Stars & Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: shimmerPlaceholder(
                        width: 16,
                        height: 16,
                        radius: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                shimmerPlaceholder(width: 80, height: 12, radius: 4),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Comment shimmer (3 lines)
        shimmerPlaceholder(width: double.infinity, height: 14, radius: 6),
        const SizedBox(height: 8),
        shimmerPlaceholder(width: double.infinity * 0.8, height: 14, radius: 6),
        const SizedBox(height: 8),
        shimmerPlaceholder(width: double.infinity * 0.6, height: 14, radius: 6),
      ],
    ),
  );
}
