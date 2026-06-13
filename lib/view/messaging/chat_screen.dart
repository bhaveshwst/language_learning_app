import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/messaging/chat_thread_args.dart';
import 'package:language_learning_app/model/messaging/message_model.dart';
import 'package:language_learning_app/model/messaging/messaging_user_role.dart';
import 'package:language_learning_app/provider/chat_thread/chat_thread_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.args});

  final ChatThreadArgs args;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatThreadBloc _chatThreadBloc;

  @override
  void initState() {
    super.initState();
    _chatThreadBloc = ChatThreadBloc()..add(InitChatThread(widget.args));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatThreadBloc.close();
    super.dispose();
  }

  String t(String key) =>
      ConstString.text(AppLanguageState.currentLanguage, key);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _chatThreadBloc.add(SendChatMessage(text));
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return BlocProvider.value(
      value: _chatThreadBloc,
      child: BlocConsumer<ChatThreadBloc, ChatThreadState>(
        listener: (context, state) {
          if (state is ChatThreadReady) {
            _scrollToBottom();
          }
          if (state is ChatThreadError) {
            commonAlertDialog(context, state.message);
          }
        },
        builder: (context, state) {
          final messages = state is ChatThreadReady ? state.messages : const [];
          final isSending = state is ChatThreadReady && state.isSending;
          final isLoading =
              state is ChatThreadInitial || state is ChatThreadLoading;

          return Scaffold(
            backgroundColor: ConstColor.background,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: ConstColor.background,
              foregroundColor: ConstColor.textPrimary,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 0,
              title: Row(
                children: [
                  _PeerAvatar(
                    imageUrl: args.peerImageUrl,
                    name: args.peerName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          args.peerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: ConstColor.textPrimary,
                          ),
                        ),
                        Text(
                          args.viewerRole.isStudent
                              ? t('chatWithTutor')
                              : t('chatWithStudent'),
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
                  ),
                ],
              ),
              actions: const [AppVersionAppBarAction()],
            ),
            body: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: ConstColor.primaryBlue,
                            ),
                          ),
                        )
                      : messages.isEmpty
                      ? _ChatEmptyState(peerName: args.peerName)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            ConstSize.grid * 2,
                            ConstSize.grid,
                            ConstSize.grid * 2,
                            ConstSize.grid * 2,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _MessageBubble(
                              message: message,
                              viewerRole: args.viewerRole,
                            );
                          },
                        ),
                ),
                _ChatComposer(
                  controller: _messageController,
                  enabled: !isLoading && state is! ChatThreadError,
                  isSending: isSending,
                  onSend: _handleSend,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.peerName});

  final String peerName;

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageState.currentLanguage;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ConstSize.grid * 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ConstColor.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: ConstColor.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            const AppText(
              'chatEmptyTitle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ConstColor.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ConstString.text(language, 'chatEmptySubtitle')
                  .replaceAll('{name}', peerName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: ConstColor.textSecondary.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.viewerRole,
  });

  final MessageModel message;
  final MessagingUserRole viewerRole;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine(viewerRole);
    final bubbleColor = message.isFailed
        ? ConstColor.error.withValues(alpha: 0.85)
        : isMine
        ? ConstColor.primaryBlue
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Opacity(
            opacity: message.isPending ? 0.7 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: isMine
                    ? null
                    : Border.all(
                        color: ConstColor.border.withValues(alpha: 0.75),
                      ),
                boxShadow: isMine
                    ? [
                        BoxShadow(
                          color: ConstColor.primaryBlue.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  message.body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: isMine ? Colors.white : ConstColor.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.onSend,
    required this.enabled,
    required this.isSending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          ConstSize.grid * 2,
          ConstSize.grid,
          ConstSize.grid * 2,
          ConstSize.grid * 1.5,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: ConstColor.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: ConstString.text(
                    AppLanguageState.currentLanguage,
                    'typeMessage',
                  ),
                  filled: true,
                  fillColor: ConstColor.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: enabled ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: enabled
                  ? ConstColor.primaryBlue
                  : ConstColor.primaryBlue.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: enabled && !isSending ? onSend : null,
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ],
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
    const size = 40.0;
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
        size: 22,
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
