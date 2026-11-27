import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnxlight/main.dart';
import 'package:vnxlight/torch.dart';

const _channel = MethodChannel('vnxlight/torch');

Future<(TorchController, List<int>)> _torch({bool available = true}) async {
  final levels = <int>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    if (call.method == 'info') {
      return {'available': available, 'maxLevel': 10};
    }
    if (call.method == 'set') {
      levels.add((call.arguments as Map)['level'] as int);
      return true;
    }
    return null;
  });
  final t = TorchController(channel: _channel);
  await t.init();
  return (t, levels);
}

void _still(WidgetTester tester) {
  // Символы в луче плывут бесконечно; с отключёнными анимациями они стоят.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  testWidgets('кнопка включает и выключает фонарик', (tester) async {
    _still(tester);
    final (torch, levels) = await _torch();
    await tester.pumpWidget(VnxLightApp(torch: torch));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Turn on flashlight'), findsOneWidget);
    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(torch.on, isTrue);
    expect(levels.last, 10);
    expect(find.bySemanticsLabel('Turn off flashlight'), findsOneWidget);

    await tester.tap(find.byKey(const Key('power')));
    await tester.pumpAndSettle();
    expect(torch.on, isFalse);
    expect(levels.last, 0);
  });

  testWidgets('палец по полоске меняет яркость, внизу — выключено',
      (tester) async {
    _still(tester);
    final (torch, levels) = await _torch();
    await tester.pumpWidget(VnxLightApp(torch: torch));
    await tester.pumpAndSettle();

    final slider = find.byKey(const Key('brightness'));
    final rect = tester.getRect(slider);
    // Касание в середине полоски — половина яркости.
    await tester.tapAt(rect.center);
    await tester.pumpAndSettle();
    expect(torch.value, closeTo(0.5, 0.05));
    expect(levels.last, 5);

    // Протянуть к самому низу — выключить.
    await tester.dragFrom(rect.center, Offset(0, rect.height));
    await tester.pumpAndSettle();
    expect(torch.on, isFalse);
    expect(levels.last, 0);
  });

  testWidgets('без вспышки показывает подсказку и всё равно светит экраном',
      (tester) async {
    _still(tester);
    final (torch, _) = await _torch(available: false);
    await tester.pumpWidget(VnxLightApp(torch: torch));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('no-flash')), findsNothing);
    await tester.tap(find.byKey(const Key('power')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(torch.on, isTrue);
    expect(find.byKey(const Key('no-flash')), findsOneWidget);
  });

  testWidgets('русский интерфейс', (tester) async {
    _still(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final (torch, _) = await _torch();
    await tester.pumpWidget(VnxLightApp(torch: torch));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Включить фонарик'), findsOneWidget);
  });

  for (final size in const [Size(320, 640), Size(360, 760), Size(430, 932)]) {
    testWidgets('раскладка без переполнений на ${size.width}×${size.height}',
        (tester) async {
      _still(tester);
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final (torch, _) = await _torch();
      await tester.pumpWidget(VnxLightApp(torch: torch));
      await tester.pumpAndSettle();
      torch.setValue(1);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Кнопка и полоска целиком на экране.
      for (final key in const [Key('power'), Key('brightness')]) {
        final r = tester.getRect(find.byKey(key));
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: '$key');
        expect(r.top, greaterThanOrEqualTo(0), reason: '$key');
      }
    });
  }
}
