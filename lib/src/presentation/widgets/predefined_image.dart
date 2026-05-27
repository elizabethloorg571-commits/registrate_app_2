import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/src/utils/http_utils.dart';

class PredefinedImage extends StatefulWidget {
  final String imgUrl;
  final String imgId;
  final String imgAsset;
  final bool circular;
  final String? cacheKey;
  final bool removeBackground;
  final BoxFit fit;

  const PredefinedImage({
    super.key,
    required this.imgUrl,
    required this.imgId,
    required this.imgAsset,
    this.fit = BoxFit.fill,
    this.circular = false,
    this.removeBackground = false,
    this.cacheKey,
  });

  @override
  State<PredefinedImage> createState() => _PredefinedImageState();
}

class _PredefinedImageState extends State<PredefinedImage> {
  bool? _resourceExists;

  @override
  void initState() {
    super.initState();
    _checkImage();
  }

  Future<void> _checkImage() async {
    if (widget.imgUrl.isEmpty) {
      setState(() => _resourceExists = false);
    } else {
      final exists = await HttpUtils.checkResourceExistsCached(widget.imgUrl);
      if (mounted) {
        setState(() => _resourceExists = exists);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.circular ? BoxShape.circle : BoxShape.rectangle;
    final padding = widget.circular ? const EdgeInsets.all(5) : null;

    if (_resourceExists == null) {
      return Container(
        decoration: BoxDecoration(
          color: widget.removeBackground
              ? Colors.transparent
              : widget.imgAsset.contains("fan_app_user")
              ? AppTheme.lightModeBlue
              : AppTheme.white950,
          shape: shape,
          image: DecorationImage(
            image: AssetImage(widget.imgAsset),
            fit: widget.fit,
          ),
        ),
      );
    }

    if (_resourceExists == true) {
      return Container(
        decoration: BoxDecoration(
          color: widget.removeBackground
              ? Colors.transparent
              : AppTheme.white950,
          shape: shape,
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              widget.imgUrl,
              cacheKey: widget.cacheKey ?? widget.imgId,
            ),
            fit: widget.fit,
          ),
        ),
      );
    } else {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: widget.removeBackground
              ? Colors.transparent
              : widget.imgAsset.contains("fan_app_user")
              ? AppTheme.lightModeBlue
              : AppTheme.white950,
          shape: shape,
          image: DecorationImage(
            image: AssetImage(widget.imgAsset),
            fit: widget.fit,
          ),
        ),
      );
    }
  }
}
