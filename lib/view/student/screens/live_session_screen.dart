import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/live_session_config.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/live_session_join_model.dart';
import 'package:language_learning_app/view/student/screens/live_session_screen_sharing_layout.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class LiveSessionScreen extends StatelessWidget {
  const LiveSessionScreen({
    super.key,
    required this.session,
    required this.isTutor,
  });

  final LiveSessionJoinModel session;
  final bool isTutor;

  String _displayInitial(ZegoUIKitUser? user) {
    final source = (user?.name ?? user?.id ?? '').trim();
    if (source.isEmpty) {
      return '?';
    }
    return source[0].toUpperCase();
  }

  /// Notifies backend when leaving the ZEGO UI. Backend must branch on [actor_id]:
  /// tutor → end session for the slot; student → participant leave only (session continues).
  Future<void> _notifyLiveSessionEnd() async {
    try {
      final response = await AppHttpClient.post(
        ConstApiUrl.liveSessionEndUrl,
        body: {
          'tutor_id': session.tutorId,
          'slot_id': session.slotId,
          'room_id': session.roomId,
          'actor_id': session.userId,
        },
      );

      debugPrint('END API STATUS: ${response.statusCode}');
      debugPrint('END API BODY: ${response.body}');
    } catch (e) {
      debugPrint('END API ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('ROOM: ${session.roomId}');
      debugPrint('USER: ${session.userId}');
    }

    if (!LiveSessionConfig.isConfigured) {
      return Scaffold(
        appBar: AppBar(
          title: const AppText('liveSession'),
          actions: const [AppVersionAppBarAction()],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(ConstSize.grid * 2),
            child: Text(
              'ZEGO App ID is missing or invalid. Set ZEGO_APP_ID in '
              'lib/core/constants/live_session_config.dart or via --dart-define.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final config = isTutor
        ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
        : ZegoUIKitPrebuiltLiveStreamingConfig.audience();
    // Screen sharing requires gallery layout for host and audience viewers.
    config.layout = ZegoLayout.gallery(
      showNewScreenSharingViewInFullscreenMode: false,
      showScreenSharingFullscreenModeToggleButtonRules:
          ZegoShowFullscreenModeToggleButtonRules.showWhenScreenPressed,
    );
    config.screenSharing.defaultFullScreen = false;
    config.audioVideoView.containerBuilder = (
      context,
      allUsers,
      audioVideoUsers,
      audioVideoViewCreator,
    ) {
      final screenSharingUsers = ZegoUIKit().getScreenSharingList();
      if (screenSharingUsers.isEmpty) {
        return null;
      }

      return LiveSessionScreenSharingLayout(
        screenSharingUser: screenSharingUsers.first,
        participants: audioVideoUsers,
        audioVideoViewCreator: audioVideoViewCreator,
      );
    };
    // Host kit defaults to a preview + "START" step. Join API already authorized
    // the slot — go straight into the live room (same expectation as Meet/Zoom).
    if (isTutor) {
      config.preview.showPreviewForHost = false;
    }
    config.turnOnMicrophoneWhenJoining = false;
    config.turnOnCameraWhenJoining = false;
    config.avatarBuilder = (context, size, user, extraInfo) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ConstColor.primaryBlue,
        ),
        alignment: Alignment.center,
        child: Text(
          _displayInitial(user),
          style: TextStyle(
            color: Colors.white,
            fontSize: size.shortestSide * 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    };
    config.duration.isVisible = true;
    config.bottomMenuBar.hostButtons = [
      ZegoLiveStreamingMenuBarButtonName.toggleScreenSharingButton,
      ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
      ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
      ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
      ZegoLiveStreamingMenuBarButtonName.leaveButton,
    ];
    config.bottomMenuBar.audienceButtons = [
      ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
      ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
      ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
      ZegoLiveStreamingMenuBarButtonName.leaveButton,
    ];
    final events = ZegoUIKitPrebuiltLiveStreamingEvents(
      room: ZegoLiveStreamingRoomEvents(
        onLoginFailed: (event, defaultAction) async {
          debugPrint(
            'ZEGO room login failed — errorCode: ${event.errorCode}, '
            'message: ${event.message}',
          );
          await defaultAction(event);
        },
      ),
      onLeaveConfirmation: (event, defaultAction) async {
        try {
          await _notifyLiveSessionEnd();
        } catch (_) {}
        return defaultAction();
      },
      onEnded: (event, defaultAction) {
        defaultAction();
      },
    );

    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltLiveStreaming(
          appID: LiveSessionConfig.appId,
          appSign: LiveSessionConfig.appSign,
          userID: session.userId,
          userName: session.userName.isEmpty
              ? session.userId
              : session.userName,
          liveID: session.roomId,
          token: session.token,
          config: config,
          events: events,
        ),
      ),
    );
  }
}
