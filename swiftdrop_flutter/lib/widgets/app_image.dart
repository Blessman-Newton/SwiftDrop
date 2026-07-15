import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/food_images.dart';

class AppImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  /// When set, a missing/broken network image falls back to a bundled food
  /// photo chosen from this seed (usually the dish or restaurant name) instead
  /// of a broken-image icon.
  final String? fallbackSeed;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.fallbackSeed,
  });

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: backgroundColor ?? const Color(0xFFE8F5E9),
          child: Center(
            child: Icon(
              Icons.restaurant,
              color: const Color(0xFF006C49).withOpacity(0.3),
              size: 32,
            ),
          ),
        );
  }

  Widget _buildError() {
    // Prefer a bundled food photo when a seed is provided.
    if (fallbackSeed != null) {
      return Image.asset(
        FoodImages.forName(fallbackSeed),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildIconError(),
      );
    }
    return errorWidget ?? _buildIconError();
  }

  Widget _buildIconError() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? const Color(0xFFF4FBF4),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Color(0xFF9CA3AF),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty || !url.startsWith('http')) {
      return _buildError();
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => _buildPlaceholder(),
      errorWidget: (_, __, ___) => _buildError(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

class AppAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final String fallbackLetter;
  final Color? backgroundColor;
  final Color? textColor;

  const AppAvatar({
    super.key,
    this.url,
    this.size = 48,
    this.fallbackLetter = '?',
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF006C49);
    final txtColor = textColor ?? Colors.white;

    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: bgColor,
            child: Center(
              child: Text(
                fallbackLetter,
                style: TextStyle(
                  color: txtColor,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: size,
            height: size,
            color: bgColor,
            child: Center(
              child: Text(
                fallbackLetter,
                style: TextStyle(
                  color: txtColor,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          fallbackLetter,
          style: TextStyle(
            color: txtColor,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
