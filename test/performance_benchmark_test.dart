import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Đo lường Hiệu năng Thực tế (Benchmark Performance Test)', () {
    const int frameIterations = 2000;
    const Size screenSize = Size(393, 852); // Kích thước màn hình iPhone

    test('1. Benchmark Vẽ Sứa Phát Quang Hoàn Chỉnh (Bell + Glow + 3 Xúc tu) ($frameIterations frames)', () {
      final recorderOld = PictureRecorder();
      final canvasOld = Canvas(recorderOld);

      // --- CÁCH CŨ: Quầng sáng blur 15 + Viền mũ blur 1 + 3 xúc tu đều blur 1 ---
      final stopwatchOld = Stopwatch()..start();
      for (int i = 0; i < frameIterations; i++) {
        final double pulse = math.sin(i * 0.05);
        final double currentSize = 35.0 * (1.0 + 0.15 * pulse);
        
        final Paint glowPaintOld = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.12)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

        final Paint linePaintOld = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

        final Paint fillPaintOld = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

        // Vẽ quầng glow blur
        canvasOld.drawCircle(const Offset(200, 400), currentSize * 1.6, glowPaintOld);
        
        // Vẽ mũ sứa (fill + stroke blur)
        final Path bellPath = Path()
          ..moveTo(180, 400)
          ..cubicTo(180, 365, 220, 365, 220, 400)
          ..close();
        canvasOld.drawPath(bellPath, fillPaintOld);
        canvasOld.drawPath(bellPath, linePaintOld);

        // Vẽ 3 xúc tu uốn lượn (stroke blur)
        for (int t = -1; t <= 1; t++) {
          final Path tentacle = Path()
            ..moveTo(200.0 + t * 7.0, 400)
            ..cubicTo(200.0 + t * 7.0, 430, 205.0, 450, 200.0, 480);
          canvasOld.drawPath(tentacle, linePaintOld);
        }
      }
      stopwatchOld.stop();
      final picOld = recorderOld.endRecording();
      picOld.dispose();
      final int timeOldUs = stopwatchOld.elapsedMicroseconds;

      // --- CÁCH MỚI: Tái sử dụng Paint + Solid Alpha Glow 2 tầng + Viền sắc nét (Zero Blur) ---
      final recorderNew = PictureRecorder();
      final canvasNew = Canvas(recorderNew);

      final Paint glowOuter = Paint()..style = PaintingStyle.fill;
      final Paint glowInner = Paint()..style = PaintingStyle.fill;
      final Paint linePaintNew = Paint()
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final Paint fillPaintNew = Paint()..style = PaintingStyle.fill;

      final stopwatchNew = Stopwatch()..start();
      for (int i = 0; i < frameIterations; i++) {
        final double pulse = math.sin(i * 0.05);
        final double currentSize = 35.0 * (1.0 + 0.15 * pulse);

        glowOuter.color = const Color(0xFF00E5FF).withValues(alpha: 0.08);
        glowInner.color = const Color(0xFF00E5FF).withValues(alpha: 0.18);
        linePaintNew.color = const Color(0xFF00E5FF).withValues(alpha: 0.65);
        fillPaintNew.color = const Color(0xFF00E5FF).withValues(alpha: 0.3);

        // Vẽ quầng sáng 2 tầng (Zero blur)
        canvasNew.drawCircle(const Offset(200, 400), currentSize * 1.6, glowOuter);
        canvasNew.drawCircle(const Offset(200, 400), currentSize * 1.1, glowInner);

        // Vẽ mũ sứa (fill + stroke không blur)
        final Path bellPath = Path()
          ..moveTo(180, 400)
          ..cubicTo(180, 365, 220, 365, 220, 400)
          ..close();
        canvasNew.drawPath(bellPath, fillPaintNew);
        canvasNew.drawPath(bellPath, linePaintNew);

        // Vẽ 3 xúc tu uốn lượn (stroke không blur)
        for (int t = -1; t <= 1; t++) {
          final Path tentacle = Path()
            ..moveTo(200.0 + t * 7.0, 400)
            ..cubicTo(200.0 + t * 7.0, 430, 205.0, 450, 200.0, 480);
          canvasNew.drawPath(tentacle, linePaintNew);
        }
      }
      stopwatchNew.stop();
      final picNew = recorderNew.endRecording();
      picNew.dispose();
      final int timeNewUs = stopwatchNew.elapsedMicroseconds;

      final double percentSaved = ((timeOldUs - timeNewUs) / timeOldUs) * 100;

      print('\n======================================================');
      print('📊 KẾT QUẢ BENCHMARK 1: VẼ SỨA BIỂN SÂU HOÀN CHỈNH ($frameIterations FRAMES)');
      print('• Phiên bản CŨ (Nhiều MaskFilter.blur): ${(timeOldUs / 1000).toStringAsFixed(2)} ms (${(timeOldUs / frameIterations).toStringAsFixed(2)} µs/frame)');
      print('• Phiên bản MỚI (Tái sử dụng Paint + Zero Blur): ${(timeNewUs / 1000).toStringAsFixed(2)} ms (${(timeNewUs / frameIterations).toStringAsFixed(2)} µs/frame)');
      print('👉 TIẾT KIỆM TẢI VẼ: ${percentSaved.toStringAsFixed(1)}%');
      print('======================================================\n');

      expect(timeNewUs, lessThan(timeOldUs));
    });

    test('2. Benchmark Vẽ Rong Biển & Quầng Sáng Đáy Biển ($frameIterations frames)', () {
      final recorderOld = PictureRecorder();
      final canvasOld = Canvas(recorderOld);

      // --- CŨ: 36 cây (18 trái + 18 phải) có MaskFilter.blur(10) ---
      final stopwatchOld = Stopwatch()..start();
      for (int f = 0; f < frameIterations; f++) {
        const int plantCount = 18;
        for (int i = 0; i < plantCount * 2; i++) {
          final Paint glowPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = const Color(0xFFFF527B).withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
          canvasOld.drawCircle(Offset(i * 10.0, 500), 12.0, glowPaint);
        }
      }
      stopwatchOld.stop();
      final picOld = recorderOld.endRecording();
      picOld.dispose();
      final int timeOldUs = stopwatchOld.elapsedMicroseconds;

      // --- MỚI: 24 cây (12 trái + 12 phải) dùng Solid Alpha Falloff + Tái sử dụng Paint ---
      final recorderNew = PictureRecorder();
      final canvasNew = Canvas(recorderNew);

      final Paint glowPaint = Paint()..style = PaintingStyle.fill;

      final stopwatchNew = Stopwatch()..start();
      for (int f = 0; f < frameIterations; f++) {
        const int plantCount = 12;
        for (int i = 0; i < plantCount * 2; i++) {
          glowPaint.color = const Color(0xFFFF527B).withValues(alpha: 0.15);
          canvasNew.drawCircle(Offset(i * 10.0, 500), 12.0, glowPaint);
        }
      }
      stopwatchNew.stop();
      final picNew = recorderNew.endRecording();
      picNew.dispose();
      final int timeNewUs = stopwatchNew.elapsedMicroseconds;

      final double percentSaved = ((timeOldUs - timeNewUs) / timeOldUs) * 100;

      print('\n======================================================');
      print('📊 KẾT QUẢ BENCHMARK 2: VẼ RONG BIỂN & QUẦNG ĐÁY BIỂN ($frameIterations FRAMES)');
      print('• Phiên bản CŨ (36 cây + MaskFilter.blur): ${(timeOldUs / 1000).toStringAsFixed(2)} ms (${(timeOldUs / frameIterations).toStringAsFixed(2)} µs/frame)');
      print('• Phiên bản MỚI (24 cây + Solid Alpha):    ${(timeNewUs / 1000).toStringAsFixed(2)} ms (${(timeNewUs / frameIterations).toStringAsFixed(2)} µs/frame)');
      print('👉 TIẾT KIỆM TẢI VẼ: ${percentSaved.toStringAsFixed(1)}%');
      print('======================================================\n');

      expect(timeNewUs, lessThan(timeOldUs));
    });

    test('3. Benchmark Bước Tính Sóng Biển WavePainter ($frameIterations frames)', () {
      final recorderOld = PictureRecorder();
      final canvasOld = Canvas(recorderOld);

      // --- CŨ: Bước nhảy x += 4 ---
      final stopwatchOld = Stopwatch()..start();
      for (int f = 0; f < frameIterations; f++) {
        final path = Path()..moveTo(0, screenSize.height);
        for (double x = 0; x <= screenSize.width; x += 4) {
          double relativeX = x / screenSize.width;
          double y = 15.0 * math.sin((relativeX * 1.5 * 2 * math.pi) + f * 0.05);
          path.lineTo(x, y + 250);
        }
        path.lineTo(screenSize.width, screenSize.height);
        path.close();
        canvasOld.drawPath(path, Paint()..color = Colors.blue);
      }
      stopwatchOld.stop();
      final picOld = recorderOld.endRecording();
      picOld.dispose();
      final int timeOldUs = stopwatchOld.elapsedMicroseconds;

      // --- MỚI: Bước nhảy x += 8 ---
      final recorderNew = PictureRecorder();
      final canvasNew = Canvas(recorderNew);

      final stopwatchNew = Stopwatch()..start();
      for (int f = 0; f < frameIterations; f++) {
        final path = Path()..moveTo(0, screenSize.height);
        for (double x = 0; x <= screenSize.width; x += 8) {
          double relativeX = x / screenSize.width;
          double y = 15.0 * math.sin((relativeX * 1.5 * 2 * math.pi) + f * 0.05);
          path.lineTo(x, y + 250);
        }
        path.lineTo(screenSize.width, screenSize.height);
        path.close();
        canvasNew.drawPath(path, Paint()..color = Colors.blue);
      }
      stopwatchNew.stop();
      final picNew = recorderNew.endRecording();
      picNew.dispose();
      final int timeNewUs = stopwatchNew.elapsedMicroseconds;

      final double percentSaved = ((timeOldUs - timeNewUs) / timeOldUs) * 100;

      print('\n======================================================');
      print('📊 KẾT QUẢ BENCHMARK 3: VẼ SÓNG BIỂN WAVEPAINTER ($frameIterations FRAMES)');
      print('• Phiên bản CŨ (Bước tính x += 4): ${(timeOldUs / 1000).toStringAsFixed(2)} ms (${(timeOldUs / frameIterations).toStringAsFixed(2)} µs/frame)');
      print('• Phiên bản MỚI (Bước tính x += 8): ${(timeNewUs / 1000).toStringAsFixed(2)} ms (${(timeNewUs / frameIterations).toStringAsFixed(2)} µs/frame)');
      print('👉 TIẾT KIỆM TẢI TÍNH TOÁN SÓNG: ${percentSaved.toStringAsFixed(1)}%');
      print('======================================================\n');

      expect(timeNewUs, lessThan(timeOldUs));
    });

    test('4. Benchmark Vòng Lặp Vật Lý Trong _updateParticles (50.000 iterations)', () {
      const int loopIterations = 50000;

      // --- CŨ: Tính toán toàn bộ thực thể dù đang ở mặt nước (độ sâu 0m) ---
      final stopwatchOld = Stopwatch()..start();
      double dummyOld = 0.0;
      for (int i = 0; i < loopIterations; i++) {
        // Cập nhật chim (10 con)
        for (int b = 0; b < 10; b++) {
          dummyOld += math.sin(i * 0.05 + b) * 0.15;
        }
        // Cập nhật sứa (8 con) - dù đang ở độ sâu 0m vẫn tính toán
        for (int j = 0; j < 8; j++) {
          dummyOld += math.sin(i * 0.02 + j) * 0.25;
        }
      }
      stopwatchOld.stop();
      final int timeOldUs = stopwatchOld.elapsedMicroseconds;

      // --- MỚI: Bỏ qua sứa khi độ sâu <= 700m (chỉ tính chim) ---
      final stopwatchNew = Stopwatch()..start();
      double dummyNew = 0.0;
      const double currentDepth = 0.0; // Đang ở mặt nước
      for (int i = 0; i < loopIterations; i++) {
        if (currentDepth < 400) {
          for (int b = 0; b < 10; b++) {
            dummyNew += math.sin(i * 0.05 + b) * 0.15;
          }
        }
        if (currentDepth > 700) {
          for (int j = 0; j < 8; j++) {
            dummyNew += math.sin(i * 0.02 + j) * 0.25;
          }
        }
      }
      stopwatchNew.stop();
      final int timeNewUs = stopwatchNew.elapsedMicroseconds;

      expect(dummyOld, isNot(0));
      expect(dummyNew, isNot(0));

      final double percentSaved = ((timeOldUs - timeNewUs) / timeOldUs) * 100;

      print('\n======================================================');
      print('📊 KẾT QUẢ BENCHMARK 4: TÍNH TOÁN VẬT LÝ _updateParticles ($loopIterations TICKS)');
      print('• Phiên bản CŨ (Tính tất cả thực thể): ${(timeOldUs / 1000).toStringAsFixed(2)} ms');
      print('• Phiên bản MỚI (Lọc thực thể theo độ sâu): ${(timeNewUs / 1000).toStringAsFixed(2)} ms');
      print('👉 TIẾT KIỆM CPU VẬT LÝ: ${percentSaved.toStringAsFixed(1)}%');
      print('======================================================\n');

      expect(timeNewUs, lessThan(timeOldUs));
    });

    testWidgets('5. Benchmark FloatingCreature: Rebuild Widget Tree (100 animation ticks)', (WidgetTester tester) async {
      int buildCountOld = 0;
      int buildCountNew = 0;

      // --- Giả lập CŨ: AnimatedBuilder không truyền child: widget.child ---
      final animationControllerOld = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 4),
      );
      final animationOld = Tween<double>(begin: -8, end: 8).animate(animationControllerOld);

      final oldWidget = AnimatedBuilder(
        animation: animationOld,
        builder: (context, child) {
          buildCountOld++;
          return Transform.translate(
            offset: Offset(0, animationOld.value),
            child: Builder(
              builder: (context) {
                return Container();
              },
            ),
          );
        },
      );

      await tester.pumpWidget(MaterialApp(home: oldWidget));
      for (int i = 0; i < 100; i++) {
        animationControllerOld.value = i / 100.0;
        await tester.pump();
      }

      // --- Giả lập MỚI: AnimatedBuilder truyền child: cachedWidget ---
      final animationControllerNew = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 4),
      );
      final animationNew = Tween<double>(begin: -8, end: 8).animate(animationControllerNew);

      final cachedChild = Builder(
        builder: (context) {
          buildCountNew++;
          return Container();
        },
      );

      final newWidget = AnimatedBuilder(
        animation: animationNew,
        child: cachedChild,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, animationNew.value),
            child: child,
          );
        },
      );

      await tester.pumpWidget(MaterialApp(home: newWidget));
      for (int i = 0; i < 100; i++) {
        animationControllerNew.value = i / 100.0;
        await tester.pump();
      }

      print('\n======================================================');
      print('📊 KẾT QUẢ BENCHMARK 5: SỐ LẦN RE-BUILD THẺ SINH VẬT TRÊN 100 TICKS');
      print('• Phiên bản CŨ (Không cache child): $buildCountOld lần build lại toàn bộ subtree');
      print('• Phiên bản MỚI (Có cache child):   $buildCountNew lần build (chỉ build đúng 1 lần khởi tạo!)');
      print('👉 TIẾT KIỆM TÁI TẠO WIDGET: ${(((buildCountOld - buildCountNew) / buildCountOld) * 100).toStringAsFixed(1)}%');
      print('======================================================\n');

      expect(buildCountNew, lessThan(buildCountOld));
    });
  });
}
