import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';

class PickImageSource extends StatelessWidget {
  const PickImageSource({
    super.key,
    required this.galleryButton,
    required this.cameraButton,
  });

  final void Function() galleryButton, cameraButton;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(IconlyBold.camera, color: primaryColor, size: 35),
            title: Text(S.of(context).take_photo),
            trailing: Icon(forwardIcon(), color: textColor.withOpacity(0.7)),
            onTap: cameraButton,
          ),
          SizedBox(height: 10),
          ListTile(
            leading: Icon(IconlyBold.image, color: primaryColor, size: 35),
            title: Text(S.of(context).choose_from_gallery),
            trailing: Icon(forwardIcon(), color: textColor.withOpacity(0.7)),
            onTap: galleryButton,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
