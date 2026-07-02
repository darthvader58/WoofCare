import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/ui/widgets/app_chrome.dart';

import '/config/constants.dart';
import '/ui/widgets/custom_button.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> getLastConversationMessage(
    QueryDocumentSnapshot conversation,
  ) async {
    try {
      final messagesSnapshot =
          await conversation.reference
              .collection('messages')
              .orderBy('time', descending: true)
              .limit(1)
              .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final data = messagesSnapshot.docs.first.data();
        return data["text"] as String? ?? "No messages yet";
      }
    } catch (_) {
      return "No messages yet";
    }

    return "No messages yet";
  }

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return const SearchBottomSheet();
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
              title: 'Messages',
              subtitle: 'Coordinate help and follow-ups',
              icon: Icons.chat_bubble_rounded,
              height: 160,
              searchController: _searchController,
              searchHint: 'Search conversations',
              onSearchChanged:
                  (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
              actions: [
                IconButton.filledTonal(
                  tooltip: 'New conversation',
                  style: IconButton.styleFrom(
                    backgroundColor: WoofCareColors.floatingActionIcons
                        .withValues(alpha: 0.14),
                    foregroundColor: WoofCareColors.floatingActionIcons,
                  ),
                  onPressed: _openSearchSheet,
                  icon: const Icon(Icons.add_rounded, size: 30),
                ),
                const SizedBox(width: 8),
                WoofCareProfileAvatar(
                  onTap: () => Navigator.pushNamed(context, "/profile"),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FIRESTORE
                        .collection("conversations")
                        .where("participants", arrayContains: profile.name)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: WoofCareColors.buttonColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Unable to load conversations",
                        style: TextStyle(
                          color: WoofCareColors.errorMessageColor,
                        ),
                      ),
                    );
                  }

                  final now = DateTime.now();
                  final conversations =
                      (snapshot.data?.docs ?? []).where((conversation) {
                        if (_isExpiredAnonymousChat(conversation, now)) {
                          return false;
                        }
                        final participant = _participantName(conversation);
                        return _query.isEmpty ||
                            participant.toLowerCase().contains(_query);
                      }).toList();

                  if (conversations.isEmpty) {
                    return WoofCareEmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: "No Conversations Yet",
                      message: "Start a new chat to coordinate help.",
                      action: CustomButton(
                        text: "New Chat",
                        icon: Icons.add,
                        margin: 0,
                        verticalPadding: 14,
                        onTap: _openSearchSheet,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 124),
                    itemCount: conversations.length,
                    separatorBuilder:
                        (context, index) => const SizedBox.shrink(),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final participant = _participantName(conversation);

                      return _ConversationRow(
                        name: participant,
                        lastMessage: getLastConversationMessage(conversation),
                        placeholderIndex: index,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'chatID': conversation.id,
                              'photoID': index,
                              'participant': participant,
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _participantName(QueryDocumentSnapshot conversation) {
    final data = conversation.data() as Map<String, dynamic>?;

    if (data?['isReportChat'] == true) {
      final reporterName = data?['reporterName']?.toString();
      final requesterName = data?['requesterName']?.toString();

      if (profile.name == reporterName) {
        return data?['requesterDisplayName']?.toString() ?? 'Anonymous User';
      }

      if (profile.name == requesterName) {
        return data?['reporterDisplayName']?.toString() ??
            (data?['anonymousReporter'] == true
                ? 'Anonymous Reporter'
                : reporterName ?? 'Reporter');
      }
    }

    final participantsData = data?['participants'];
    final participants = participantsData is List ? participantsData : const [];

    if (participants.length > 1) {
      return participants[0] == profile.name
          ? participants[1].toString()
          : participants[0].toString();
    }

    if (participants.length == 1) {
      return participants[0] == profile.name
          ? "Unknown"
          : participants[0].toString();
    }

    return "Unknown";
  }

  bool _isExpiredAnonymousChat(
    QueryDocumentSnapshot conversation,
    DateTime now,
  ) {
    final data = conversation.data() as Map<String, dynamic>?;
    if (data?['isReportChat'] != true || data?['anonymousReporter'] != true) {
      return false;
    }

    final expiresAt = data?['expiresAt'];
    if (expiresAt is! Timestamp) {
      return false;
    }

    return expiresAt.toDate().isBefore(now);
  }
}

class _ConversationRow extends StatelessWidget {
  final String name;
  final Future<String> lastMessage;
  final int placeholderIndex;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.name,
    required this.lastMessage,
    required this.placeholderIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageIndex = (placeholderIndex % 8).clamp(0, 7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Material(
        color: WoofCareColors.offWhite,
        elevation: 3,
        shadowColor: WoofCareColors.cardShadow,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: SizedBox(
            height: 92,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: WoofCareColors.backgroundElementColor,
                    backgroundImage: AssetImage(
                      "assets/images/placeholders/$imageIndex.jpg",
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: WoofCareColors.primaryTextAndIcons,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: WoofCareColors.floatingActionIcons
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Chat",
                                style: TextStyle(
                                  color: WoofCareColors.floatingActionIcons,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<String>(
                          future: lastMessage,
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? "No messages yet",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF734C28),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController searchController = TextEditingController();
  List<String> searchResults = [];
  String? selectedUser;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    final snapshot = await FirebaseFirestore.instance.collection("users").get();

    final matches =
        snapshot.docs
            .where(
              (user) => user["name"].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .map((user) => user["name"].toString())
            .toList();

    if (!mounted) return;
    setState(() => searchResults = matches);
  }

  Future<void> startChat(BuildContext context, String selectedUser) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('conversations')
            .where("participants", arrayContains: profile.name)
            .get();

    final conversations = snapshot.docs.where((doc) {
      final participants = doc["participants"] as List;
      return participants.contains(selectedUser);
    });

    final chatID =
        conversations.isEmpty
            ? (await FirebaseFirestore.instance.collection("conversations").add(
              {
                "messages": [],
                "participants": [profile.name, selectedUser],
              },
            )).id
            : conversations.first.id;

    if (!context.mounted) return;

    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {'chatID': chatID, 'participant': selectedUser},
    );
  }

  void addUser() {
    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a user first")),
      );
      return;
    }

    startChat(context, selectedUser!);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 460,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: WoofCareColors.secondaryBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: WoofCareColors.buttonColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "New conversation",
              style: TextStyle(
                color: WoofCareColors.primaryTextAndIcons,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              maxLines: 1,
              maxLength: 100,
              style: const TextStyle(
                fontSize: 16,
                color: WoofCareColors.primaryTextAndIcons,
              ),
              cursorColor: WoofCareColors.primaryTextAndIcons,
              decoration: InputDecoration(
                counterText: '',
                constraints: const BoxConstraints(maxHeight: 60),
                filled: true,
                fillColor: WoofCareColors.offWhite,
                hintText: "Find user",
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: WoofCareColors.primaryTextAndIcons.withValues(
                    alpha: 0.55,
                  ),
                ),
                prefixIcon: const Icon(Icons.search),
                prefixIconColor: WoofCareColors.primaryTextAndIcons,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: WoofCareColors.buttonColor,
                  ),
                ),
                suffixIcon:
                    searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchResults = []);
                          },
                        )
                        : null,
                suffixIconColor: WoofCareColors.primaryTextAndIcons,
              ),
              onChanged: searchUsers,
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  searchResults.isEmpty
                      ? const Center(
                        child: Text(
                          "No users found",
                          style: TextStyle(
                            color: WoofCareColors.primaryTextAndIcons,
                            fontSize: 16,
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          final isSelected = user == selectedUser;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? WoofCareColors.offWhite
                                      : WoofCareColors.offWhite.withValues(
                                        alpha: 0.88,
                                      ),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? WoofCareColors.floatingActionIcons
                                        : WoofCareColors.offWhite,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isSelected
                                        ? WoofCareColors.floatingActionIcons
                                        : WoofCareColors.buttonColor,
                                child: Icon(
                                  Icons.person,
                                  color:
                                      isSelected
                                          ? WoofCareColors.secondaryBackground
                                          : WoofCareColors.offWhite,
                                ),
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                color:
                                    isSelected
                                        ? WoofCareColors.floatingActionIcons
                                        : WoofCareColors.buttonColor,
                              ),
                              title: Text(
                                user,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: WoofCareColors.primaryTextAndIcons,
                                ),
                              ),
                              onTap: () => setState(() => selectedUser = user),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            CustomButton(text: "Add User", icon: Icons.add, onTap: addUser),
          ],
        ),
      ),
    );
  }
}
