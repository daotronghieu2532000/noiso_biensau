import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

class OceanDescriptionWidget extends StatefulWidget {
  final String description;
  final Color themeColor;

  const OceanDescriptionWidget({
    super.key,
    required this.description,
    required this.themeColor,
  });

  @override
  State<OceanDescriptionWidget> createState() => _OceanDescriptionWidgetState();
}

class _OceanDescriptionWidgetState extends State<OceanDescriptionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ledController;
  late Animation<double> _ledAnimation;

  @override
  void initState() {
    super.initState();
    _ledController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _ledAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_ledController);
  }

  @override
  void dispose() {
    _ledController.dispose();
    super.dispose();
  }

  Widget _buildBlinkingLed(Color color) {
    return AnimatedBuilder(
      animation: _ledController,
      builder: (context, child) {
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: _ledAnimation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _ledAnimation.value * 0.4),
                blurRadius: 3,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, Color baseColor, Color highlightColor, bool isEn) {
    final RegExp highlightRegex = isEn
        ? RegExp(
            r'(Pacific Ocean|Atlantic Ocean|Indian Ocean|Southern Ocean|Arctic Ocean|'
            r'largest and deepest|deepest|largest|smallest and shallowest|smallest|'
            r'Ring of Fire|active submarine volcanoes|submarine volcanoes|'
            r'perpetual darkness|eternal darkness|world of darkness|'
            r'immense pressure|extreme cold pressure|'
            r'Mid-Atlantic Ridge|shipwreck|Titanic|'
            r'complex faulting|giant underwater earthquakes|destructive tsunamis|'
            r'strong undercurrents|steep canyons|violent storms|'
            r'underwater ice wall|perpetual ice|most isolated geographical mystery|'
            r'evolved completely separately)',
            caseSensitive: false,
          )
        : RegExp(
            r'(Thái Bình Dương|Đại Tây Dương|Ấn Độ Dương|Nam Đại Dương|Bắc Băng Dương|'
            r'lớn nhất và sâu nhất|sâu nhất|lớn nhất|nhỏ nhất và nông nhất|nhỏ nhất|'
            r'Vành đai lửa|núi lửa ngầm đang hoạt động|núi lửa ngầm|'
            r'bóng tối vĩnh cửu|Bóng tối vĩnh cửu|thế giới bóng tối|'
            r'áp suất khổng lồ|áp suất cực lạnh|'
            r'Sống núi giữa Đại Tây Dương|xác tàu đắm|Titanic|'
            r'nứt gãy phức tạp|động đất kiến tạo ngầm khổng lồ|sóng thần tàn phá|'
            r'dòng biển ngầm xiết|hẻm núi dốc đứng|gió bão dữ dội|'
            r'bức tường băng ngầm|băng vĩnh cửu|bí ẩn địa lý cô lập nhất|'
            r'tiến hóa tách biệt hoàn toàn)',
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
        style: const TextStyle(
          fontSize: 12.0,
          height: 1.6,
          fontFamily: 'monospace',
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.listen(context);
    final isEn = strings.languageCode == 'en';
    final List<String> paragraphs = widget.description
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(paragraphs.length, (idx) {
        String label;
        IconData icon;
        if (idx == 0) {
          label = isEn ? "GEOLOGICAL OVERVIEW" : "ĐỊA THỂ TỔNG QUAN";
          icon = Icons.public_outlined;
        } else if (idx == 1) {
          label = isEn ? "TECTONIC STRUCTURE" : "CẤU TRÚC KIẾN TẠO";
          icon = Icons.terrain_outlined;
        } else {
          label = isEn ? "ABYSSAL MYSTERIES" : "BÍ ẨN VỰC THẲM";
          icon = Icons.waves_outlined;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
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
              // Holographic watermark icon
              Positioned(
                right: 8,
                top: 8,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(icon, color: widget.themeColor, size: 36),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildBlinkingLed(widget.themeColor),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: widget.themeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "SURVEY_LOG // 0x${(idx + 1) * 47}F",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 7.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Divider(color: widget.themeColor.withValues(alpha: 0.08), thickness: 1),
                    const SizedBox(height: 4),
                    _buildHighlightedText(
                      paragraphs[idx],
                      Colors.white,
                      const Color(0xFF00F0FF), // Highlight color
                      isEn,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 12,
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

              // Glowing neon left bar
              Positioned(
                left: 0,
                top: 10,
                bottom: 10,
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
      }),
    );
  }
}

class ThalassophobiaWarningWidget extends StatefulWidget {
  final String warningText;

  const ThalassophobiaWarningWidget({
    super.key,
    required this.warningText,
  });

  @override
  State<ThalassophobiaWarningWidget> createState() => _ThalassophobiaWarningWidgetState();
}

class _ThalassophobiaWarningWidgetState extends State<ThalassophobiaWarningWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(_glowController);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Widget _buildWarningText(String text, bool isEn) {
    // List of key terms related to deep sea fear.
    final RegExp dangerRegex = isEn
        ? RegExp(
            r'(1,000 times|atmospheric pressure|crush any normal steel structure in an instant|'
            r'giant shipwrecks|corroded by rust|silent darkness|strong currents|tectonic plate crack|'
            r'Sunda trench|crush|toxic gas pockets|freeze the body|few minutes|perpetual ice drifting aimlessly|'
            r'completely isolated|encounter an incident|no chance of rescue|rescue opportunities)',
            caseSensitive: false,
          )
        : RegExp(
            r'(1,000 lần|áp suất khí quyển|ép nát bất kỳ cấu trúc thép thông thường nào trong tích tắc|'
            r'xác tàu đắm khổng lồ|bị ăn mòn rỉ sét|bóng tối câm lặng|dòng nước xiết|vết nứt mảng kiến tạo ngầm|'
            r'rãnh Sunda|nghiền nát|túi khí độc|đông cứng cơ thể|vài phút|băng vĩnh cửu trôi dạt vô định|'
            r'bị cô lập hoàn toàn|gặp sự cố|không có bất kỳ cơ hội cứu hộ nào|cơ hội cứu hộ)',
            caseSensitive: false,
          );

    final List<TextSpan> spans = [];

    text.splitMapJoin(
      dangerRegex,
      onMatch: (Match match) {
        final String matchText = match[0]!;
        spans.add(TextSpan(
          text: matchText,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white, // Highlighted text in danger box is pure white for extreme visibility
            shadows: [
              Shadow(
                color: Color(0xFFFF3366),
                blurRadius: 4,
              ),
            ],
          ),
        ));
        return '';
      },
      onNonMatch: (String nonMatchText) {
        spans.add(TextSpan(
          text: nonMatchText,
          style: TextStyle(
            color: const Color(0xFFFF3366).withValues(alpha: 0.85),
          ),
        ));
        return '';
      },
    );

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 11.5,
          height: 1.5,
          fontFamily: 'monospace',
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.listen(context);
    final isEn = strings.languageCode == 'en';
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final Color warningColor = const Color(0xFFFF3366);
        final double glowVal = _glowAnimation.value;

        return Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: warningColor.withValues(alpha: 0.03 + (0.02 * glowVal)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: warningColor.withValues(alpha: 0.15 + (0.35 * glowVal)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: warningColor.withValues(alpha: 0.05 * glowVal),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Corner bracket designs (telemetry vibe)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: warningColor, width: 1.5),
                      top: BorderSide(color: warningColor, width: 1.5),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: warningColor, width: 1.5),
                      bottom: BorderSide(color: warningColor, width: 1.5),
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: warningColor.withValues(alpha: 0.5 + (0.5 * glowVal)),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEn ? "THALASSOPHOBIA WARNING" : "CẢNH BÁO HỘI CHỨNG SỢ BIỂN SÂU",
                          style: TextStyle(
                            color: warningColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildWarningText(widget.warningText, isEn),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
