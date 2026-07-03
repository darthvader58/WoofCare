import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/config/constants.dart';

class ThumbsUpButton extends StatefulWidget {
  final String postId;
  final int numOfLikes;
  final bool initiallyLiked;

  const ThumbsUpButton({
    super.key,
    required this.postId,
    required this.numOfLikes,
    this.initiallyLiked = false,
  });

  @override
  State<ThumbsUpButton> createState() => _ThumbsUpButtonState();
}

class _ThumbsUpButtonState extends State<ThumbsUpButton> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initiallyLiked;
  }

  void postLiked() {
    final currUser = AUTH.currentUser;
    if (currUser?.email == null) return;

    setState(() {
      isLiked = !isLiked;
    });

    // Get a reference from the post that holds the current thumbs up widget
    DocumentReference postRef = FIRESTORE
        .collection('posts')
        .doc(widget.postId);

    if (isLiked) {
      postRef.update({
        'likes': FieldValue.arrayUnion([currUser!.email]),
      });
    } else {
      postRef.update({
        'likes': FieldValue.arrayRemove([currUser!.email]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: postLiked,
      icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 19),
      label: Text(_likeLabel),
      style: TextButton.styleFrom(
        foregroundColor:
            isLiked
                ? WoofCareColors.buttonColor
                : WoofCareColors.primaryTextAndIcons,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  String get _likeLabel {
    if (widget.numOfLikes == 0) return 'Like';
    return widget.numOfLikes.toString();
  }
}
