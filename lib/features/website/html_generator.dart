import 'block_models.dart';

/// Generates a complete standalone .html file from a [WebsiteDoc].
/// No external assets, no network — opens in any browser fully offline.
String generateHtml(WebsiteDoc doc) {
  final accent = _safeColor(doc.themeColor);
  final body = doc.blocks.map(_blockHtml).join('\n');

  return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${_esc(doc.title)}</title>
<style>
  :root { --accent: $accent; }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: Arial, Helvetica, sans-serif;
    color: #0f172a;
    background: #f8fafc;
    line-height: 1.6;
  }
  main { max-width: 760px; margin: 0 auto; padding: 24px 20px 64px; }
  .hero {
    background: var(--accent);
    color: #ffffff;
    border-radius: 16px;
    padding: 40px 24px;
    margin: 16px 0;
  }
  .hero h1 { margin: 0 0 8px; font-size: 2rem; }
  .hero p { margin: 0; opacity: 0.9; }
  .btn {
    display: inline-block;
    background: var(--accent);
    color: #ffffff;
    text-decoration: none;
    padding: 12px 28px;
    border-radius: 10px;
    font-weight: bold;
    margin: 12px 0;
  }
  .image-frame {
    border: 2px dashed var(--accent);
    border-radius: 12px;
    padding: 48px 16px;
    text-align: center;
    color: #64748b;
    margin: 16px 0;
    background: #ffffff;
  }
  .image-frame .caption { font-weight: bold; color: #0f172a; margin-top: 8px; }
  blockquote {
    border-left: 4px solid var(--accent);
    margin: 16px 0;
    padding: 8px 20px;
    background: #ffffff;
    border-radius: 0 12px 12px 0;
    font-style: italic;
  }
  blockquote footer { font-style: normal; color: #64748b; margin-top: 6px; }
  hr { border: none; border-top: 2px solid #e2e8f0; margin: 28px 0; }
  ul { background: #ffffff; border-radius: 12px; padding: 16px 16px 16px 36px; }
  .align-center { text-align: center; }
  .align-right { text-align: right; }
</style>
</head>
<body>
<main>
$body
</main>
</body>
</html>
''';
}

String _blockHtml(SiteBlock b) {
  final alignClass = switch (b.align) {
    'center' => ' class="align-center"',
    'right' => ' class="align-right"',
    _ => '',
  };

  return switch (b.type) {
    SiteBlockType.header => '''
<section class="hero${b.align == 'center' ? ' align-center' : ''}">
  <h1>${_esc(b.text)}</h1>
  ${b.secondary.isNotEmpty ? '<p>${_esc(b.secondary)}</p>' : ''}
</section>''',
    SiteBlockType.text => '<p$alignClass>${_esc(b.text)}</p>',
    SiteBlockType.image => '''
<div class="image-frame">
  <div>🖼 ${_esc(b.secondary.isNotEmpty ? b.secondary : 'Add your image here (replace this box with an &lt;img&gt; tag)')}</div>
  ${b.text.isNotEmpty ? '<div class="caption">${_esc(b.text)}</div>' : ''}
</div>''',
    SiteBlockType.button =>
      '<div$alignClass><a class="btn" href="${_safeUrl(b.secondary)}">${_esc(b.text)}</a></div>',
    SiteBlockType.list => '''
${b.text.isNotEmpty ? '<h3>${_esc(b.text)}</h3>' : ''}
<ul>
${b.items.map((i) => '  <li>${_esc(i)}</li>').join('\n')}
</ul>''',
    SiteBlockType.quote => '''
<blockquote>
  ${_esc(b.text)}
  ${b.secondary.isNotEmpty ? '<footer>— ${_esc(b.secondary)}</footer>' : ''}
</blockquote>''',
    SiteBlockType.divider => '<hr>',
  };
}

/// Escapes user text so typed HTML shows as text instead of executing.
String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// Only allow harmless link targets; anything scripty becomes '#'.
String _safeUrl(String url) {
  final u = url.trim();
  if (u.isEmpty || u == '#') return '#';
  final lower = u.toLowerCase();
  final allowed = lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('mailto:') ||
      lower.startsWith('#') ||
      lower.startsWith('./');
  if (!allowed) return '#';
  return _esc(u);
}

/// Theme color must be a #rrggbb hex value; falls back to indigo.
String _safeColor(String hex) {
  final ok = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex);
  return ok ? hex : '#2E96E8';
}
