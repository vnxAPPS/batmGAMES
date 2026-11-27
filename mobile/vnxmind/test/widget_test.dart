import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnxmind/main.dart';
import 'package:vnxmind/progress.dart';
import 'package:vnxmind/progress_scope.dart';
import 'package:vnxmind/puzzles/levels.dart';
import 'package:vnxmind/screens/puzzle_screen.dart';
import 'package:vnxmind/theme.dart';

Future<Progress> _progress([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return Progress(await SharedPreferences.getInstance(), levels.length);
}

void _still(WidgetTester tester) {
  // Фон анимирован бесконечно; с отключёнными анимациями он стоит, и
  // pumpAndSettle завершается.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.byKey(Key('key-$d')));
    await tester.pump();
  }
}

void main() {
  testWidgets('первый уровень: неверно, потом верно, переход дальше',
      (tester) async {
    _still(tester);
    final progress = await _progress();
    await tester.pumpWidget(VnxMindApp(progress: progress));
    await tester.pumpAndSettle();

    expect(find.text('Play'), findsOneWidget);
    await tester.tap(find.byKey(const Key('play')));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);

    await _type(tester, '9');
    await tester.tap(find.byKey(const Key('check')));
    await tester.pumpAndSettle();
    expect(find.text('Not yet. Try again'), findsOneWidget);
    expect(progress.isSolved(0), isFalse);

    await _type(tester, '10');
    expect(find.text('10'), findsWidgets);
    await tester.tap(find.byKey(const Key('check')));
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    // После верного ответа показано правило задачи.
    expect(find.text(levels[0].hint.en), findsOneWidget);
    expect(progress.isSolved(0), isTrue);
    expect(progress.usedHint(0), isFalse);

    await tester.tap(find.byKey(const Key('next')));
    await tester.pumpAndSettle();
    expect(find.text('Level 2'), findsOneWidget);
  });

  testWidgets('подсказка и показ ответа отмечают уровень', (tester) async {
    _still(tester);
    final progress = await _progress();
    await tester.pumpWidget(VnxMindApp(progress: progress));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('play')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hint')));
    await tester.pumpAndSettle();
    expect(find.text(levels[0].hint.en), findsOneWidget);
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text(levels[0].solution.en), findsOneWidget);

    await _type(tester, '${levels[0].answer}');
    await tester.tap(find.byKey(const Key('check')));
    await tester.pumpAndSettle();
    expect(progress.isSolved(0), isTrue);
    expect(progress.usedHint(0), isTrue);
  });

  testWidgets('русский интерфейс', (tester) async {
    _still(tester);
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(VnxMindApp(progress: await _progress()));
    await tester.pumpAndSettle();
    expect(find.text('Играть'), findsOneWidget);
    expect(find.text('Математические загадки'), findsOneWidget);
  });

  testWidgets('прогресс сохраняется и открывает следующий уровень',
      (tester) async {
    final progress = await _progress({'solved': ['0', '1']});
    expect(progress.solvedCount, 2);
    expect(progress.firstUnsolved, 2);
    expect(progress.isUnlocked(2), isTrue);
    expect(progress.isUnlocked(3), isFalse);
  });

  // Каждый уровень на маленьком и большом экране: переполнение раскладки
  // в тестах — ошибка, так что вылезающая за край задача здесь упадёт.
  for (final size in const [Size(320, 640), Size(360, 760), Size(430, 932)]) {
    testWidgets('все уровни помещаются на экране ${size.width}×${size.height}',
        (tester) async {
      _still(tester);
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final progress = await _progress();
      for (var i = 0; i < levels.length; i++) {
        await tester.pumpWidget(ProgressScope(
          progress: progress,
          child: MaterialApp(
            theme: buildTheme(),
            home: PuzzleScreen(key: ValueKey(i), level: i),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'уровень ${i + 1}');
        // Длинный ввод тоже должен помещаться в клетку «?».
        await _type(tester, '8888');
        expect(tester.takeException(), isNull, reason: 'уровень ${i + 1}, ввод');
      }
    });
  }
}
