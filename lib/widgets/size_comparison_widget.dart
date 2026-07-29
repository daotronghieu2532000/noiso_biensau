import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

class SizeComparisonWidget extends StatelessWidget {
  final double humanSize; // in meters (default 1.8)
  final double creatureSize; // in meters
  final String creatureName;
  final String creatureImageUrl;

  const SizeComparisonWidget({
    super.key,
    required this.humanSize,
    required this.creatureSize,
    required this.creatureName,
    required this.creatureImageUrl,
  });

  @override
  Widget build(BuildContext buildContext) {
    final strings = AppStrings.of(buildContext);
    final isEn = strings.languageCode == 'en';
    // Determine the scale
    final double maxSize = math.max(humanSize, creatureSize);
    
    // Max display height for the larger object (leaving some padding inside the 220px box)
    final double maxDrawingHeight = 170.0;
    
    // Proportional display sizes
    final double humanDisplayHeight = math.max(16.0, (humanSize / maxSize) * maxDrawingHeight);
    final double creatureDisplayHeight = math.max(16.0, (creatureSize / maxSize) * maxDrawingHeight);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3D).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isEn ? "VISUAL SIZE COMPARISON" : "SO SÁNH KÍCH THƯỚC TRỰC QUAN",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isEn ? "Real scale" : "Tỷ lệ thực tế",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          // Grid layout with images overlay
          SizedBox(
            height: 220.0,
            width: double.infinity,
            child: Stack(
              children: [
                // 1. Grid Background
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(),
                  ),
                ),
                
                // 2. Proportional Images aligned at the bottom
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Diver
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: humanDisplayHeight,
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Image.asset(
                              'assets/images/creatures/diver_transparent.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: Color(0xFFFF3366), size: 30),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEn ? "Diver" : "Thợ lặn",
                            style: const TextStyle(color: Color(0xFFFF3366), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      
                      // Creature
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: creatureDisplayHeight,
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: creatureImageUrl.startsWith('http')
                                ? Image.network(
                                    creatureImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, color: Color(0xFF00F0FF), size: 30),
                                  )
                                : Image.asset(
                                    creatureImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.bug_report, color: Color(0xFF00F0FF), size: 30),
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            creatureName,
                            style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                isEn ? "Diver height: $humanSize m" : "Chiều dài thợ lặn: $humanSize m",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.0,
                ),
              ),
              Text(
                isEn ? "Creature length: $creatureSize m" : "Chiều dài sinh vật: $creatureSize m",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.0,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 8.0;
    final double usableWidth = size.width - (padding * 2);
    final double usableHeight = size.height - (padding * 2);

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    int gridCount = 10;
    for (int i = 0; i <= gridCount; i++) {
      double x = padding + (usableWidth / gridCount) * i;
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), gridPaint);

      double y = padding + (usableHeight / gridCount) * i;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}
