import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in the system browser; shows a message if nothing can.
Future<void> openExternalLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not open ${uri.host}${uri.path}')),
    );
  }
}
