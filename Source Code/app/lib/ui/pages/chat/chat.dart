import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/models/profile.dart';
import 'package:woofcare/ui/pages/profile/profile.dart';

import '/config/constants.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  late String chatID;
  bool _isSendButtonDisabled = true;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isSendButtonDisabled = _messageController.text.trim().isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
            as Map;

    chatID = arguments['chatID'];
    final String participant = arguments['participant'];

    return StreamBuilder<DocumentSnapshot>(
      stream: FIRESTORE.collection("conversations").doc(chatID).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        return _buildChatScaffold(context, participant, data);
      },
    );
  }

  Widget _buildChatScaffold(
    BuildContext context,
    String participant,
    Map<String, dynamic> conversationData,
  ) {
    final displayParticipant = _displayParticipant(
      participant,
      conversationData,
    );
    final profileLookupName = _profileLookupName(participant, conversationData);

    return Scaffold(
      backgroundColor: WoofCareColors.offWhite,
      appBar: AppBar(
        backgroundColor: WoofCareColors.offWhite,
        elevation: 3,
        shadowColor: WoofCareColors.cardShadow,
        toolbarHeight: 72,
        iconTheme: IconThemeData(
          color: WoofCareColors.primaryTextAndIcons,
          size: 26,
        ),
        actions:
            _isAnonymousDisplay(displayParticipant)
                ? []
                : [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: WoofCareColors.floatingActionIcons
                            .withValues(alpha: 0.14),
                        foregroundColor: WoofCareColors.floatingActionIcons,
                      ),
                      icon: const Icon(Icons.phone_rounded),
                      onPressed: () {},
                    ),
                  ),
                ],
        title: GestureDetector(
          onTap:
              profileLookupName == null
                  ? null
                  : () async {
                    final userProfile = await Profile.fromName(
                      profileLookupName,
                    );
                    if (userProfile != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(user: userProfile),
                        ),
                      );
                    }
                  },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor:
                    _isAnonymousDisplay(displayParticipant)
                        ? WoofCareColors.buttonColor
                        : WoofCareColors.backgroundElementColor,
                radius: 22,
                backgroundImage:
                    _isAnonymousDisplay(displayParticipant)
                        ? null
                        : const AssetImage("assets/images/placeholders/1.jpg"),
                child:
                    _isAnonymousDisplay(displayParticipant)
                        ? const Icon(
                          Icons.visibility_off_rounded,
                          color: WoofCareColors.offWhite,
                        )
                        : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayParticipant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WoofCareColors.primaryTextAndIcons,
                        fontFamily: "ABeeZee",
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "Active now",
                      style: TextStyle(
                        color: WoofCareColors.mutedText.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _Messages(chatId: chatID, conversationData: conversationData),
            _ChatComposer(
              controller: _messageController,
              sendDisabled: _isSendButtonDisabled,
              onSend: () => submit(context),
            ),
          ],
        ),
      ),
    );
  }

  String _displayParticipant(
    String fallback,
    Map<String, dynamic> conversationData,
  ) {
    if (conversationData['isReportChat'] == true) {
      final reporterName = conversationData['reporterName']?.toString();
      final requesterName = conversationData['requesterName']?.toString();

      if (profile.name == reporterName) {
        return conversationData['requesterDisplayName']?.toString() ??
            'Anonymous User';
      }

      if (profile.name == requesterName) {
        return conversationData['reporterDisplayName']?.toString() ??
            (conversationData['anonymousReporter'] == true
                ? 'Anonymous Reporter'
                : reporterName ?? fallback);
      }
    }

    return fallback;
  }

  String? _profileLookupName(
    String fallback,
    Map<String, dynamic> conversationData,
  ) {
    final displayName = _displayParticipant(fallback, conversationData);
    if (_isAnonymousDisplay(displayName)) return null;

    if (conversationData['isReportChat'] == true) {
      final reporterName = conversationData['reporterName']?.toString();
      final requesterName = conversationData['requesterName']?.toString();

      if (profile.name == reporterName) {
        return conversationData['requesterProfileShared'] == true
            ? requesterName
            : null;
      }

      if (profile.name == requesterName) {
        return conversationData['anonymousReporter'] == true
            ? null
            : reporterName;
      }
    }

    return fallback;
  }

  bool _isAnonymousDisplay(String value) {
    return value == 'Anonymous Reporter' || value == 'Anonymous User';
  }

  void submit(BuildContext context) {
    FocusScope.of(context).unfocus();

    FIRESTORE
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .add({
          "text": _messageController.text.trim(),
          "sender": profile.name,
          "time": Timestamp.now(),
        });

    _messageController.clear();
  }
}

class _Messages extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> conversationData;

  const _Messages({required this.chatId, required this.conversationData});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FIRESTORE
              .collection("conversations")
              .doc(chatId)
              .collection("messages")
              .orderBy("time", descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: WoofCareColors.buttonColor,
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.docs.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text(
                "No messages yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WoofCareColors.primaryTextAndIcons,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }

        final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
        final List<_Message> messages = [];
        for (final QueryDocumentSnapshot doc in docs) {
          final sender = doc.get("sender").toString();
          messages.add(
            _Message(
              text: doc.get("text"),
              sender: _senderDisplayName(sender),
              time: doc.get("time"),
              isSelf: profile.name == sender,
            ),
          );
        }
        return Expanded(
          child: ListView(
            reverse: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
            children: messages,
          ),
        );
      },
    );
  }

  String _senderDisplayName(String sender) {
    if (conversationData['isReportChat'] != true) {
      return sender;
    }

    final reporterName = conversationData['reporterName']?.toString();
    final requesterName = conversationData['requesterName']?.toString();

    if (sender == reporterName &&
        conversationData['anonymousReporter'] == true) {
      return 'Anonymous Reporter';
    }

    if (sender == requesterName &&
        conversationData['requesterProfileShared'] != true) {
      return 'Anonymous User';
    }

    return sender;
  }
}

class _Message extends StatelessWidget {
  final String text;
  final String sender;
  final Timestamp time;
  final bool isSelf;

  const _Message({
    required this.text,
    required this.sender,
    required this.time,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(time.toDate());

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment:
                isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isSelf)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    sender,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: WoofCareColors.mutedText.withValues(alpha: 0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelf
                          ? WoofCareColors.buttonColor
                          : WoofCareColors.secondaryBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isSelf ? 20 : 6),
                    bottomRight: Radius.circular(isSelf ? 6 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color:
                        isSelf
                            ? WoofCareColors.offWhite
                            : WoofCareColors.primaryTextAndIcons,
                    fontSize: 16,
                    height: 1.32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    color: WoofCareColors.mutedText.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sendDisabled;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.sendDisabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: WoofCareColors.offWhite,
        border: Border(
          top: BorderSide(
            color: WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                color: WoofCareColors.primaryTextAndIcons,
                fontSize: 16,
                height: 1.25,
              ),
              decoration: InputDecoration(
                hintText: "Message",
                hintStyle: TextStyle(
                  color: WoofCareColors.primaryTextAndIcons.withValues(
                    alpha: 0.5,
                  ),
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: WoofCareColors.textBoxColor.withValues(alpha: 0.72),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor:
                  sendDisabled
                      ? WoofCareColors.gray
                      : WoofCareColors.buttonColor,
              foregroundColor: WoofCareColors.offWhite,
              fixedSize: const Size(48, 48),
            ),
            onPressed: sendDisabled ? null : onSend,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
