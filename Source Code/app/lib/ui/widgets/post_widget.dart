import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/config/constants.dart';
import 'package:woofcare/ui/widgets/thumbs_up_widget.dart';

class Post extends StatelessWidget {
  final String message;
  final String user;
  final String time;
  final String postId;
  final List<String> usersWhoLiked;
  final List<String> images;
  final String? videoUrl;
  final String? link;

  const Post({
    super.key,
    required this.message,
    required this.user,
    required this.time,
    required this.postId,
    required this.usersWhoLiked,
    this.images = const [],
    this.videoUrl,
    this.link,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: WoofCareColors.offWhite,
          border: Border.all(
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PostHeader(user: user, time: time),
              if (message.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: WoofCareColors.primaryTextAndIcons,
                      fontSize: 17,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                const SizedBox(height: 6),
              if (videoUrl != null && videoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: _PostVideo(url: videoUrl!),
                ),
              if (images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: _PostImages(images: images),
                ),
              if (link != null && link!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: _PostLinkCard(url: link!),
                ),
              Container(
                height: 1,
                color: WoofCareColors.primaryTextAndIcons.withValues(
                  alpha: 0.08,
                ),
              ),
              _PostActions(postId: postId, usersWhoLiked: usersWhoLiked),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostImages extends StatelessWidget {
  final List<String> images;

  const _PostImages({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            images.first,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => const _MediaErrorPlaceholder(),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              images[index],
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const SizedBox(
                        width: 140,
                        height: 140,
                        child: _MediaErrorPlaceholder(),
                      ),
            ),
          );
        },
      ),
    );
  }
}

class _MediaErrorPlaceholder extends StatelessWidget {
  const _MediaErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WoofCareColors.backgroundElementColor.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: WoofCareColors.primaryTextAndIcons,
      ),
    );
  }
}

class _PostVideo extends StatefulWidget {
  final String url;

  const _PostVideo({required this.url});

  @override
  State<_PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<_PostVideo> {
  VideoPlayerController? _controller;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startPlayback() async {
    setState(() => _isLoading = true);
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: controller?.value.isInitialized == true
            ? controller!.value.aspectRatio
            : 16 / 10,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (controller != null && controller.value.isInitialized)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                  child: VideoPlayer(controller),
                )
              else if (_hasError)
                const _MediaErrorPlaceholder()
              else if (_isLoading)
                const CircularProgressIndicator(color: Colors.white)
              else
                IconButton(
                  iconSize: 52,
                  color: Colors.white,
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: _startPlayback,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostLinkCard extends StatelessWidget {
  final String url;

  const _PostLinkCard({required this.url});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WoofCareColors.buttonColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openLink(context, url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: WoofCareColors.buttonColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WoofCareColors.buttonColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: WoofCareColors.buttonColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String value) async {
    var uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      uri = Uri.tryParse('https://${value.trim()}');
    }
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open this link')));
    }
  }
}

class _PostHeader extends StatelessWidget {
  final String user;
  final String time;

  const _PostHeader({required this.user, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WoofCareColors.backgroundElementColor,
              border: Border.all(color: WoofCareColors.offWhite, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _initialsFor(user),
              style: const TextStyle(
                color: WoofCareColors.primaryTextAndIcons,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayNameFor(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WoofCareColors.primaryTextAndIcons,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WoofCareColors.primaryTextAndIcons.withValues(
                      alpha: 0.58,
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: WoofCareColors.floatingActionIcons.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Community',
              style: TextStyle(
                color: WoofCareColors.floatingActionIcons,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayNameFor(String value) {
    final localPart = value.split('@').first.trim();
    if (localPart.isEmpty) return 'Community Member';

    return localPart
        .split(RegExp(r'[._\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _initialsFor(String value) {
    final displayName = _displayNameFor(value);
    final parts = displayName.split(' ').where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0]).join();
  }
}

class _PostActions extends StatelessWidget {
  final String postId;
  final List<String> usersWhoLiked;

  const _PostActions({required this.postId, required this.usersWhoLiked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: ThumbsUpButton(
                postId: postId,
                numOfLikes: usersWhoLiked.length,
                initiallyLiked: usersWhoLiked.contains(AUTH.currentUser?.email),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _SocialActionButton(
                icon: Icons.comment_outlined,
                label: 'Comment',
                onTap: () {},
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _SocialActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: WoofCareColors.primaryTextAndIcons,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
