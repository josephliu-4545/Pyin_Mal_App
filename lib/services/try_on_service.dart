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

  // Optional catalog context per garment slot. Set when a slot is filled from a
  // real product (not a raw gallery upload), so the size-fit check can look up
  // that item's chart and the chosen size. Null → no size check for that slot.
  String? shirtProductId;
  String? shirtSize;

  String? pantsProductId;
  String? pantsSize;

  String? shoesProductId;
  String? shoesSize;

  void clear() {
    userPhoto = null;
    userPhotoBytes = null;
    shirtPhoto = null;
    shirtPhotoBytes = null;
    pantsPhoto = null;
    pantsPhotoBytes = null;
    shoesPhoto = null;
    shoesPhotoBytes = null;
    shirtProductId = null;
    shirtSize = null;
    pantsProductId = null;
    pantsSize = null;
    shoesProductId = null;
    shoesSize = null;
  }
}
