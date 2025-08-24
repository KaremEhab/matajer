import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';

class AnimatedCategoryItem extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget icon;
  final String text;

  const AnimatedCategoryItem({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.text,
  });

  @override
  State<AnimatedCategoryItem> createState() => _AnimatedCategoryItemState();
}

class _AnimatedCategoryItemState extends State<AnimatedCategoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _radiusAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // 🔥 Trigger the animation if the item is selected by default
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCategoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(22));
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _radiusAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: CircleFillPainter(
                    progress: _radiusAnimation.value,
                    color: primaryColor,
                  ),
                  child: SizedBox(
                    width: 75, // عرض العنصر جوه الليست
                    height: 105, // نفس ارتفاع العنصر
                  ),
                );
              },
            ),
            Container(
              // width: 90.w,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 0.6,
                ),
              ),
              child: Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: formFieldColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(child: widget.icon),
                  ),
                  Flexible(
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            widget.isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                        color: widget.isSelected ? Colors.white : textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleFillPainter extends CustomPainter {
  final double progress; // 0 to 1
  final Color color;

  CircleFillPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.longestSide * 1.2 * progress;

    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleFillPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
