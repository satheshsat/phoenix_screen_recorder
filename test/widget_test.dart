import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phoenix_screen_recorder/main.dart';
import 'package:phoenix_screen_recorder/services/recording_service.dart';

void main() {
  testWidgets('Phoenix Screen Recorder UI smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final service = RecordingService();

    await tester.pumpWidget(PhoenixScreenRecorderApp(service: service));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Phoenix Screen Recorder'), findsWidgets);
    expect(find.text('START RECORDING'), findsOneWidget);

    expect(find.text('Background Sound'), findsOneWidget);
    expect(find.text('Microphone Audio'), findsOneWidget);

    expect(find.byType(Switch), findsNWidgets(2));

    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 100));

    service.dispose();
  });
}
