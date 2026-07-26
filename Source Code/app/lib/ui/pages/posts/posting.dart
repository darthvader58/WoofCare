import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/services/post_media_service.dart';
import 'package:woofcare/ui/widgets/responsive.dart';
import 'package:woofcare/ui/widgets/video_preview_controller.dart';

import '/config/constants.dart';
import '/ui/widgets/custom_button.dart';
import '/ui/widgets/custom_textfield.dart';

class PostingPage extends StatefulWidget {
  final ScrollController scrollController;

  const PostingPage({super.key, required this.scrollController});

  @override
  State<PostingPage> createState() => _PostingPageState();
}

class _PostingPageState extends State<PostingPage> {
  final currUser = AUTH.currentUser!;
  final _postTextController = TextEditingController();
  final _linkController = TextEditingController();

  final List<XFile> _images = [];
  XFile? _video;
  VideoPlayerController? _videoPreviewController;

  bool _isPosting = false;
  String? _uploadStatus;

  @override
  void dispose() {
    _postTextController.dispose();
    _linkController.dispose();
    _videoPreviewController?.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _postTextController.text.trim().isNotEmpty ||
      _images.isNotEmpty ||
      _video != null ||
      _linkController.text.trim().isNotEmpty;

  Future<void> _pickImagesFromGallery() async {
    final remaining = PostMediaService.maxImagesPerPost - _images.length;
    if (remaining <= 0) return;

    final picked = await PostMediaService.pickImagesFromGallery(
      remainingSlots: remaining,
    );
    if (!mounted || picked.isEmpty) return;
    setState(() => _images.addAll(picked));
  }

  Future<void> _pickImageFromCamera() async {
    if (_images.length >= PostMediaService.maxImagesPerPost) return;

    final picked = await PostMediaService.pickImageFromCamera();
    if (!mounted || picked == null) return;
    setState(() => _images.add(picked));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _setVideo(XFile? video) async {
    if (video == null) return;

    final controller = createVideoPreviewController(video);
    try {
      await controller.initialize();
    } catch (_) {
      controller.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to preview this video.')),
        );
      }
      return;
    }
    if (!mounted) {
      controller.dispose();
      return;
    }

    setState(() {
      _videoPreviewController?.dispose();
      _video = video;
      _videoPreviewController = controller;
    });
  }

  void _removeVideo() {
    setState(() {
      _videoPreviewController?.dispose();
      _videoPreviewController = null;
      _video = null;
    });
  }

