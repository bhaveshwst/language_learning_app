import 'package:flutter/material.dart';

/// Root [Navigator] key for [MaterialApp] so session expiry can navigate without a [BuildContext].
final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>();
