// ignore_for_file: avoid_print


import 'package:image_picker/image_picker.dart';

class ImagePickerUtils {
  static Future<XFile?> galleryOneImagePicker() async {
    try {
      XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      return image;
    } catch (e) {
      print("Error picking image from gallery: $e");
      return null;
    }
  }

  static Future<List<XFile>> galleryImagePicker() async {
    try {
      List<XFile>? images = await ImagePicker().pickMultiImage();

      return images;
    } catch (e) {
      print("Error picking images: $e");
      return [];
    }
  }

  static Future<XFile?> cameraImagePicker() async {
    try {
      XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );

      return image;
    } catch (e) {
      print("Error picking image from camera: $e");
      return null;
    }
  }

  static Future<XFile?> videoPicker() async {
    try {
      XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );

      return video;
    } catch (e) {
      print("Error picking video: $e");
      return null;
    }
  }

  static Future<XFile?> cameraVideoPicker() async {
    try {
      XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.camera,
      );

      return video;
    } catch (e) {
      print("Error capturing video from camera: $e");
      return null;
    }
  }
}
