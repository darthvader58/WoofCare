import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:woofcare/config/colors.dart';
import 'package:woofcare/models/profile.dart';
import 'package:woofcare/services/location_privacy.dart';
import 'package:woofcare/ui/pages/profile/profile.dart';
import 'package:woofcare/ui/widgets/responsive.dart';
import 'package:woofcare/ui/widgets/web_design_system.dart';

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
  Map<String, dynamic> _conversationData = {};

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
        _conversationData = data;
        return _buildChatScaffold(context, participant, data);
      },
    );
  }

  Widget _buildChatScaffold(
    BuildContext context,
    String participant,
    Map<String, dynamic> conversationData,
  ) {
    final web = WoofCareWebDesign.enabled;
    final displayParticipant = _displayParticipant(
      participant,
      conversationData,
    );
    final profileLookupName = _profileLookupName(participant, conversationData);

    return Scaffold(
      backgroundColor: web ? WoofCareWebDesign.canvas : WoofCareColors.offWhite,
      appBar: AppBar(
        backgroundColor: web
            ? WoofCareWebDesign.surface
            : WoofCareColors.offWhite,
        elevation: web ? 0 : 3,
        shadowColor: WoofCareColors.cardShadow,
        toolbarHeight: web ? 68 : 72,
        shape: web
            ? const Border(bottom: BorderSide(color: WoofCareWebDesign.border))
            : null,
        iconTheme: IconThemeData(
          color: web
              ? WoofCareWebDesign.textMuted
              : WoofCareColors.primaryTextAndIcons,
          size: web ? 22 : 26,
        ),
        actions: _isAnonymousDisplay(displayParticipant)
            ? []
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: web
                          ? WoofCareWebDesign.primary.withValues(alpha: 0.08)
                          : WoofCareColors.floatingActionIcons.withValues(
                              alpha: 0.14,
                            ),
                      foregroundColor: web
                          ? WoofCareWebDesign.primary
                          : WoofCareColors.floatingActionIcons,
                    ),
                    icon: const Icon(Icons.phone_rounded),
                    onPressed: () {},
                  ),
                ),
              ],
        title: GestureDetector(
          onTap: profileLookupName == null
              ? null
              : () async {
                  final userProfile = await Profile.fromName(profileLookupName);
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
                backgroundColor: _isAnonymousDisplay(displayParticipant)
                    ? web
                          ? WoofCareWebDesign.primary
                          : WoofCareColors.buttonColor
                    : web
                    ? WoofCareWebDesign.primary.withValues(alpha: 0.1)
                    : WoofCareColors.backgroundElementColor,
                radius: web ? 19 : 22,
                backgroundImage: web || _isAnonymousDisplay(displayParticipant)
                    ? null
                    : const AssetImage("assets/images/placeholders/1.jpg"),
                child: _isAnonymousDisplay(displayParticipant)
                    ? Icon(
                        Icons.visibility_off_rounded,
                        color: web
                            ? WoofCareWebDesign.onPrimary
                            : WoofCareColors.offWhite,
                        size: web ? 17 : 24,
                      )
                    : web
                    ? Text(
                        displayParticipant.trim().isEmpty
                            ? '?'
                            : displayParticipant.trim()[0].toUpperCase(),
                        style: const TextStyle(
                          color: WoofCareWebDesign.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
                      style: TextStyle(
                        color: web
                            ? WoofCareWebDesign.text
                            : WoofCareColors.primaryTextAndIcons,
                        fontFamily: web ? null : "ABeeZee",
                        fontSize: web ? 15 : 17,
                        fontWeight: web ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    Text(
                      "Active now",
                      style: TextStyle(
                        color: web
                            ? WoofCareWebDesign.textMuted
                            : WoofCareColors.mutedText.withValues(alpha: 0.78),
                        fontSize: web ? 11 : 12,
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
        child: WoofCareContentSurface(
          maxWidth: web ? 1040 : 900,
          child: Column(
            children: [
              _ReportLocationConsentPanel(
                chatId: chatID,
                conversationData: conversationData,
              ),
              _Messages(chatId: chatID, conversationData: conversationData),
              _ChatComposer(
                controller: _messageController,
                sendDisabled: _isSendButtonDisabled,
                onSend: () => submit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayParticipant(
    String fallback,
    Map<String, dynamic> conversationData,
  ) {
    if (conversationData['isReportChat'] == true) {
      final reporterUserId = conversationData['reporterUserId']?.toString();
      final requesterUserId = conversationData['requesterUserId']?.toString();

      if (profile.id == reporterUserId) {
        return conversationData['requesterDisplayName']?.toString() ??
            'Anonymous User';
      }

      if (profile.id == requesterUserId) {
        return conversationData['reporterDisplayName']?.toString() ??
            (conversationData['anonymousReporter'] == true
                ? 'Anonymous Reporter'
                : conversationData['reporterName']?.toString() ?? fallback);
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
      final reporterUserId = conversationData['reporterUserId']?.toString();
      final requesterUserId = conversationData['requesterUserId']?.toString();

      if (profile.id == reporterUserId) {
        return conversationData['requesterProfileShared'] == true
            ? conversationData['requesterName']?.toString()
            : null;
      }

      if (profile.id == requesterUserId) {
        return conversationData['anonymousReporter'] == true
            ? null
            : conversationData['reporterName']?.toString();
      }
    }

    return fallback;
  }

  bool _isAnonymousDisplay(String value) {
    return value == 'Anonymous Reporter' || value == 'Anonymous User';
  }

  void submit(BuildContext context) {
    FocusScope.of(context).unfocus();

    // Store the privacy-appropriate display name so the raw message doc never
    // carries a real name the sender chose to hide; identity checks use
    // senderId, which the rules require to match the authenticated uid.
    String senderName = profile.name;
    if (_conversationData['isReportChat'] == true) {
      final reporterUserId = _conversationData['reporterUserId']?.toString();
      final requesterUserId = _conversationData['requesterUserId']?.toString();
      if (profile.id == reporterUserId &&
          _conversationData['anonymousReporter'] == true) {
        senderName = 'Anonymous Reporter';
      } else if (profile.id == requesterUserId &&
          _conversationData['requesterProfileShared'] != true) {
        senderName = 'Anonymous User';
      }
    }

    FIRESTORE
        .collection("conversations")
        .doc(chatID)
        .collection("messages")
        .add({
          "text": _messageController.text.trim(),
          "sender": senderName,
          "senderId": profile.id,
          "time": Timestamp.now(),
        });

    _messageController.clear();
  }
}

class _ReportLocationConsentPanel extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> conversationData;

  const _ReportLocationConsentPanel({
    required this.chatId,
    required this.conversationData,
  });

  @override
  State<_ReportLocationConsentPanel> createState() =>
      _ReportLocationConsentPanelState();
}

class _ReportLocationConsentPanelState
    extends State<_ReportLocationConsentPanel> {
  Future<_ReportLocationGrantContext?>? _grantContextFuture;
  String? _grantContextKey;
  bool _isGranting = false;
  bool _isResolving = false;

  @override
  Widget build(BuildContext context) {
    if (widget.conversationData['isReportChat'] != true) {
      return const SizedBox.shrink();
    }

    final reportId = widget.conversationData['reportId']?.toString().trim();
    final reporterUserId = widget.conversationData['reporterUserId']
        ?.toString()
        .trim();
    final requesterUserId = widget.conversationData['requesterUserId']
        ?.toString()
        .trim();

    if (reportId == null || reportId.isEmpty) {
      return const SizedBox.shrink();
    }

    final isReporter =
        reporterUserId != null &&
        reporterUserId.isNotEmpty &&
        profile.id == reporterUserId;
    final isRequester =
        requesterUserId != null &&
        requesterUserId.isNotEmpty &&
        profile.id == requesterUserId;
    if (!isReporter && !isRequester) {
      return const SizedBox.shrink();
    }

    final contextKey = '${widget.chatId}|$reportId|$requesterUserId';
    if (_grantContextKey != contextKey) {
      _grantContextKey = contextKey;
      _grantContextFuture = _loadGrantContext(
        chatId: widget.chatId,
        reportId: reportId,
        requesterUserId: requesterUserId,
        isReporter: isReporter,
        isRequester: isRequester,
      );
    }

    return FutureBuilder<_ReportLocationGrantContext?>(
      future: _grantContextFuture,
      builder: (context, snapshot) {
        final grantContext = snapshot.data;
        if (grantContext == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          return _LocationConsentShell(
            icon: Icons.location_off_rounded,
            title: 'Location sharing unavailable',
            message:
                'This chat cannot grant exact location access until the helper profile is available.',
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FIRESTORE
              .collection('report_location_grants')
              .doc(grantContext.grantDocumentId)
              .snapshots(),
          builder: (context, grantSnapshot) {
            final grantData =
                grantSnapshot.data?.data() as Map<String, dynamic>?;
            final grantUserId = grantData?['granteeUserId'];
            final hasGrant =
                grantSnapshot.data?.exists == true &&
                grantData?['pathway'] == 'chat_consent' &&
                grantData?['chatId'] == grantContext.chatId &&
                grantUserId == grantContext.granteeUserId;

            if (hasGrant) {
              return _LocationConsentShell(
                icon: Icons.verified_rounded,
                title: 'Exact location shared',
                message: grantContext.isRequester
                    ? 'The reporter shared this report location with you.'
                    : 'This helper can now access the exact report location.',
                actionLabel: grantContext.isRequester
                    ? 'View exact location'
                    : null,
                actionIcon: Icons.map_rounded,
                busy: _isResolving,
                onAction: grantContext.isRequester
                    ? () => _showExactLocation(grantContext)
                    : null,
              );
            }

            if (grantContext.isReporter) {
              return _LocationConsentShell(
                icon: Icons.my_location_rounded,
                title: 'Share exact location',
                message:
                    'Give only this helper access to the protected exact location for this report.',
                actionLabel: 'Share',
                actionIcon: Icons.lock_open_rounded,
                busy: _isGranting,
                onAction: () => _confirmAndGrant(grantContext),
              );
            }

            return const _LocationConsentShell(
              icon: Icons.lock_rounded,
              title: 'Exact location hidden',
              message:
                  'Ask the reporter here if exact location access is needed.',
            );
          },
        );
      },
    );
  }

  Future<_ReportLocationGrantContext?> _loadGrantContext({
    required String chatId,
    required String reportId,
    required String? requesterUserId,
    required bool isReporter,
    required bool isRequester,
  }) async {
    String? granteeUserId = requesterUserId;

    if ((granteeUserId == null || granteeUserId.isEmpty) && isRequester) {
      granteeUserId = profile.id;
    }

    if (granteeUserId == null || granteeUserId.trim().isEmpty) {
      return null;
    }

    return _ReportLocationGrantContext(
      chatId: chatId,
      reportId: reportId,
      granteeUserId: granteeUserId,
      isReporter: isReporter,
      isRequester: isRequester,
    );
  }

  Future<void> _confirmAndGrant(
    _ReportLocationGrantContext grantContext,
  ) async {
    final shouldGrant = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share exact location?'),
        content: const Text(
          'Only this chat helper will be granted access. Your anonymous reporter display stays private.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );

    if (shouldGrant != true || !mounted) return;

    setState(() => _isGranting = true);

    try {
      await createExactLocationGrant(
        reportId: grantContext.reportId,
        granteeUserId: grantContext.granteeUserId,
        pathway: 'chat_consent',
        grantedBy: profile.id,
        chatId: grantContext.chatId,
      );

      await FIRESTORE.collection('conversations').doc(grantContext.chatId).set({
        'exactLocationShared': true,
        'exactLocationSharedAt': FieldValue.serverTimestamp(),
        'exactLocationSharedWithUserId': grantContext.granteeUserId,
      }, SetOptions(merge: true));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to share location: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGranting = false);
      }
    }
  }

  Future<void> _showExactLocation(
    _ReportLocationGrantContext grantContext,
  ) async {
    setState(() => _isResolving = true);

    try {
      final location = await fetchExactReportLocation(grantContext.reportId);

      if (!mounted) return;

      if (location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exact location is not available yet')),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exact location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load exact location: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }
}

class _LocationConsentShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool busy;
  final VoidCallback? onAction;

  const _LocationConsentShell({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.busy = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WoofCareColors.secondaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: WoofCareColors.buttonColor.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: WoofCareColors.buttonColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: WoofCareColors.buttonColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WoofCareColors.primaryTextAndIcons,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: WoofCareColors.mutedText.withValues(alpha: 0.86),
                    fontSize: 12,
                    height: 1.22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: WoofCareColors.buttonColor,
                foregroundColor: WoofCareColors.offWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: busy ? null : onAction,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(actionIcon, size: 18),
              label: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportLocationGrantContext {
  final String chatId;
  final String reportId;
  final String granteeUserId;
  final bool isReporter;
  final bool isRequester;

  _ReportLocationGrantContext({
    required this.chatId,
    required this.reportId,
    required this.granteeUserId,
    required this.isReporter,
    required this.isRequester,
  });

  String get grantDocumentId {
    return '${reportId}_${granteeUserId}_chat_consent';
  }
}

class _Messages extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> conversationData;

  const _Messages({required this.chatId, required this.conversationData});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FIRESTORE
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
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final sender = data['sender']?.toString() ?? '';
          final senderId = data['senderId']?.toString();
          messages.add(
            _Message(
              text: data['text']?.toString() ?? '',
              sender: _senderDisplayName(sender, senderId),
              time: data['time'] as Timestamp,
              isSelf: senderId != null
                  ? senderId == profile.id
                  : profile.name == sender,
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

  String _senderDisplayName(String sender, String? senderId) {
    if (conversationData['isReportChat'] != true) {
      return sender;
    }

    final reporterUserId = conversationData['reporterUserId']?.toString();
    final requesterUserId = conversationData['requesterUserId']?.toString();
    // Legacy messages carry only a real-name sender; keep masking them too.
    final reporterName = conversationData['reporterName']?.toString();
    final requesterName = conversationData['requesterName']?.toString();

    final isReporterMessage = senderId != null
        ? senderId == reporterUserId
        : sender == reporterName;
    final isRequesterMessage = senderId != null
        ? senderId == requesterUserId
        : sender == requesterName;

    if (isReporterMessage && conversationData['anonymousReporter'] == true) {
      return 'Anonymous Reporter';
    }

    if (isRequesterMessage &&
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
    final web = WoofCareWebDesign.enabled;

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width < 820
              ? MediaQuery.sizeOf(context).width * 0.76
              : 620,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: web ? 10 : 12),
          child: Column(
            crossAxisAlignment: isSelf
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isSelf)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    sender,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: web
                          ? WoofCareWebDesign.textMuted
                          : WoofCareColors.mutedText.withValues(alpha: 0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: web ? 14 : 16,
                  vertical: web ? 10 : 11,
                ),
                decoration: BoxDecoration(
                  color: isSelf
                      ? web
                            ? WoofCareWebDesign.primary
                            : WoofCareColors.buttonColor
                      : web
                      ? WoofCareWebDesign.surface
                      : WoofCareColors.secondaryBackground,
                  borderRadius: web
                      ? BorderRadius.circular(8)
                      : BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isSelf ? 20 : 6),
                          bottomRight: Radius.circular(isSelf ? 6 : 20),
                        ),
                  border: web && !isSelf
                      ? Border.all(color: WoofCareWebDesign.border)
                      : null,
                  boxShadow: web
                      ? null
                      : [
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
                    color: isSelf
                        ? web
                              ? Colors.white
                              : WoofCareColors.offWhite
                        : web
                        ? WoofCareWebDesign.text
                        : WoofCareColors.primaryTextAndIcons,
                    fontSize: web ? 14 : 16,
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
                    color: web
                        ? WoofCareWebDesign.textMuted
                        : WoofCareColors.mutedText.withValues(alpha: 0.62),
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
    final web = WoofCareWebDesign.enabled;
    return Container(
      padding: EdgeInsets.fromLTRB(
        web ? 20 : 14,
        web ? 14 : 10,
        web ? 20 : 14,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: web ? WoofCareWebDesign.surface : WoofCareColors.offWhite,
        border: Border(
          top: BorderSide(
            color: web
                ? WoofCareWebDesign.border
                : WoofCareColors.primaryTextAndIcons.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: web
            ? null
            : [
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
              style: TextStyle(
                color: web
                    ? WoofCareWebDesign.text
                    : WoofCareColors.primaryTextAndIcons,
                fontSize: web ? 14 : 16,
                height: 1.25,
              ),
              decoration: InputDecoration(
                hintText: "Message",
                hintStyle: TextStyle(
                  color: web
                      ? WoofCareWebDesign.textMuted
                      : WoofCareColors.primaryTextAndIcons.withValues(
                          alpha: 0.5,
                        ),
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: web
                    ? WoofCareWebDesign.surfaceMuted
                    : WoofCareColors.textBoxColor.withValues(alpha: 0.72),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(web ? 8 : 24),
                  borderSide: web
                      ? const BorderSide(color: WoofCareWebDesign.border)
                      : BorderSide.none,
                ),
                enabledBorder: web
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: WoofCareWebDesign.border,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: sendDisabled
                  ? web
                        ? WoofCareWebDesign.border
                        : WoofCareColors.gray
                  : web
                  ? WoofCareWebDesign.primary
                  : WoofCareColors.buttonColor,
              foregroundColor: web
                  ? WoofCareWebDesign.onPrimary
                  : WoofCareColors.offWhite,
              fixedSize: Size(web ? 44 : 48, web ? 44 : 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(web ? 8 : 24),
              ),
            ),
            onPressed: sendDisabled ? null : onSend,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
