import 'package:flutter_test/flutter_test.dart';
import 'package:ai_connect_africa/features/website/block_models.dart';
import 'package:ai_connect_africa/features/website/html_generator.dart';

void main() {
  group('SiteBlock JSON', () {
    test('round-trips every block type through JSON', () {
      for (final type in SiteBlockType.values) {
        final original = SiteBlock.starter(type).copyWith(
          text: 'Hello',
          secondary: 'World',
          items: ['a', 'b'],
          align: 'center',
        );
        final restored = SiteBlock.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.type, type);
        expect(restored.text, 'Hello');
        expect(restored.secondary, 'World');
        expect(restored.items, ['a', 'b']);
        expect(restored.align, 'center');
      }
    });

    test('document blocks round-trip as a JSON string', () {
      final doc = WebsiteDoc(
        title: 'Test Site',
        blocks: [
          SiteBlock.starter(SiteBlockType.header),
          SiteBlock.starter(SiteBlockType.text),
          SiteBlock.starter(SiteBlockType.list),
        ],
      );
      final restored = WebsiteDoc.blocksFromJson(doc.blocksToJson());
      expect(restored.length, 3);
      expect(restored[0].type, SiteBlockType.header);
      expect(restored[2].items, isNotEmpty);
    });

    test('corrupt JSON yields an empty block list, not a crash', () {
      expect(WebsiteDoc.blocksFromJson('not json'), isEmpty);
      expect(WebsiteDoc.blocksFromJson('{"a":1}'), isEmpty);
    });
  });

  group('HTML generator', () {
    test('produces a complete standalone document', () {
      final doc = WebsiteDoc(
        title: 'My Farm Page',
        themeColor: '#10B981',
        blocks: [
          SiteBlock.starter(SiteBlockType.header).copyWith(
              text: 'Welcome to the Farm', secondary: 'Fresh and local'),
          SiteBlock.starter(SiteBlockType.list)
              .copyWith(text: 'We grow', items: ['Maize', 'Beans']),
          SiteBlock.starter(SiteBlockType.button)
              .copyWith(text: 'Contact us', secondary: 'mailto:farm@home'),
        ],
      );
      final html = generateHtml(doc);

      expect(html, startsWith('<!DOCTYPE html>'));
      expect(html, contains('<title>My Farm Page</title>'));
      expect(html, contains('--accent: #10B981'));
      expect(html, contains('<h1>Welcome to the Farm</h1>'));
      expect(html, contains('<li>Maize</li>'));
      expect(html, contains('href="mailto:farm@home"'));
      expect(html, contains('</html>'));
    });

    test('escapes typed HTML so it cannot execute', () {
      final doc = WebsiteDoc(blocks: [
        SiteBlock.starter(SiteBlockType.text)
            .copyWith(text: '<script>alert("x")</script>'),
      ]);
      final html = generateHtml(doc);
      expect(html, isNot(contains('<script>alert')));
      expect(html, contains('&lt;script&gt;'));
    });

    test('blocks javascript: links and broken theme colors', () {
      final doc = WebsiteDoc(
        themeColor: 'red; } body { display:none',
        blocks: [
          SiteBlock.starter(SiteBlockType.button)
              .copyWith(text: 'Click', secondary: 'javascript:alert(1)'),
        ],
      );
      final html = generateHtml(doc);
      expect(html, isNot(contains('javascript:')));
      expect(html, contains('href="#"'));
      expect(html, contains('--accent: #2E96E8')); // Crystal Sky fallback
    });

    test('keeps safe http links', () {
      final doc = WebsiteDoc(blocks: [
        SiteBlock.starter(SiteBlockType.button)
            .copyWith(secondary: 'https://example.com'),
      ]);
      expect(generateHtml(doc), contains('href="https://example.com"'));
    });
  });
}
