import 'dart:typed_data';

/// A single pre-loved item listed in the Resell marketplace.
///
/// Two flavours share this model:
///  • **Demo seed items** — hardcoded showcase listings. They have an empty
///    [id]/[sellerId] and their photo lives in [image] (a bundled asset path).
///  • **Real user posts** — stored in the `resellPosts` Firestore collection.
///    They carry a Firestore doc [id], the author's [sellerId], and a hosted
///    photo URL in [imageUrl]. [imageBytes] is only used for the brief optimistic
///    preview while a freshly-picked photo is still uploading.
class ResellPost {
  final String id; // Firestore doc id ('' for demo seed items)
  final String title;
  final String price;
  final String image; // bundled asset path (demo items)
  final String? imageUrl; // hosted photo URL (user posts)
  final Uint8List? imageBytes; // local preview before upload finishes
  final String condition; // Like New / Good / Fair
  final String seller;
  final String sellerId; // uid of the author ('' for demo items)
  final String size;
  final bool isSoldOut;

  const ResellPost({
    this.id = '',
    required this.title,
    required this.price,
    this.image = '',
    this.imageUrl,
    this.imageBytes,
    required this.condition,
    required this.seller,
    this.sellerId = '',
    required this.size,
    this.isSoldOut = false,
  });

  /// True when this listing was posted by the signed-in user [uid].
  bool isMineFor(String? uid) =>
      uid != null && sellerId.isNotEmpty && sellerId == uid;

  /// Best image source to display: the hosted URL when present, otherwise the
  /// bundled asset path. (Callers show [imageBytes] first when it's non-null.)
  String get displaySrc =>
      (imageUrl != null && imageUrl!.isNotEmpty) ? imageUrl! : image;

  ResellPost copyWith({bool? isSoldOut}) => ResellPost(
        id: id,
        title: title,
        price: price,
        image: image,
        imageUrl: imageUrl,
        imageBytes: imageBytes,
        condition: condition,
        seller: seller,
        sellerId: sellerId,
        size: size,
        isSoldOut: isSoldOut ?? this.isSoldOut,
      );

  factory ResellPost.fromMap(Map<String, dynamic> data, String id) {
    return ResellPost(
      id: id,
      title: data['title'] as String? ?? '',
      price: data['price'] as String? ?? '',
      image: data['image'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      condition: data['condition'] as String? ?? 'Good',
      seller: data['seller'] as String? ?? 'Someone',
      sellerId: data['sellerId'] as String? ?? '',
      size: data['size'] as String? ?? 'One size',
      isSoldOut: data['isSoldOut'] as bool? ?? false,
    );
  }
}
