import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/vars.dart';

class HalfFilledStarIcon extends StatelessWidget {
  final double size;
  final Color color;

  const HalfFilledStarIcon({
    super.key,
    this.size = 24,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(
          IconlyLight.star,
          size: size,
          color: color, // Outline base
        ),
        ClipRect(
          clipper: _HalfClipper(),
          child: Icon(
            IconlyBold.star,
            size: size,
            color: color, // Half fill
          ),
        ),
      ],
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    if (lang == 'ar') {
      // Fill right side in RTL
      return Rect.fromLTRB(size.width / 2, 0, size.width, size.height);
    } else {
      // Fill left side in LTR
      return Rect.fromLTRB(0, 0, size.width / 2, size.height);
    }
  }

  @override
  bool shouldReclip(_HalfClipper oldClipper) => false;
}
