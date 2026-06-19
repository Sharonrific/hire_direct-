// lib/presentation/screens/shared/image_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../core/theme/app_theme.dart';

class ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late int _current;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageCtrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        builder: (context, i) => PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(widget.images[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
