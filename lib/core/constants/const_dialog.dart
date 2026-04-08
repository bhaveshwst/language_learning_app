import 'package:flutter/cupertino.dart';

void commonAlertDialog(BuildContext context, String text) {
  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        content: Text(text),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

void commonAlertDialogwithButton(
  BuildContext context,
  String text,
  void Function()? onPressed,
) {
  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        content: Text(text),
        actions: [
          CupertinoDialogAction(onPressed: onPressed, child: const Text("OK")),
        ],
      );
    },
  );
}
