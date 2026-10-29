import 'dart:convert';

/// Khối nội dung trong một câu chuyện hải trình
class StoryBlock {
  final String type; // 'paragraph', 'quote', 'image', 'video', 'log_entry', 'whisper', 'climax_quote', 'epilogue_warning'
  final String text;
  final String textEn;
  final String url;
  final String caption;
  final String captionEn;
  final String header;
  final String headerEn;

  const StoryBlock({
    required this.type,
    this.text = '',
    this.textEn = '',
    this.url = '',
    this.caption = '',
    this.captionEn = '',
    this.header = '',
    this.headerEn = '',
  });

  String getText(String lang) =>
      (lang == 'en' && textEn.isNotEmpty) ? textEn : text;

  String getCaption(String lang) =>
      (lang == 'en' && captionEn.isNotEmpty) ? captionEn : caption;

  String getHeader(String lang) =>
      (lang == 'en' && headerEn.isNotEmpty) ? headerEn : header;

  factory StoryBlock.fromJson(Map<String, dynamic> json) {
    return StoryBlock(
      type: json['type'] as String? ?? 'paragraph',
      text: json['text'] as String? ?? '',
      textEn: json['text_en'] as String? ?? '',
      url: json['url'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      captionEn: json['caption_en'] as String? ?? '',
      header: json['header'] as String? ?? '',
      headerEn: json['header_en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (text.isNotEmpty) 'text': text,
    if (textEn.isNotEmpty) 'text_en': textEn,
    if (url.isNotEmpty) 'url': url,
    if (caption.isNotEmpty) 'caption': caption,
    if (captionEn.isNotEmpty) 'caption_en': captionEn,
    if (header.isNotEmpty) 'header': header,
    if (headerEn.isNotEmpty) 'header_en': headerEn,
  };
}

/// Mô hình dữ liệu Chuyện Thủy Thủ / Hải Trình Ký Sự
class SailorStory {
  final int id;
  final String storyId;
  final String title;
  final String titleEn;
  final String subtitle;
  final String subtitleEn;
  final String author;
  final String authorEn;
  final int readTimeMinutes;
  final String coverImage;
  final String ambientSound;
  final bool isVip;
  final bool isCoverVideo;
  final String coverVideo;
  final List<StoryBlock> content;
  final String createdAt;

  const SailorStory({
    required this.id,
    required this.storyId,
    required this.title,
    required this.titleEn,
    this.subtitle = '',
    this.subtitleEn = '',
    this.author = 'Thuyền Trưởng Hải Trình',
    this.authorEn = '',
    this.readTimeMinutes = 4,
    required this.coverImage,
    this.ambientSound = '',
    this.isVip = false,
    this.isCoverVideo = false,
    this.coverVideo = '',
    required this.content,
    this.createdAt = '',
  });

  /// Lấy video bìa hiệu dụng: nếu coverVideo có sẵn thì lấy, nếu rỗng thì fallback lấy video đầu tiên trong nội dung truyện
  String get effectiveCoverVideo {
    if (coverVideo.isNotEmpty) return coverVideo;
    for (final block in content) {
      if (block.type == 'video' && block.url.isNotEmpty) {
        return block.url;
      }
    }
    return '';
  }

  String getTitle(String lang) =>
      (lang == 'en' && titleEn.isNotEmpty) ? titleEn : title;

  String getSubtitle(String lang) =>
      (lang == 'en' && subtitleEn.isNotEmpty) ? subtitleEn : subtitle;

  String getAuthor(String lang) {
    if (lang == 'en') {
      if (authorEn.isNotEmpty) return authorEn;
      String translated = author;
      const Map<String, String> titleRanks = {
        'Thuyền Trưởng': 'Captain',
        'Đô Đốc Hải Quân': 'Admiral',
        'Đô Đốc': 'Admiral',
        'Giáo Sư Thủy Văn Học': 'Prof.',
        'Giáo Sư': 'Professor',
        'Học Giả Thần Bí': 'Scholar',
        'Học Giả': 'Scholar',
        'Kỹ Sư Hải Dương Học': 'Ocean Engineer',
        'Kỹ Sư': 'Engineer',
        'Thủy Thủ Đoàn': 'The Crew of',
        'Thủy Thủ': 'Sailor',
      };
      for (final entry in titleRanks.entries) {
        if (translated.contains(entry.key)) {
          translated = translated.replaceAll(entry.key, entry.value);
          break;
        }
      }
      return translated;
    }
    return author;
  }

  factory SailorStory.fromJson(Map<String, dynamic> json) {
    List<StoryBlock> parsedBlocks = [];
    final rawContent = json['content'];
    if (rawContent is List) {
      parsedBlocks = rawContent
          .whereType<Map<String, dynamic>>()
          .map((item) => StoryBlock.fromJson(item))
          .toList();
    } else if (rawContent is String && rawContent.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawContent);
        if (decoded is List) {
          parsedBlocks = decoded
              .whereType<Map<String, dynamic>>()
              .map((item) => StoryBlock.fromJson(item))
              .toList();
        }
      } catch (_) {}
    } else if (json['content_json'] != null) {
      final rawContentJson = json['content_json'];
      if (rawContentJson is String && rawContentJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawContentJson);
          if (decoded is List) {
            parsedBlocks = decoded
                .whereType<Map<String, dynamic>>()
                .map((item) => StoryBlock.fromJson(item))
                .toList();
          }
        } catch (_) {}
      } else if (rawContentJson is List) {
        parsedBlocks = rawContentJson
            .whereType<Map<String, dynamic>>()
            .map((item) => StoryBlock.fromJson(item))
            .toList();
      }
    }

    return SailorStory(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      storyId: json['story_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      subtitleEn: json['subtitle_en'] as String? ?? '',
      author: json['author'] as String? ?? 'Thuyền Trưởng Hải Trình',
      authorEn: json['author_en'] as String? ?? '',
      readTimeMinutes: json['read_time_minutes'] is int
          ? json['read_time_minutes'] as int
          : int.tryParse(json['read_time_minutes']?.toString() ?? '4') ?? 4,
      coverImage: json['cover_image'] as String? ?? '',
      ambientSound: json['ambient_sound'] as String? ?? '',
      isVip: json['is_vip'] == true ||
          json['is_vip'] == 1 ||
          json['is_vip'] == '1',
      isCoverVideo: json['is_cover_video'] == true ||
          json['is_cover_video'] == 1 ||
          json['is_cover_video'] == '1',
      coverVideo: json['cover_video'] as String? ?? '',
      content: parsedBlocks,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'story_id': storyId,
    'title': title,
    'title_en': titleEn,
    'subtitle': subtitle,
    'subtitle_en': subtitleEn,
    'author': author,
    'author_en': authorEn,
    'read_time_minutes': readTimeMinutes,
    'cover_image': coverImage,
    'ambient_sound': ambientSound,
    'is_vip': isVip,
    'is_cover_video': isCoverVideo ? 1 : 0,
    'cover_video': coverVideo,
    'content': content.map((b) => b.toJson()).toList(),
    'created_at': createdAt,
  };
}
