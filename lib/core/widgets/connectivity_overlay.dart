import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';

/// Listens to platform connectivity and shows a full-page offline screen.
class ConnectivityOverlay extends StatefulWidget {
  const ConnectivityOverlay({super.key, required this.child});

  final Widget? child;

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay>
    with SingleTickerProviderStateMixin {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;
  bool _checking = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _listen();
  }

  Future<void> _listen() async {
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    if (!mounted) return;
    _updateOnlineState(_hasNetwork(initial));

    _subscription = connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      _updateOnlineState(_hasNetwork(results));
    });
  }

  void _updateOnlineState(bool isOnline) {
    setState(() => _online = isOnline);
    if (!isOnline) {
      _animController.forward(from: 0);
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _retryConnection() async {
    setState(() => _checking = true);
    await Future.delayed(const Duration(seconds: 2));
    final results = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _online = _hasNetwork(results);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animController.dispose();
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
            // Main app content (always rendered below)
            widget.child ?? const SizedBox.shrink(),

            // Full-page offline overlay
            if (!_online)
              FadeTransition(
                opacity: _fadeAnim,
                child: _NoInternetPage(
                  message: message,
                  isChecking: _checking,
                  onRetry: _retryConnection,
                  scaleAnimation: _scaleAnim,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Full-page No Internet UI
// ---------------------------------------------------------------------------

class _NoInternetPage extends StatelessWidget {
  const _NoInternetPage({
    required this.message,
    required this.isChecking,
    required this.onRetry,
    required this.scaleAnimation,
  });

  final String message;
  final bool isChecking;
  final VoidCallback onRetry;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFFEFF3FB), // same light-blue bg as the app
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Animated icon container ──────────────────────────
                  _PulsingIcon(),

                  const SizedBox(height: 32),

                  // ── Title ────────────────────────────────────────────
                  Text(
                    'No Internet Connection',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2341),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Sub-message ───────────────────────────────────────
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7A99),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Retry button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isChecking ? null : onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ConstColor.primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            ConstColor.primaryBlue.withOpacity(0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isChecking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Hint text ─────────────────────────────────────────
                  Text(
                    'Check your Wi-Fi or mobile data settings',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9BAABF),
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

// ---------------------------------------------------------------------------
// Pulsing wifi-off icon
// ---------------------------------------------------------------------------

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ConstColor.error.withOpacity(0.12),
        ),
        child: Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ConstColor.error.withOpacity(0.18),
            ),
            child: const Center(
              child: Icon(
                Icons.wifi_off_rounded,
                size: 38,
                color: ConstColor.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}