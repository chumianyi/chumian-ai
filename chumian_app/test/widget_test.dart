import 'package:flutter_test/flutter_test.dart';
import 'package:chumian_ai/utils/markdown_stripper.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

void main() {
  group('MarkdownStripper', () {
    test('strips headings', () {
      expect(MarkdownStripper.strip('# Hello'), 'Hello');
      expect(MarkdownStripper.strip('## World'), 'World');
    });

    test('strips bold and italic', () {
      expect(MarkdownStripper.strip('**bold**'), 'bold');
      expect(MarkdownStripper.strip('*italic*'), 'italic');
    });

    test('strips code', () {
      expect(MarkdownStripper.strip('`code`'), 'code');
    });

    test('strips links', () {
      expect(MarkdownStripper.strip('[text](url)'), 'text');
    });

    test('strips lists', () {
      expect(MarkdownStripper.strip('- item'), 'item');
      expect(MarkdownStripper.strip('1. item'), 'item');
    });

    test('strips blockquotes', () {
      expect(MarkdownStripper.strip('> quote'), 'quote');
    });

    test('complex markdown becomes plain text', () {
      const md = '# Title\n\nThis is **bold** and *italic* with `code`.\n\n- item1\n- item2\n\n[link](http://example.com)';
      final result = MarkdownStripper.strip(md);
      expect(result.contains('#'), isFalse);
      expect(result.contains('**'), isFalse);
      expect(result.contains('`'), isFalse);
      expect(result.contains('Title'), isTrue);
      expect(result.contains('bold'), isTrue);
      expect(result.contains('item1'), isTrue);
      expect(result.contains('link'), isTrue);
    });
  });

  group('MiuixColors', () {
    test('primary color is pink', () {
      expect(MiuixColors.primary, const Color(0xFFFF6B9D));
    });

    test('background is light pink', () {
      expect(MiuixColors.background, const Color(0xFFFFF5F8));
    });

    test('gradient has 3 colors', () {
      expect(MiuixColors.primaryGradient.length, 3);
    });
  });

  group('MiuixRadius', () {
    test('pill radius is 999', () {
      expect(MiuixRadius.pill, 999.0);
    });
  });

  test('basic arithmetic', () {
    expect(1 + 1, 2);
  });
}
