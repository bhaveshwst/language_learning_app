import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';

/// Listens to platform connectivity and shows a banner when offline.
class ConnectivityOverlay extends StatefulWidget {
  const ConnectivityOverlay({super.key, required this.child});

  final Widget? child;

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() => _online = _hasNetwork(initial));

    _subscription = connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _online = _hasNetwork(results));
    });
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageState.current,
      builder: (context, lang, _) {
        final message = ConstString.text(lang, 'noInternetMessage');

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child ?? const SizedBox.shrink(),
            if (!_online)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: ConstColor.error,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                message,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
