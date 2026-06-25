import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class TryOnService {
  static final TryOnService _instance = TryOnService._internal();
  factory TryOnService() => _instance;
  TryOnService._internal();

  static TryOnService get instance => _instance;

  XFile? userPhoto;
  Uint8List? userPhotoBytes;

  XFile? shirtPhoto;
  Uint8List? shirtPhotoBytes;

  XFile? pantsPhoto;
  Uint8List? pantsPhotoBytes;

  XFile? shoesPhoto;
  Uint8List? shoesPhotoBytes;

  void clear() {
    userPhoto = null;
    userPhotoBytes = null;
    shirtPhoto = null;
    shirtPhotoBytes = null;
    pantsPhoto = null;
    pantsPhotoBytes = null;
    shoesPhoto = null;
    shoesPhotoBytes = null;
  }
}
