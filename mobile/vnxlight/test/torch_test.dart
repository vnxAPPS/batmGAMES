import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnxlight/torch.dart';

const _channel = MethodChannel('vnxlight/torch');

/// Подменяет нативную часть: отвечает на `info` и записывает уровни `set`.
List<int> _fakeFlash({bool available = true, int maxLevel = 10}) {
  final levels = <int>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    switch (call.method) {
      case 'info':
        return {'available': available, 'maxLevel': maxLevel};
      case 'set':
        levels.add((call.arguments as Map)['level'] as int);
        return true;
    }
    return null;
  });
  return levels;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('читает, есть ли вспышка и сколько у неё ступеней', () async {
    _fakeFlash(maxLevel: 45);
    final t = TorchController(channel: _channel);
    await t.init();
    expect(t.available, isTrue);
    expect(t.maxLevel, 45);
    expect(t.dimmable, isTrue);
    expect(t.on, isFalse);
  });

  test('кнопка включает на полную, потом выключает', () async {
    final levels = _fakeFlash(maxLevel: 10);
    final t = TorchController(channel: _channel);
    await t.init();
    t.toggle();
    await _settle();
    expect(t.on, isTrue);
    expect(levels.last, 10);
    t.toggle();
    await _settle();
    expect(t.on, isFalse);
    expect(levels.last, 0);
  });

  test('полоска задаёт ступень, низ полоски выключает', () async {
    final levels = _fakeFlash(maxLevel: 10);
    final t = TorchController(channel: _channel);
    await t.init();
    t.setValue(0.5);
    await _settle();
    expect(levels.last, 5);
    t.setValue(0.01);
    await _settle();
    expect(t.on, isFalse);
    expect(levels.last, 0);
  });

  test('после «опустил до низа» кнопка зажигает прежнюю яркость, а не точку',
      () async {
    final levels = _fakeFlash(maxLevel: 10);
    final t = TorchController(channel: _channel);
    await t.init();
    t.setValue(0.6);
    t.setValue(0.05);
    t.setValue(0);
    await _settle();
    t.toggle();
    await _settle();
    expect(levels.last, 6);
  });

  test('самая малая яркость — не ноль, а первая ступень', () async {
    final levels = _fakeFlash(maxLevel: 10);
    final t = TorchController(channel: _channel);
    await t.init();
    t.setValue(0.04);
    await _settle();
    expect(t.hardwareLevel, 1);
    expect(levels.last, 1);
  });

  test('вспышка без ступеней получает только вкл/выкл', () async {
    final levels = _fakeFlash(maxLevel: 1);
    final t = TorchController(channel: _channel);
    await t.init();
    expect(t.dimmable, isFalse);
    t.setValue(0.3);
    await _settle();
    expect(levels.last, 1);
  });

  test('без нативной части (нет вспышки) ничего не падает', () async {
    final t = TorchController(channel: _channel);
    await t.init();
    expect(t.available, isFalse);
    t.toggle();
    await _settle();
    expect(t.on, isTrue);
  });

  test('вспышку выключили из шторки — экран это видит', () async {
    _fakeFlash();
    final t = TorchController(channel: _channel);
    await t.init();
    t.toggle();
    await _settle();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'vnxlight/torch',
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('changed', {'on': false})),
      (_) {},
    );
    expect(t.on, isFalse);
  });
}
