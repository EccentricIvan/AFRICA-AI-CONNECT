import 'package:flutter/material.dart';

import 'html_preview.dart';

/// Whether [url] is a video clip the chat can play.
bool isClipUrl(String url) =>
    RegExp(r'\.(webm|ogv|mp4|mov)(\?|$)', caseSensitive: false).hasMatch(url);

/// The page that plays one clip: a standard HTML5 video, which every
/// WebView engine the app uses (WebView2 on Windows, System WebView on
/// Android) can play, WebM included.
String clipPlayerHtml(String url) {
  final src = url.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
  return '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width, initial-scale=1">'
      '<style>html,body{margin:0;height:100%;background:#000}'
      'body{display:grid;place-items:center}'
      'video{width:100%;max-height:100vh;background:#000}</style></head>'
      '<body><video controls autoplay playsinline preload="metadata" src="$src">'
      'This device cannot play the clip.</video></body></html>';
}

/// Plays [url] in a window over the chat.
Future<void> showClipPlayer(BuildContext context, String url, {String? title}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final width = size.width * 0.9 > 960 ? 960.0 : size.width * 0.9;
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_outline_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title == null || title.trim().isEmpty ? 'Video clip' : title.replaceFirst(RegExp(r'^▶\s*'), ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: HtmlPreviewPane(html: clipPlayerHtml(url), borderRadius: 0),
              ),
            ],
          ),
        ),
      );
    },
  );
}
