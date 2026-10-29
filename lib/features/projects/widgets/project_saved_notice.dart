import 'package:flutter/material.dart';

import '../../../l10n/app_locale.dart';

/// A save acknowledgement should not keep covering the editor after saving.
void showProjectSavedNotice(
  BuildContext context, {
  required String name,
  required VoidCallback onOpen,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(trFill(context, 'Saved \u201c{name}\u201d to Projects', {'name': name})),
        persist: false,
        duration: const Duration(seconds: 4),
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: tr(context, 'Open'), onPressed: onOpen),
      ),
    );
}
