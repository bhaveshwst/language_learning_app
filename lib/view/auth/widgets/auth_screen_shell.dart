import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.child,
    this.showAppBar = true,
  });

  final Widget child;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(backgroundColor: Colors.transparent) : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ConstSize.grid * 3,
                  ConstSize.grid * 2,
                  ConstSize.grid * 3,
                  ConstSize.grid * 4,
                ),
                child: child,
              ),
            ),
            const AppVersionFooter(),
          ],
        ),
      ),
    );
  }
}
