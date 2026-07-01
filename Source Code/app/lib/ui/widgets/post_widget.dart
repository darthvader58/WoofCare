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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: WoofCareColors.secondaryBackground,
        boxShadow: [
          BoxShadow(
            color: WoofCareColors.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(user: user, time: time),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
            child: Text(
              message,
              style: const TextStyle(
                color: WoofCareColors.primaryTextAndIcons,
                fontSize: 16,
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.12),
          ),
          _PostActions(postId: postId, usersWhoLiked: usersWhoLiked),
        ],
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: WoofCareColors.backgroundElementColor,
            child: Text(
              _initialsFor(user),
              style: const TextStyle(
                color: WoofCareColors.primaryTextAndIcons,
                fontWeight: FontWeight.w800,
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
                    fontSize: 16,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: WoofCareColors.buttonColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Help',
              style: TextStyle(
                color: WoofCareColors.buttonColor,
                fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ThumbsUpButton(
            postId: postId,
            numOfLikes: usersWhoLiked.length,
            initiallyLiked: usersWhoLiked.contains(AUTH.currentUser?.email),
          ),
          _SocialActionButton(
            icon: Icons.comment_outlined,
            label: 'Comment',
            onTap: () {},
          ),
          _SocialActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {},
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
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