  Future<void> _showMediaSourceSheet({
    required String title,
    required VoidCallback onGallery,
    required VoidCallback onCamera,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: WoofCareColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return WoofCareSheetSurface(
          maxWidth: 480,
          child: Material(
            color: WoofCareColors.secondaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WoofCareColors.buttonColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_outlined,
                      color: WoofCareColors.primaryTextAndIcons,
                    ),
                    title: Text(
                      title == 'Video'
                          ? 'Choose from gallery'
                          : 'Choose photos',
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onGallery();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt_outlined,
                      color: WoofCareColors.primaryTextAndIcons,
                    ),
                    title: const Text('Use camera'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onCamera();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> postMessage() async {
    if (!_hasContent || _isPosting) return;

    setState(() {
      _isPosting = true;
      _uploadStatus = null;
    });

    try {
      final postRef = FIRESTORE.collection('posts').doc();

      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        setState(() => _uploadStatus = 'Uploading photos...');
        imageUrls = await PostMediaService.uploadImages(
          images: _images,
          uid: currUser.uid,
          postId: postRef.id,
        );
      }

      String? videoUrl;
      if (_video != null) {
        setState(() => _uploadStatus = 'Uploading video...');
        videoUrl = await PostMediaService.uploadVideo(
          video: _video!,
          uid: currUser.uid,
          postId: postRef.id,
        );
      }

      final link = _linkController.text.trim();

      await postRef.set({
        'email': currUser.email,
        'message': _postTextController.text.trim(),
        'timestamp': Timestamp.now(),
        'likes': [],
        'images': imageUrls,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (link.isNotEmpty) 'link': link,
      });

      if (mounted) Navigator.pop(context);
    } on PostMediaUploadException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: WoofCareColors.errorMessageColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $error'),
            backgroundColor: WoofCareColors.errorMessageColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _uploadStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WoofCareColors.secondaryBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: IconButton(
                    onPressed: _isPosting ? null : () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: WoofCareColors.primaryTextAndIcons,
                    ),
                    tooltip: "Back",
                  ),
                ),
                CustomButton(
                  text: _isPosting ? 'Posting...' : 'Post',
                  fontSize: 12,
                  verticalPadding: 12,
                  horizontalPadding: 40,
                  margin: 10,
                  fontWeight: FontWeight.w200,
                  onTap: (_hasContent && !_isPosting) ? postMessage : null,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              spacing: 10.0,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFCAB096),
                  child: Icon(
                    Icons.person,
                    color: WoofCareColors.primaryTextAndIcons,
                  ),
                ),
                Text(
                  "${AUTH.currentUser!.email}",
                  style: TextStyle(color: WoofCareColors.primaryTextAndIcons),
                ),
              ],
            ),
          ),

          CustomTextField(
            controller: _postTextController,
            keyboardType: TextInputType.multiline,
            autofocus: true,
            hintText: "What's on your mind?",
            horizontalPadding: 0,
            minLines: 6,
            maxLines: 10,
            top: 15,
            bottom: 15,
          ),

          if (_video != null) ...[
            const SizedBox(height: 16),
            _VideoPreview(
              controller: _videoPreviewController,
              onRemove: _isPosting ? null : _removeVideo,
            ),
          ],

          if (_images.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ImagePreviewStrip(
              images: _images,
              onRemove: _isPosting ? null : _removeImage,
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              _MediaPickerButton(
                icon: Icons.image_outlined,
                label: 'Photo',
                enabled:
                    !_isPosting &&
                    _images.length < PostMediaService.maxImagesPerPost,
                onTap: () => _showMediaSourceSheet(
                  title: 'Photo',
                  onGallery: _pickImagesFromGallery,
                  onCamera: _pickImageFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              _MediaPickerButton(
                icon: Icons.videocam_outlined,
                label: 'Video',
                enabled: !_isPosting && _video == null,
                onTap: () => _showMediaSourceSheet(
                  title: 'Video',
                  onGallery: () async {
                    final picked =
                        await PostMediaService.pickVideoFromGallery();
                    await _setVideo(picked);
                  },
                  onCamera: () async {
                    final picked = await PostMediaService.pickVideoFromCamera();
                    await _setVideo(picked);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          CustomTextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            hintText: 'Add a link (optional)',
            prefix: Icons.link,
            horizontalPadding: 0,
          ),

          if (_uploadStatus != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  _uploadStatus!,
                  style: TextStyle(color: WoofCareColors.primaryTextAndIcons),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _MediaPickerButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: WoofCareColors.offWhite,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: WoofCareColors.primaryTextAndIcons),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: WoofCareColors.primaryTextAndIcons,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreviewStrip extends StatelessWidget {
  final List<XFile> images;
  final void Function(int index)? onRemove;

  const _ImagePreviewStrip({required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _XFileImagePreview(file: images[index]),
              ),
              if (onRemove != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: () => onRemove!(index),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: WoofCareColors.errorMessageColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _XFileImagePreview extends StatefulWidget {
  final XFile file;

  const _XFileImagePreview({required this.file});

  @override
  State<_XFileImagePreview> createState() => _XFileImagePreviewState();
}

class _XFileImagePreviewState extends State<_XFileImagePreview> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.file.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant _XFileImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _bytes = widget.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          if (snapshot.hasError) {
            return const ColoredBox(
              color: WoofCareColors.textBoxColor,
              child: Icon(
                Icons.broken_image_outlined,
                color: WoofCareColors.primaryTextAndIcons,
              ),
            );
          }
          return const ColoredBox(
            color: WoofCareColors.textBoxColor,
            child: Center(
              child: CircularProgressIndicator(
                color: WoofCareColors.buttonColor,
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final VoidCallback? onRemove;

  const _VideoPreview({required this.controller, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 180,
            color: Colors.black,
            child: ready
                ? AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: VideoPlayer(controller!),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
        ),
        if (ready)
          Positioned.fill(
            child: Center(
              child: IconButton(
                iconSize: 44,
                color: Colors.white,
                icon: Icon(
                  controller!.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                ),
                onPressed: () {
                  controller!.value.isPlaying
                      ? controller!.pause()
                      : controller!.play();
                },
              ),
            ),
          ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: WoofCareColors.errorMessageColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
