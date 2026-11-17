import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noiso_biensau/models/creature.dart';

double calculateDepthFromScroll({
  required double currentOffset,
  required double maxScroll,
  required double viewportDimension,
  required List<Creature> filtered,
}) {
  if (currentOffset <= 550.0) {
    return 0.0;
  }

  if (filtered.isEmpty) {
    if (maxScroll <= 550.0) return 0.0;
    final underwaterProgress = ((currentOffset - 550.0) / (maxScroll - 550.0)).clamp(0.0, 1.0);
    return underwaterProgress * 11000.0;
  }

  const double listStartOffset = 640.0 + 289.0 + 76.0; // 1005.0
  const double itemExtent = 414.0; // 390.0 + 24.0
  const double cardCenterRelative = itemExtent / 2; // 207.0

  final double focalLine = viewportDimension * 0.42;
  final double focalOffset = currentOffset + focalLine;

  final double firstCardCenter = listStartOffset + cardCenterRelative;
  final double firstDepth = filtered.first.minDepth.toDouble();

  if (focalOffset < firstCardCenter) {
    final double surfaceFocalOffset = 550.0 + focalLine;
    if (focalOffset <= surfaceFocalOffset) {
      return 0.0;
    }
    final double span = firstCardCenter - surfaceFocalOffset;
    if (span <= 0) return firstDepth;
    final double t = ((focalOffset - surfaceFocalOffset) / span).clamp(0.0, 1.0);
    return t * firstDepth;
  }

  final double lastCardCenter = listStartOffset + (filtered.length - 1) * itemExtent + cardCenterRelative;
  final double lastDepth = filtered.last.minDepth.toDouble();

  if (focalOffset <= lastCardCenter) {
    final double floatIndex = (focalOffset - firstCardCenter) / itemExtent;
    final int index = floatIndex.floor().clamp(0, filtered.length - 1);
    final double frac = (floatIndex - index).clamp(0.0, 1.0);

    if (index >= filtered.length - 1) {
      return lastDepth;
    }

    final double depthA = filtered[index].minDepth.toDouble();
    final double depthB = filtered[index + 1].minDepth.toDouble();
    return depthA + (depthB - depthA) * frac;
  }

  final double trenchStartOffset = lastCardCenter - focalLine;
  if (maxScroll <= trenchStartOffset) {
    return 11000.0;
  }
  final double trenchProgress = ((currentOffset - trenchStartOffset) / (maxScroll - trenchStartOffset)).clamp(0.0, 1.0);
  return (lastDepth + (11000.0 - lastDepth) * trenchProgress).clamp(0.0, 11000.0);
}

void main() {
  late List<Creature> allCreatures;

  setUpAll(() {
    final file = File('assets/data/creatures.json');
    final jsonString = file.readAsStringSync();
    final List<dynamic> decoded = jsonDecode(jsonString);
    allCreatures = decoded.map((c) => Creature.fromJson(c)).toList();
  });

  group('Depth Progression and Synchronization Tests', () {
    test('Creatures are strictly sorted by depth with no inverted ordering', () {
      expect(allCreatures.isNotEmpty, isTrue);

      int previousDepth = -1;
      for (final creature in allCreatures) {
        expect(creature.minDepth >= previousDepth, isTrue,
            reason: '${creature.name} (${creature.minDepth}m) is shallower than previous (${previousDepth}m)');
        previousDepth = creature.minDepth;
      }
    });

    test('Real creatures start near surface (0m) and end in hadal abyss (>8000m)', () {
      final real = allCreatures.where((c) => c.isReal).toList();
      expect(real.isNotEmpty, isTrue);
      expect(real.first.minDepth, equals(0));
      expect(real.last.minDepth, greaterThanOrEqualTo(8000));
    });

    test('Titanic shipwreck is placed accurately at 3800m', () {
      final wrecks = allCreatures.where((c) => c.isShipwreck).toList();
      expect(wrecks.isNotEmpty, isTrue);
      final titanic = wrecks.firstWhere((w) => w.id == 'wreck_titanic');
      expect(titanic.minDepth, equals(3800));
    });

    test('Depth calculation returns 0m above water surface', () {
      final depth = calculateDepthFromScroll(
        currentOffset: 200.0,
        maxScroll: 12000.0,
        viewportDimension: 850.0,
        filtered: allCreatures,
      );
      expect(depth, equals(0.0));
    });

    test('Depth calculation aligns exactly with visible creature card in viewport center', () {
      const double listStartOffset = 1005.0;
      const double itemExtent = 414.0;
      const double viewportDimension = 850.0;
      const double focalLine = viewportDimension * 0.42;

      // Verify each creature when its card is centered at the focal line
      for (int i = 0; i < allCreatures.length; i++) {
        final cardCenter = listStartOffset + i * itemExtent + 207.0;
        final offset = cardCenter - focalLine;

        final depth = calculateDepthFromScroll(
          currentOffset: offset,
          maxScroll: 15000.0,
          viewportDimension: viewportDimension,
          filtered: allCreatures,
        );

        expect(depth, closeTo(allCreatures[i].minDepth.toDouble(), 0.1),
            reason: 'Creature $i (${allCreatures[i].name}) depth must match its card badge');
      }
    });

    test('Depth calculation reaches 11000m at bottom of Mariana Trench', () {
      const double maxScroll = 13500.0;
      final depth = calculateDepthFromScroll(
        currentOffset: maxScroll,
        maxScroll: maxScroll,
        viewportDimension: 850.0,
        filtered: allCreatures,
      );
      expect(depth, equals(11000.0));
    });
  });
}
