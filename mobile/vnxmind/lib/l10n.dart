import 'package:flutter/widgets.dart';

/// Строки интерфейса. Язык — системный: русский или английский для всех
/// остальных.
class L10n {
  const L10n(this.ru);

  final bool ru;

  static L10n of(BuildContext context) =>
      L10n(Localizations.localeOf(context).languageCode == 'ru');

  String get tagline => ru ? 'Математические загадки' : 'Math riddles';
  String get subtitle => ru
      ? 'Найди закономерность и впиши число вместо «?»'
      : 'Spot the pattern and replace “?” with a number';
  String get play => ru ? 'Играть' : 'Play';
  String get continueGame => ru ? 'Продолжить' : 'Continue';
  String get levels => ru ? 'Уровни' : 'Levels';
  String level(int n) => ru ? 'Уровень $n' : 'Level $n';
  String solvedOf(int solved, int total) =>
      ru ? 'Решено $solved из $total' : 'Solved $solved of $total';
  String get check => ru ? 'Проверить' : 'Check';
  String get hint => ru ? 'Подсказка' : 'Hint';
  String get showAnswer => ru ? 'Показать ответ' : 'Show answer';
  String get correct => ru ? 'Верно!' : 'Correct!';
  String get wrong => ru ? 'Пока нет. Попробуй ещё' : 'Not yet. Try again';
  String get next => ru ? 'Дальше' : 'Next';
  String get allDone => ru ? 'Все уровни решены!' : 'All levels solved!';
  String get allDoneText => ru
      ? 'Ты прошёл все 60 загадок. Новые уровни уже в работе.'
      : 'You have solved all 60 riddles. New levels are on the way.';
  String get home => ru ? 'На главную' : 'Home';
  String get locked => ru ? 'Сначала реши предыдущий уровень' : 'Solve the previous level first';
  String get resetProgress => ru ? 'Сбросить прогресс' : 'Reset progress';
  String get resetConfirm => ru
      ? 'Все решённые уровни снова станут нерешёнными.'
      : 'All solved levels will become unsolved again.';
  String get cancel => ru ? 'Отмена' : 'Cancel';
  String get reset => ru ? 'Сбросить' : 'Reset';
  String get about => ru ? 'О приложении' : 'About';
  String get aboutText => ru
      ? 'vnxMIND — головоломки с числами для тренировки логики. '
          'Без рекламы, без регистрации, работает без интернета. '
          'Приложение не собирает никаких данных.'
      : 'vnxMIND is a set of number puzzles to train logic. '
          'No ads, no sign-up, works offline. '
          'The app collects no data at all.';
  String get close => ru ? 'Закрыть' : 'Close';
  String get answerLabel => ru ? 'Ответ' : 'Answer';
  String get pyramidTip =>
      ru ? 'Блок = сумма двух под ним' : 'Block = sum of the two below';
}
