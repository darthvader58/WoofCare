import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/config/constants.dart';
import 'package:woofcare/tools/functions.dart';
import 'package:woofcare/ui/pages/posts/posting.dart';
import 'package:woofcare/ui/widgets/app_chrome.dart';
import 'package:woofcare/ui/widgets/post_widget.dart';

class SocialMediaFeed extends StatefulWidget {
  const SocialMediaFeed({super.key});

  @override
  State<SocialMediaFeed> createState() => _SocialMediaFeedState();
}

class _SocialMediaFeedState extends State<SocialMediaFeed> {
  void _postButtonPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag:
          false, // Prevent dragging of the modal bottom sheet (instead cancel with "Cancel" button)
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: WoofCareColors.borderOutline.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      backgroundColor: WoofCareColors.secondaryBackground,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.95,
          maxChildSize: 0.95,
          builder: (sheetContext, scrollController) {
            return Container(
              // Container to store the drag handle and the ReportingPage
              decoration: const BoxDecoration(
                color: WoofCareColors.secondaryBackground,
              ),

              // Children of the container => drag handle and the ReportingPage
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // The ReportingPage (uses Expanded to take up the rest of the space)
                  Expanded(
                    child: SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(
                          left: 25,
                          right: 25,
                          top: 10,
                          bottom: 30,
                        ),
                        child: PostingPage(scrollController: scrollController),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WoofCareColors.primaryBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            WoofCareScreenHeader(
              title: 'Community',
              subtitle: 'Updates, sightings, and rescue support',
              height: 112,
              actions: [
                WoofCareProfileAvatar(
                  onTap: () => Navigator.pushNamed(context, "/profile"),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder(
                stream:
                    FIRESTORE
                        .collection("posts")
                        .orderBy("timestamp", descending: true)
                        .snapshots(),

                builder: (context, snapshot) {
                  // If there is any data in the snapshot of the collection return a ListView.builder will all the posts (docs)
                  if (snapshot.hasData) {
                    if (snapshot.data!.docs.isEmpty) {
                      return const WoofCareEmptyState(
                        icon: Icons.forum_outlined,
                        title: "No posts yet",
                        message:
                            "Share the first update with the WoofCare community.",
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 124),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final post = snapshot.data!.docs[index];
                        return Post(
                          message: post['message'],
                          user: post['email'],
                          time: formatDate(post['timestamp']),
                          postId: post.id,
                          usersWhoLiked: List<String>.from(post['likes'] ?? []),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: TextStyle(
                          color: WoofCareColors.errorMessageColor,
                        ),
                      ),
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: WoofCareColors.buttonColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: WoofCareColors.buttonColor,
        elevation: 8,
        tooltip: 'Create post',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => _postButtonPressed(),
        child: FaIcon(FontAwesomeIcons.paperPlane, color: Colors.white),
      ),
    );
  }
}
