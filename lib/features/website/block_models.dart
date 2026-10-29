import 'dart:convert';

/// The building blocks a student can drag onto the canvas.
enum SiteBlockType { header, text, image, button, list, quote, divider }

extension SiteBlockTypeX on SiteBlockType {
  String get label => switch (this) {
        SiteBlockType.header => 'Header',
        SiteBlockType.text => 'Text',
        SiteBlockType.image => 'Image',
        SiteBlockType.button => 'Button',
        SiteBlockType.list => 'List',
        SiteBlockType.quote => 'Quote',
        SiteBlockType.divider => 'Divider',
      };

  static SiteBlockType fromName(String name) => SiteBlockType.values
      .firstWhere((t) => t.name == name, orElse: () => SiteBlockType.text);
}

/// One block on the page. Meaning of [text]/[secondary] depends on [type]:
///
/// | type    | text            | secondary           |
/// |---------|-----------------|---------------------|
/// | header  | title           | subtitle            |
/// | text    | paragraph       | —                   |
/// | image   | caption         | image description   |
/// | button  | label           | link URL            |
/// | list    | list title      | — (items used)      |
/// | quote   | quote text      | author              |
/// | divider | —               | —                   |
class SiteBlock {
  SiteBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.secondary = '',
    this.items = const [],
    this.align = 'left',
  });

  final String id;
  final SiteBlockType type;
  final String text;
  final String secondary;
  final List<String> items;
  final String align; // left | center | right

  static int _counter = 0;

  /// Creates a block with starter content so the canvas never shows
  /// an empty mystery box.
  factory SiteBlock.starter(SiteBlockType type) {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
    return switch (type) {
      SiteBlockType.header => SiteBlock(
          id: id,
          type: type,
          text: 'My Website',
          secondary: 'Welcome to my page',
          align: 'center'),
      SiteBlockType.text => SiteBlock(
          id: id, type: type, text: 'Write something here…'),
      SiteBlockType.image => SiteBlock(
          id: id, type: type, text: 'My photo', secondary: 'A picture of…'),
      SiteBlockType.button => SiteBlock(
          id: id, type: type, text: 'Click me', secondary: '#'),
      SiteBlockType.list => SiteBlock(
          id: id,
          type: type,
          text: 'My list',
          items: const ['First item', 'Second item']),
      SiteBlockType.quote => SiteBlock(
          id: id, type: type, text: 'A wise saying…', secondary: 'Author'),
      SiteBlockType.divider => SiteBlock(id: id, type: type),
    };
  }

  SiteBlock copyWith({
    String? text,
    String? secondary,
    List<String>? items,
    String? align,
  }) =>
      SiteBlock(
        id: id,
        type: type,
        text: text ?? this.text,
        secondary: secondary ?? this.secondary,
        items: items ?? this.items,
        align: align ?? this.align,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'text': text,
        'secondary': secondary,
        'items': items,
        'align': align,
      };

  factory SiteBlock.fromJson(Map<String, dynamic> json) => SiteBlock(
        id: json['id'] as String? ??
            '${DateTime.now().microsecondsSinceEpoch}_${_counter++}',
        type: SiteBlockTypeX.fromName(json['type'] as String? ?? 'text'),
        text: json['text'] as String? ?? '',
        secondary: json['secondary'] as String? ?? '',
        items: (json['items'] as List?)?.cast<String>() ?? const [],
        align: json['align'] as String? ?? 'left',
      );
}

/// Theme colors a student can pick for the page accent.
const siteThemeColors = <String, String>{
  'Crystal Blue': '#2E96E8',
  'Sky': '#3BAFD4',
  'Deep Blue': '#1B7FD4',
  'Teal': '#2EA8C4',
  'Green': '#3DAA6D',
  'Slate': '#3D5A73',
};

/// A whole website document: title + theme + ordered blocks.
class WebsiteDoc {
  const WebsiteDoc({
    this.title = 'My Website',
    this.themeColor = '#2E96E8',
    this.blocks = const [],
  });

  final String title;
  final String themeColor;
  final List<SiteBlock> blocks;

  WebsiteDoc copyWith({
    String? title,
    String? themeColor,
    List<SiteBlock>? blocks,
  }) =>
      WebsiteDoc(
        title: title ?? this.title,
        themeColor: themeColor ?? this.themeColor,
        blocks: blocks ?? this.blocks,
      );

  String blocksToJson() => jsonEncode(blocks.map((b) => b.toJson()).toList());

  static List<SiteBlock> blocksFromJson(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => SiteBlock.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
