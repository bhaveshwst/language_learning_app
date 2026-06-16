import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

/// Screen share on top (~75%), participant tiles in a compact row below (~25%).
class LiveSessionScreenSharingLayout extends StatelessWidget {
  const LiveSessionScreenSharingLayout({
    super.key,
    required this.screenSharingUser,
    required this.participants,
    required this.audioVideoViewCreator,
  });

  final ZegoUIKitUser screenSharingUser;
  final List<ZegoUIKitUser> participants;
  final ZegoAudioVideoView Function(ZegoUIKitUser user) audioVideoViewCreator;

  static const int _screenShareFlex = 3;
  static const int _participantsFlex = 1;

  @override
  Widget build(BuildContext context) {
    final screenSharingController =
        ZegoUIKitPrebuiltLiveStreamingController().screenSharing.viewController;

    return ColoredBox(
      color: const Color(0xff171821),
      child: Column(
        children: [
          Expanded(
            flex: _screenShareFlex,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ZegoScreenSharingView(
                  user: screenSharingUser,
                  controller: screenSharingController,
                  showFullscreenModeToggleButtonRules:
                      ZegoShowFullscreenModeToggleButtonRules
                          .showWhenScreenPressed,
                ),
              ),
            ),
          ),
          Expanded(
            flex: _participantsFlex,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  for (final user in participants)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: audioVideoViewCreator(user),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
