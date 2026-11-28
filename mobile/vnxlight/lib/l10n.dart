import 'package:flutter/widgets.dart';

class L10n {
  const L10n(this.ru);

  final bool ru;

  static L10n of(BuildContext context) =>
      L10n(Localizations.localeOf(context).languageCode == 'ru');

  String get turnOn => ru ? 'Включить фонарик' : 'Turn on flashlight';
  String get turnOff => ru ? 'Выключить фонарик' : 'Turn off flashlight';
  String get brightness => ru ? 'Яркость' : 'Brightness';
  String get noFlash => ru
      ? 'Вспышка не найдена — светит экран'
      : 'No flash found — the screen is the light';
}
