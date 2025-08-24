import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';

class FavoriteHeartIcon extends StatefulWidget {
  final bool isFavorited, hasBorder;
  final double iconSize, padding, radius;
  final VoidCallback onTap;
  final Color color;

  const FavoriteHeartIcon({
    super.key,
    required this.isFavorited,
    this.hasBorder = false,
    this.iconSize = 23,
    this.padding = 9,
    this.radius = 200,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  State<FavoriteHeartIcon> createState() => _FavoriteHeartIconState();
}

class _FavoriteHeartIconState extends State<FavoriteHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    if (widget.isFavorited) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant FavoriteHeartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🎯 لما القيمة تتغير من خارج الـ widget
    if (widget.isFavorited != oldWidget.isFavorited) {
      if (widget.isFavorited) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap(); // مفيش setState هنا
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: widget.color,
        borderRadius: BorderRadius.circular(widget.radius),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(widget.radius),
          child: Container(
            padding: EdgeInsets.all(widget.padding),
            decoration:
                widget.hasBorder
                    ? BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.radius),
                      border: Border.all(
                        color: textColor.withOpacity(0.2),
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    )
                    : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  IconlyLight.heart,
                  color: primaryColor,
                  size: widget.iconSize,
                ),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Icon(
                    IconlyBold.heart,
                    color: primaryColor,
                    size: widget.iconSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
