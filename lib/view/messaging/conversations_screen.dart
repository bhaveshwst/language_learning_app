import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/messaging/messaging_navigation.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/core/widgets/unread_count_badge.dart';
import 'package:language_learning_app/model/messaging/conversation_model.dart';
import 'package:language_learning_app/provider/conversation_list/conversation_list_bloc.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final ConversationListBloc _conversationListBloc;

  @override
  void initState() {
    super.initState();
    _conversationListBloc = ConversationListBloc();
    _fetchConversations();
  }

  @override
  void dispose() {
    _conversationListBloc.close();
    super.dispose();
  }

  void _fetchConversations() {
    final tutorId = PrefUtils.gettutorid().trim();
    if (tutorId.isEmpty) return;
    _conversationListBloc.add(
      FetchConversationList(
        studentId: null,
        tutorId: tutorId,
      ),
    );
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(value.year, value.month, value.day);

    if (messageDay == today) {
      final hour = value.hour.toString().padLeft(2, '0');
      final minute = value.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return '${value.month}/${value.day}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _conversationListBloc,
      child: BlocConsumer<ConversationListBloc, ConversationListState>(
        listener: (context, state) {
          if (state is ConversationListError) {
            commonAlertDialog(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading =
              state is ConversationListInitial ||
              state is ConversationListLoading;
          final conversations = state is ConversationListSuccess
              ? state.conversations
              : const <ConversationModel>[];

          return Scaffold(
            backgroundColor: ConstColor.background,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: ConstColor.background,
              foregroundColor: ConstColor.textPrimary,
              surfaceTintColor: Colors.transparent,
              title: const AppText(
                'chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                  color: ConstColor.textPrimary,
                ),
              ),
              actions: const [AppVersionAppBarAction()],
            ),
            body: SafeArea(
              child: RefreshIndicator(
                color: ConstColor.primaryBlue,
                onRefresh: () async => _fetchConversations(),
                child: isLoading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: ConstColor.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      )
                    : conversations.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          ConstSize.grid * 2,
                          ConstSize.grid * 4,
                          ConstSize.grid * 2,
                          ConstSize.grid * 2,
                        ),
                        children: const [
                          _ConversationsEmptyState(),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          ConstSize.grid * 2,
                          ConstSize.grid,
                          ConstSize.grid * 2,
                          ConstSize.grid * 2,
                        ),
                        itemCount: conversations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          return _ConversationTile(
                            conversation: conversation,
                            timestampLabel: _formatTimestamp(
                              conversation.lastMessageAt,
                            ),
                            onTap: () async {
                              _conversationListBloc.add(
                                MarkConversationReadLocally(conversation.id),
                              );
                              await MessagingNavigation.openTutorChatWithStudent(
                                context,
                                studentId: conversation.peerId,
                                studentName: conversation.peerName,
                                studentImageUrl: conversation.peerImageUrl,
                                conversationId: conversation.id,
                              );
                              if (!mounted) return;
                              _fetchConversations();
                            },
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationsEmptyState extends StatelessWidget {
  const _ConversationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: ConstColor.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.forum_outlined,
            size: 38,
            color: ConstColor.primaryBlue,
          ),
        ),
        const SizedBox(height: 18),
        const AppText(
          'chatInboxEmptyTitle',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ConstColor.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        AppText(
          'chatInboxEmptySubtitle',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: ConstColor.textSecondary.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.timestampLabel,
    required this.onTap,
  });

  final ConversationModel conversation;
  final String timestampLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = (conversation.lastMessageText ?? '').trim();
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ConstColor.border.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            children: [
              _PeerAvatar(
                imageUrl: conversation.peerImageUrl,
                name: conversation.peerName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: ConstColor.textPrimary,
                            ),
                          ),
                        ),
                        if (timestampLabel.isNotEmpty)
                          Text(
                            timestampLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ConstColor.textSecondary.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview.isEmpty
                                ? ConstString.text(
                                    AppLanguageState.currentLanguage,
                                    'chatNoMessagesYet',
                                  )
                                : preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: ConstColor.textSecondary.withValues(
                                alpha: 0.95,
                              ),
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: UnreadCountBadge(
                              count: conversation.unreadCount,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({
    required this.imageUrl,
    required this.name,
  });

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final url = (imageUrl ?? '').trim();

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ConstColor.primaryBlue.withValues(alpha: 0.12),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: ConstColor.primaryBlue,
        size: 24,
      ),
    );

    if (url.isEmpty) return placeholder;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
        ),
      ),
    );
  }
}
