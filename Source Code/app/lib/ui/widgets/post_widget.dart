import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/config/constants.dart';
import 'package:woofcare/ui/widgets/thumbs_up_widget.dart';

class Post extends StatelessWidget {
  final String message;
  final String user;
  final String time;
  final String postId;
  final List<String> usersWhoLiked;

  const Post({
    super.key,
    required this.message,
    required this.user,
    required this.time,
    required this.postId,
    required this.usersWhoLiked,
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
