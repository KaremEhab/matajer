import 'package:flutter/material.dart';

class ResponsiveSpacing extends StatelessWidget {
  final double? heightFactor;
  final double? widthFactor;
  final double? fixedHeight;
  final double? fixedWidth;
  final ResponsiveSpacingType? basedOn;

  const ResponsiveSpacing({
    super.key,
    this.heightFactor,
    this.widthFactor,
    this.fixedHeight,
    this.fixedWidth,
    this.basedOn,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    double height = 0;
    double width = 0;

    if (fixedHeight != null) {
      height = fixedHeight!;
    } else if (heightFactor != null) {
      switch (basedOn) {
        case ResponsiveSpacingType.minDimension:
          height =
              heightFactor! *
              (media.size.width < media.size.height
                  ? media.size.width
                  : media.size.height);
          break;
        case ResponsiveSpacingType.maxDimension:
          height =
              heightFactor! *
              (media.size.width > media.size.height
                  ? media.size.width
                  : media.size.height);
          break;
        case ResponsiveSpacingType.width:
          height = heightFactor! * media.size.width;
          break;
        case ResponsiveSpacingType.height:
        default:
          height = heightFactor! * media.size.height;
          break;
      }
    }

    if (fixedWidth != null) {
      width = fixedWidth!;
    } else if (widthFactor != null) {
      switch (basedOn) {
        case ResponsiveSpacingType.minDimension:
          width =
              widthFactor! *
              (media.size.width < media.size.height
                  ? media.size.width
                  : media.size.height);
          break;
        case ResponsiveSpacingType.maxDimension:
          width =
              widthFactor! *
              (media.size.width > media.size.height
                  ? media.size.width
                  : media.size.height);
          break;
        case ResponsiveSpacingType.height:
          width = widthFactor! * media.size.height;
          break;
        case ResponsiveSpacingType.width:
        default:
          width = widthFactor! * media.size.width;
          break;
      }
    }

    return SizedBox(height: height, width: width);
  }
}

enum ResponsiveSpacingType { height, width, minDimension, maxDimension }
