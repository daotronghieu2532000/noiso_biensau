import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noiso_biensau/models/sailor_story.dart';

void main() {
  test('Verify stories.json offline data parses correctly into SailorStory models', () {
    final file = File('assets/data/stories.json');
    expect(file.existsSync(), isTrue, reason: 'assets/data/stories.json must exist');

    final jsonString = file.readAsStringSync();
    final List<dynamic> decoded = jsonDecode(jsonString);
    expect(decoded.length, equals(10), reason: 'There must be 10 seeded stories');

    final stories = decoded.map((item) => SailorStory.fromJson(item)).toList();
    expect(stories.length, equals(10));

    for (final story in stories) {
      expect(story.id, greaterThan(0));
      expect(story.storyId.isNotEmpty, isTrue);
      expect(story.title.isNotEmpty, isTrue);
      expect(story.titleEn.isNotEmpty, isTrue);
      expect(story.coverImage.isNotEmpty, isTrue);
      expect(story.content.isNotEmpty, isTrue);

      for (final block in story.content) {
        expect(
          [
            'paragraph',
            'quote',
            'image',
            'video',
            'log_entry',
            'whisper',
            'climax_quote',
            'epilogue_warning'
          ].contains(block.type),
          isTrue,
        );
        if (block.type == 'image' || block.type == 'video') {
          expect(block.url.isNotEmpty, isTrue);
        } else {
          expect(block.text.isNotEmpty, isTrue);
        }
      }
    }
  });

  test('Verify live API https://codego.io.vn/api/get_stories.php returns 5 stories and parses into SailorStory', () async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('https://codego.io.vn/api/get_stories.php'));
      final response = await request.close();
      expect(response.statusCode, equals(200));

      final responseBody = await response.transform(utf8.decoder).join();
      expect(responseBody.isNotEmpty, isTrue);

      final List<dynamic> decoded = jsonDecode(responseBody);
      expect(decoded.length, greaterThanOrEqualTo(5));

      final stories = decoded.map((item) => SailorStory.fromJson(item)).toList();
      expect(stories.length, greaterThanOrEqualTo(5));
      for (final story in stories) {
        expect(story.id, greaterThan(0));
        expect(story.title.isNotEmpty, isTrue);
        expect(story.content.isNotEmpty, isTrue);
        // Verify bilingual author translations even when server has only Vietnamese author
        expect(story.getAuthor('vi'), equals(story.author));
        expect(story.getAuthor('en').isNotEmpty, isTrue);
        expect(story.getAuthor('en').contains('Thuyền Trưởng'), isFalse);
        expect(story.getAuthor('en').contains('Đô Đốc'), isFalse);
        expect(story.getAuthor('en').contains('Giáo Sư'), isFalse);
        expect(story.getAuthor('en').contains('Học Giả'), isFalse);
        expect(story.getAuthor('en').contains('Kỹ Sư'), isFalse);
      }
    } finally {
      client.close();
    }
  });

  test('Verify bilingual title, author and content block accuracy in both VI and EN', () {
    final file = File('assets/data/stories.json');
    final List<dynamic> decoded = jsonDecode(file.readAsStringSync());
    final stories = decoded.map((item) => SailorStory.fromJson(item)).toList();

    for (final story in stories) {
      expect(story.getTitle('vi'), equals(story.title));
      expect(story.getTitle('en'), equals(story.titleEn));
      expect(story.getSubtitle('vi'), equals(story.subtitle));
      expect(story.getSubtitle('en'), equals(story.subtitleEn));
      expect(story.getAuthor('vi'), equals(story.author));
      expect(story.getAuthor('en'), equals(story.authorEn));

      for (final block in story.content) {
        expect(block.getText('vi'), equals(block.text));
        if (block.textEn.isNotEmpty) {
          expect(block.getText('en'), equals(block.textEn));
        }
        expect(block.getCaption('vi'), equals(block.caption));
        if (block.captionEn.isNotEmpty) {
          expect(block.getCaption('en'), equals(block.captionEn));
        }
        expect(block.getHeader('vi'), equals(block.header));
        if (block.headerEn.isNotEmpty) {
          expect(block.getHeader('en'), equals(block.headerEn));
        }
      }
    }
  });
}

