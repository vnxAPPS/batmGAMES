import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Прогресс игрока. Хранится только на устройстве.
class Progress extends ChangeNotifier {
  Progress(this._prefs, this.total)
    : _solved = _read(_prefs, _solvedKey),
      _hinted = _read(_prefs, _hintedKey);

  static const _solvedKey = 'solved';
  static const _hintedKey = 'hinted';

  final SharedPreferences _prefs;
  final int total;
  final Set<int> _solved;
  final Set<int> _hinted;

  static Set<int> _read(SharedPreferences p, String key) =>
      {for (final s in p.getStringList(key) ?? const <String>[]) ?int.tryParse(s)};

  int get solvedCount => _solved.length;

  bool isSolved(int level) => _solved.contains(level);

  /// Решён с подсказкой или с показанным ответом.
  bool usedHint(int level) => _hinted.contains(level);

  /// Открыт первый уровень и каждый, перед которым всё решено подряд, —
  /// плюс один следующий.
  bool isUnlocked(int level) => level <= firstUnsolved;

  /// Первый нерешённый уровень; total — если решены все.
  int get firstUnsolved {
    for (var i = 0; i < total; i++) {
      if (!_solved.contains(i)) return i;
    }
    return total;
  }

  bool get allSolved => firstUnsolved >= total;

  Future<void> markSolved(int level) async {
    if (_solved.add(level)) {
      notifyListeners();
      await _prefs.setStringList(_solvedKey, [for (final i in _solved) '$i']);
    }
  }

  Future<void> markHinted(int level) async {
    if (_hinted.add(level)) {
      notifyListeners();
      await _prefs.setStringList(_hintedKey, [for (final i in _hinted) '$i']);
    }
  }

  Future<void> reset() async {
    _solved.clear();
    _hinted.clear();
    notifyListeners();
    await _prefs.remove(_solvedKey);
    await _prefs.remove(_hintedKey);
  }
}
