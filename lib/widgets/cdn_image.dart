import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/api_constants.dart';

class CdnImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? color;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CdnImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.color,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Already a full URL (e.g. a user-uploaded resell/OOTD photo hosted on
    // Cloudinary/imgbb) — load it directly instead of prefixing the CDN base.
    if (assetPath.startsWith('http://') || assetPath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: assetPath,
        width: width,
        height: height,
        fit: fit,
        color: color,
        placeholder: (context, url) => SizedBox(
          width: width,
          height: height,
          child: const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
          ),
        ),
        errorWidget: (context, url, error) {
          if (errorBuilder != null) {
            return errorBuilder!(context, error ?? 'Error', StackTrace.empty);
          }
          return SizedBox(
            width: width,
            height: height,
            child:
                const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          );
        },
      );
    }

    // Local bundled assets — use Image.asset directly
    if (assetPath.contains('logo') || assetPath.contains('splash') ||
        assetPath.startsWith('pyin-mal-assets/') ||
        assetPath.startsWith('assets/clothes/') ||
        assetPath.startsWith('assets/models/')) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        color: color,
        errorBuilder: (ctx, err, stack) {
          debugPrint('🖼️ Asset failed: $assetPath | $err');
          if (errorBuilder != null) return errorBuilder!(ctx, err, stack);
          return const SizedBox.shrink();
        },
      );
    }

    // Convert asset path to CDN path
    final String cdnPath = assetPath.replaceFirst('assets/images/', '');
    final String fullUrl = '${ApiConstants.cdnBaseUrl}$cdnPath';

    return CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      placeholder: (context, url) => SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      ),
      errorWidget: (context, url, error) {
        if (errorBuilder != null) {
          // CachedNetworkImage errorWidget passes the error as dynamic, 
          // we cast it or pass a standard string if it's null.
          return errorBuilder!(context, error ?? 'Error', StackTrace.empty);
        }
        return SizedBox(
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        );
      },
    );
  }
}
