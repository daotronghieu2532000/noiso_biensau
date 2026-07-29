import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

class StructuredDescriptionWidget extends StatefulWidget {
  final String description;
  final Color themeColor;
  final bool compact;
  final int? singleParagraphIndex;

  const StructuredDescriptionWidget({
    super.key,
    required this.description,
    required this.themeColor,
    this.compact = false,
    this.singleParagraphIndex,
  });

  @override
  State<StructuredDescriptionWidget> createState() => _StructuredDescriptionWidgetState();
}

class _StructuredDescriptionWidgetState extends State<StructuredDescriptionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ledController;
  late Animation<double> _ledAnimation;

  @override
  void initState() {
    super.initState();
    _ledController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _ledAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_ledController);
  }

  @override
  void dispose() {
    _ledController.dispose();
    super.dispose();
  }

  Color _getHighlightColor() {
    // If the theme color is red/pink (warning), use a neon gold highlight
    if (widget.themeColor.r > 0.78 && widget.themeColor.g < 0.4) {
      return const Color(0xFFFFD23F); // Neon gold/yellow
    }
    // Otherwise (typically cyan), use a bright amber/orange highlight
    return const Color(0xFFFFB300);
  }

  Widget _buildBlinkingLed(Color color) {
    return AnimatedBuilder(
      animation: _ledController,
      builder: (context, child) {
        return Container(
          width: widget.compact ? 5 : 6,
          height: widget.compact ? 5 : 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: _ledAnimation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _ledAnimation.value * 0.5),
                blurRadius: widget.compact ? 3 : 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, Color baseColor, Color highlightColor, bool isEn) {
    // List of key terms ordered from longest to shortest to ensure correct match precedence.
    final RegExp highlightRegex = isEn
        ? RegExp(
            r'(hunting habit of Cthulhu is unlike any earthly creature|'
            r'hunting habit of this super monster is|'
            r'equal rivals|'
            r'survival rivals|'
            r'arch-nemesis|'
            r'competitor|'
            r'hunting habit is|'
            r'their habit is|'
            r'greatest adversary|'
            r'only intelligent mammal|'
            r'eternal arch-nemesis|'
            r'feeding primarily on|'
            r'favorite food is|'
            r'favorite food|'
            r'hunting habit|'
            r'Great Leviathan|'
            r'Kraken|'
            r'Cthulhu|'
            r'Sea Serpent|'
            r'Apex predator|'
            r'predator|'
            r'habit|'
            r'Megalodon|'
            r'natural enemy|'
            r'Godzillaa|'
            r'behavior|'
            r'rival|'
            r'abyss|'
            r'venomous|'
            r'pressure)',
            caseSensitive: false,
          )
        : RegExp(
            r'(Thói quen săn mồi của Cthulhu không giống bất kỳ loài sinh vật trần tục nào|'
            r'Thói quen săn mồi của siêu quái vật này là|'
            r'Đối thủ - đối trọng ngang tài ngang sức|'
            r'Đối thủ - đối trọng sinh tồn cận kề|'
            r'Đối thủ - đối trọng truyền kiếp của nó|'
            r'Đối thủ - đối trọng truyền kiếp của|'
            r'Đối thủ - đối trọng cạnh tranh|'
            r'Thói quen săn mồi của nó là|'
            r'thói quen săn mồi của nó là|'
            r'Thói quen của chúng là|'
            r'thói quen của chúng là|'
            r'Đối thủ - đối trọng truyền kiếp|'
            r'đối thủ - đối trọng truyền kiếp|'
            r'Đối thủ - đối trọng lớn nhất|'
            r'Đối thủ - đối trọng duy nhất|'
            r'Đối thủ - đối trọng vĩnh cửu|'
            r'Thức ăn ưa thích của|'
            r'thức ăn ưa thích của|'
            r'thức ăn ưa thích là|'
            r'Thức ăn ưa thích là|'
            r'Thói quen săn mồi của nó|'
            r'Thói quen của nó là|'
            r'thói quen của nó là|'
            r'Đối thủ - đối trọng|'
            r'đối thủ - đối trọng|'
            r'Thức ăn ưa thích|'
            r'thức ăn ưa thích|'
            r'Thói quen săn mồi|'
            r'thói quen săn mồi|'
            r'Đại Long Leviathan|'
            r'Thủy Quái Kraken|'
            r'Tà Thần Cthulhu|'
            r'Mãng Xà Biển|'
            r'Kẻ săn mồi|'
            r'kẻ săn mồi|'
            r'Thói quen|'
            r'thói quen|'
            r'Megalodon|'
            r'thiên địch|'
            r'Thiên địch|'
            r'Godzillaa|'
            r'Tập tính|'
            r'tập tính|'
            r'Đối thủ|'
            r'đối thủ|'
            r'vực thẳm|'
            r'kịch độc|'
            r'áp lực)',
            caseSensitive: false,
          );

    final List<TextSpan> spans = [];

    text.splitMapJoin(
      highlightRegex,
      onMatch: (Match match) {
        final String matchText = match[0]!;
        spans.add(TextSpan(
          text: matchText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlightColor,
          ),
        ));
        return '';
      },
      onNonMatch: (String nonMatchText) {
        spans.add(TextSpan(
          text: nonMatchText,
          style: TextStyle(
            color: baseColor.withValues(alpha: 0.85),
          ),
        ));
        return '';
      },
    );

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: widget.compact ? 11.5 : 13.0,
          height: 1.6,
          fontFamily: 'monospace',
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isEn = strings.languageCode == 'en';
    final String cleanDescription = widget.description.trim();
    final List<String> rawParagraphs = cleanDescription.split('. ');
    final List<String> paragraphs = rawParagraphs
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final List<int> indices = [];
    if (widget.singleParagraphIndex != null) {
      if (widget.singleParagraphIndex! >= 0 && widget.singleParagraphIndex! < paragraphs.length) {
        indices.add(widget.singleParagraphIndex!);
      }
    } else {
      indices.addAll(List.generate(paragraphs.length, (i) => i));
    }

    final Color highlightColor = _getHighlightColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: indices.map<Widget>((idx) {
        String text = paragraphs[idx];
        if (!text.endsWith('.')) {
          text += '.';
        }

        // Section dossier info
        String label;
        IconData icon;
        if (idx == 0) {
          label = isEn ? "DETECTION & IDENTIFICATION" : "PHÁT HIỆN & NHẬN DẠNG";
          icon = Icons.visibility_outlined;
        } else if (idx == 1) {
          label = isEn ? "BEHAVIOR & ECOLOGY" : "TẬP TÍNH & SINH THÁI";
          icon = Icons.psychology_outlined;
        } else {
          label = isEn ? "RIVALS & THREATS" : "ĐỐI THỦ & ĐE DỌA";
          icon = Icons.shield_outlined;
        }

        return Container(
          margin: EdgeInsets.only(bottom: widget.compact ? 10.0 : 14.0),
          decoration: BoxDecoration(
            color: const Color(0xFF030D1C).withValues(alpha: 0.65),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            border: Border.all(
              color: widget.themeColor.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.themeColor.withValues(alpha: 0.02),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Holographic watermark icon in the background
              Positioned(
                right: 8,
                top: 8,
                child: Opacity(
                  opacity: widget.compact ? 0.05 : 0.08,
                  child: Icon(icon, color: widget.themeColor, size: widget.compact ? 36 : 44),
                ),
              ),
              
              // Content block
              Padding(
                padding: EdgeInsets.all(widget.compact ? 10.0 : 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildBlinkingLed(widget.themeColor),
                            SizedBox(width: widget.compact ? 6 : 8),
                            Text(
                              label,
                              style: TextStyle(
                                color: widget.themeColor,
                                fontSize: widget.compact ? 9.5 : 11.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        // Status text/code (Decentralized design)
                        Text(
                          "EXP_LOG // 0x${(idx + 1) * 31}A",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: widget.compact ? 7.5 : 8.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: widget.compact ? 4 : 6),
                    Divider(color: widget.themeColor.withValues(alpha: 0.08), thickness: 1),
                    SizedBox(height: widget.compact ? 4 : 6),
                    _buildHighlightedText(
                      text,
                      Colors.white,
                      highlightColor,
                      isEn,
                    ),
                    SizedBox(height: widget.compact ? 4 : 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: widget.compact ? 12 : 20,
                          height: 1.0,
                          color: widget.themeColor.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 3,
                          height: 1.0,
                          color: widget.themeColor.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Glowing neon left-accent bar
              Positioned(
                left: 0,
                top: widget.compact ? 10 : 14,
                bottom: widget.compact ? 10 : 14,
                child: Container(
                  width: 2.5,
                  decoration: BoxDecoration(
                    color: widget.themeColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.themeColor.withValues(alpha: 0.5),
                        blurRadius: 3,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
