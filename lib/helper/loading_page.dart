import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context, String loading) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.noHeader,
    dismissOnTouchOutside: false,
    dismissOnBackKeyPress: false,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Colors.red),
        const SizedBox(height: 16),
        Text(loading),
      ],
    ),
  ).show();
}

void hideLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}
