import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:noiso_biensau/main.dart';
import 'package:noiso_biensau/services/data_service.dart';
import 'package:noiso_biensau/services/sound_service.dart';
import 'package:noiso_biensau/services/locale_service.dart';
import 'package:noiso_biensau/services/ad_service.dart';

void main() {
  testWidgets('App root smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataService()),
          ChangeNotifierProvider(create: (_) => SoundService()),
          ChangeNotifierProvider(create: (_) => LocaleService()),
          ChangeNotifierProvider(create: (_) => AdService()),
        ],
        child: const MyApp(),
      ),
    );

    // Drain timers from splash screen and home screen
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    // Verify MaterialApp builds
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
