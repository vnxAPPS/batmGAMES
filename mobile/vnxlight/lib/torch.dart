import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Состояние фонарика и связь со вспышкой через канал `vnxlight/torch`
/// (MainActivity.kt).
///
/// [value] — яркость 0..1, где 0 — выключено. Полоска яркости и кнопка
/// меняют одно и то же значение, поэтому опустить полоску до низа — то же,
/// что выключить.
class TorchController extends ChangeNotifier {
  TorchController({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('vnxlight/torch') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;

  /// Есть ли вспышка. Без неё фонарик светит только экраном (лучом).
  bool available = false;

  /// Ступеней яркости у вспышки; 1 — только вкл/выкл.
  int maxLevel = 1;

  /// Ниже этого полоска считается опущенной до конца: свет гаснет.
  static const offThreshold = 0.03;

  /// Слабее этого яркость не запоминается для следующего включения кнопкой:
  /// иначе после «опустил до низа» кнопка зажгла бы едва заметный свет.
  static const rememberThreshold = 0.15;

  double _value = 0;
  double _restore = 1;

  double get value => _value;
  bool get on => _value > 0;

  /// Яркость реально регулируется (Android 13+ и многоуровневая вспышка).
  bool get dimmable => maxLevel > 1;

  /// Ступень, которую получает вспышка: 0 — выключить.
  int get hardwareLevel =>
      _value <= 0 ? 0 : math.max(1, (_value * maxLevel).ceil());

  Future<void> init() async {
    try {
      final info = await _channel.invokeMapMethod<String, Object?>('info');
      available = info?['available'] == true;
      maxLevel = math.max(1, (info?['maxLevel'] as int?) ?? 1);
    } on PlatformException {
      available = false;
    } on MissingPluginException {
      available = false;
    }
    notifyListeners();
  }

  void toggle() => setValue(on ? 0 : _restore);

  void setValue(double v) {
    var next = v.clamp(0.0, 1.0);
    if (next < offThreshold) next = 0;
    if (next >= rememberThreshold) _restore = next;
    if (next == _value) return;
    _value = next;
    notifyListeners();
    _apply();
  }

  bool _busy = false;
  bool _pending = false;
  int _sent = 0;

  /// Вызовы к вспышке идут по одному: при движении пальца по полоске новых
  /// значений больше, чем вспышка успевает принять, и отправляется только
  /// последнее.
  Future<void> _apply() async {
    _pending = true;
    if (_busy) return;
    _busy = true;
    try {
      while (_pending) {
        _pending = false;
        final level = hardwareLevel;
        if (level == _sent) continue;
        try {
          await _channel.invokeMethod<bool>('set', {'level': level});
          _sent = level;
        } on PlatformException {
          // Камеру заняло другое приложение: состояние экрана оставляем,
          // следующее движение попробует снова.
        } on MissingPluginException {
          return;
        }
      }
    } finally {
      _busy = false;
    }
  }

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method == 'changed') {
      final external = (call.arguments as Map?)?['on'] == true;
      if (external != on) {
        // Вспышку переключили из шторки.
        _value = external ? _restore : 0;
        _sent = hardwareLevel;
        notifyListeners();
      }
    }
    return null;
  }
}
