// Модель задач vnxMATH.
//
// Каждая задача хранит видимые данные, правило и ответ. Правило — объект с
// функцией и подсказкой на двух языках, поэтому тесты проверяют каждую
// задачу исполнением правила: видимые примеры должны ему подчиняться, а ответ
// должен из него следовать (test/levels_test.dart).

/// Строка на двух языках интерфейса.
class Tr {
  const Tr(this.ru, this.en);

  final String ru;
  final String en;

  String of(bool ru) => ru ? this.ru : en;
}

String _signed(int k) => k >= 0 ? '+$k' : '−${-k}';

/// «в 2 раза», «в 5 раз»: склонение по последней цифре.
String _timesRu(int k) {
  final last = k % 10;
  final lastTwo = k % 100;
  if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) {
    return 'в $k раза';
  }
  return 'в $k раз';
}

sealed class Puzzle {
  const Puzzle();

  int get answer;

  /// Подсказка: как устроено правило, без готового ответа.
  Tr get hint;

  /// Разбор: правило и ответ целиком.
  Tr get solution => Tr(
    '${hint.ru}. Ответ: $answer',
    '${hint.en}. Answer: $answer',
  );
}

// --- Числовые ряды ---------------------------------------------------------

abstract class SeqRule {
  const SeqRule();

  /// Сколько первых чисел ряда задано, а не вычислено правилом.
  int get seeds => 1;

  /// Следующее число по уже известным; prev.length — его номер в ряду.
  int next(List<int> prev);

  Tr get hint;
}

class AddRule extends SeqRule {
  const AddRule(this.k);

  final int k;

  @override
  int next(List<int> prev) => prev.last + k;

  @override
  Tr get hint => k >= 0
      ? Tr('Каждое число больше предыдущего на $k',
          'Each number is $k more than the one before')
      : Tr('Каждое число меньше предыдущего на ${-k}',
          'Each number is ${-k} less than the one before');
}

class MulRule extends SeqRule {
  const MulRule(this.k);

  final int k;

  @override
  int next(List<int> prev) => prev.last * k;

  @override
  Tr get hint => Tr('Каждое число ${_timesRu(k)} больше предыдущего',
      'Each number is $k times the one before');
}

/// Шаг растёт: +first, +(first+inc), +(first+2·inc)…
class GrowingAddRule extends SeqRule {
  const GrowingAddRule(this.first, this.inc);

  final int first;
  final int inc;

  @override
  int next(List<int> prev) => prev.last + first + inc * (prev.length - 1);

  @override
  Tr get hint {
    final steps = [for (var i = 0; i < 3; i++) _signed(first + inc * i)];
    return Tr('Шаг растёт: ${steps.join(', ')}…',
        'The step grows: ${steps.join(', ')}…');
  }
}

class FibRule extends SeqRule {
  const FibRule();

  @override
  int get seeds => 2;

  @override
  int next(List<int> prev) => prev[prev.length - 1] + prev[prev.length - 2];

  @override
  Tr get hint => const Tr('Каждое число — сумма двух предыдущих',
      'Each number is the sum of the two before it');
}

class SquareRule extends SeqRule {
  const SquareRule();

  @override
  int get seeds => 0;

  @override
  int next(List<int> prev) => (prev.length + 1) * (prev.length + 1);

  @override
  Tr get hint => const Tr('Это числа, умноженные сами на себя: 1×1, 2×2, 3×3…',
      'These are numbers multiplied by themselves: 1×1, 2×2, 3×3…');
}

class CubeRule extends SeqRule {
  const CubeRule();

  @override
  int get seeds => 0;

  @override
  int next(List<int> prev) {
    final n = prev.length + 1;
    return n * n * n;
  }

  @override
  Tr get hint => const Tr('Это кубы чисел: 1×1×1, 2×2×2, 3×3×3…',
      'These are cubes: 1×1×1, 2×2×2, 3×3×3…');
}

class PrimeRule extends SeqRule {
  const PrimeRule();

  @override
  int get seeds => 0;

  @override
  int next(List<int> prev) {
    var n = prev.isEmpty ? 2 : prev.last + 1;
    while (!_isPrime(n)) {
      n++;
    }
    return n;
  }

  static bool _isPrime(int n) {
    if (n < 2) return false;
    for (var d = 2; d * d <= n; d++) {
      if (n % d == 0) return false;
    }
    return true;
  }

  @override
  Tr get hint => const Tr('Это простые числа: они делятся только на 1 и на себя',
      'These are primes: divisible only by 1 and themselves');
}

/// Умножить на m и прибавить a.
class MulAddRule extends SeqRule {
  const MulAddRule(this.m, this.a);

  final int m;
  final int a;

  @override
  int next(List<int> prev) => prev.last * m + a;

  @override
  Tr get hint => a >= 0
      ? Tr('Умножь предыдущее на $m и прибавь $a',
          'Multiply the previous one by $m and add $a')
      : Tr('Умножь предыдущее на $m и вычти ${-a}',
          'Multiply the previous one by $m and subtract ${-a}');
}

/// Шаг ряда: умножить или прибавить.
class Step {
  const Step.add(this.k) : mul = false;
  const Step.mul(this.k) : mul = true;

  final bool mul;
  final int k;

  int apply(int x) => mul ? x * k : x + k;

  @override
  String toString() => mul ? '×$k' : _signed(k);
}

/// Действия чередуются по кругу: например ×2, +1, ×2, +1…
class CycleRule extends SeqRule {
  const CycleRule(this.steps);

  final List<Step> steps;

  @override
  int next(List<int> prev) =>
      steps[(prev.length - 1) % steps.length].apply(prev.last);

  @override
  Tr get hint {
    final s = steps.join(', ');
    return Tr('Действия чередуются: $s, и снова по кругу',
        'The steps alternate: $s, and round again');
  }
}

class SequencePuzzle extends Puzzle {
  const SequencePuzzle(this.items, this.rule, this.answer);

  /// Числа ряда; null — клетка «?».
  final List<int?> items;
  final SeqRule rule;
  @override
  final int answer;

  @override
  Tr get hint => rule.hint;
}

// --- Треугольники ----------------------------------------------------------

class TriRule {
  const TriRule(this.apply, this.hint);

  final int Function(int top, int left, int right) apply;
  final Tr hint;
}

class TriRules {
  static final sum = TriRule((t, l, r) => t + l + r,
      const Tr('В центре — сумма трёх чисел по углам',
          'The center is the sum of the three corners'));
  static final lrTimesT = TriRule((t, l, r) => (l + r) * t,
      const Tr('Сложи нижние числа и умножь на верхнее',
          'Add the bottom numbers and multiply by the top one'));
  static final lrMinusT = TriRule((t, l, r) => l * r - t,
      const Tr('Перемножь нижние числа и вычти верхнее',
          'Multiply the bottom numbers and subtract the top one'));
  static final tlPlusR = TriRule((t, l, r) => t * l + r,
      const Tr('Умножь верхнее на левое и прибавь правое',
          'Multiply the top by the left and add the right'));
  static final tMinusLTimesR = TriRule((t, l, r) => (t - l) * r,
      const Tr('Из верхнего вычти левое и умножь на правое',
          'Subtract the left from the top and multiply by the right'));
  static final tPlusLR = TriRule((t, l, r) => t + l * r,
      const Tr('Перемножь нижние числа и прибавь верхнее',
          'Multiply the bottom numbers and add the top one'));
  static final product = TriRule((t, l, r) => t * l * r,
      const Tr('Перемножь все три числа', 'Multiply all three numbers'));
  static final sumTimes2 = TriRule((t, l, r) => (t + l + r) * 2,
      const Tr('Сложи все три числа и удвой сумму',
          'Add all three numbers and double the sum'));
  static final tSqMinus = TriRule((t, l, r) => t * t - l - r,
      const Tr('Умножь верхнее само на себя и вычти нижние',
          'Square the top number and subtract the bottom ones'));
  static final lrMinus2t = TriRule((t, l, r) => l * r - 2 * t,
      const Tr('Перемножь нижние числа и вычти удвоенное верхнее',
          'Multiply the bottom numbers and subtract twice the top'));

  static final all = [
    sum, lrTimesT, lrMinusT, tlPlusR, tMinusLTimesR,
    tPlusLR, product, sumTimes2, tSqMinus, lrMinus2t,
  ];
}

class Tri {
  const Tri(this.top, this.left, this.right, [this.center]);

  final int top;
  final int left;
  final int right;

  /// null — «?» в центре.
  final int? center;
}

class TrianglePuzzle extends Puzzle {
  const TrianglePuzzle(this.tris, this.rule, this.answer);

  final List<Tri> tris;
  final TriRule rule;
  @override
  final int answer;

  @override
  Tr get hint => rule.hint;
}

// --- Таблица 3×3 -----------------------------------------------------------

class GridRule {
  const GridRule(this.apply, this.hint);

  final int Function(int a, int b) apply;
  final Tr hint;
}

class GridRules {
  static final add = GridRule((a, b) => a + b,
      const Tr('Третье число — сумма первых двух',
          'The third number is the sum of the first two'));
  static final mul = GridRule((a, b) => a * b,
      const Tr('Третье число — произведение первых двух',
          'The third number is the product of the first two'));
  static final sub = GridRule((a, b) => a - b,
      const Tr('Из первого числа вычти второе',
          'Subtract the second number from the first'));
  static final mulMinus1 = GridRule((a, b) => a * b - 1,
      const Tr('Перемножь первые два числа и вычти 1',
          'Multiply the first two numbers and subtract 1'));
  static final sum2x = GridRule((a, b) => (a + b) * 2,
      const Tr('Сложи первые два числа и удвой',
          'Add the first two numbers and double it'));
  static final sqPlus = GridRule((a, b) => a * a + b,
      const Tr('Умножь первое число само на себя и прибавь второе',
          'Square the first number and add the second'));
  static final mulPlusB = GridRule((a, b) => a * b + b,
      const Tr('Перемножь первые два числа и прибавь второе',
          'Multiply the first two numbers and add the second'));
  static final mulMinusBoth = GridRule((a, b) => a * b - a - b,
      const Tr('Перемножь первые два числа и вычти их оба',
          'Multiply the first two numbers and subtract both of them'));

  static final all = [
    add, mul, sub, mulMinus1, sum2x, sqPlus, mulPlusB, mulMinusBoth,
  ];
}

class GridPuzzle extends Puzzle {
  const GridPuzzle(this.cells, this.rule, this.answer, {this.byColumns = false});

  /// Три строки по три числа; null — «?».
  final List<List<int?>> cells;
  final GridRule rule;

  /// Правило идёт сверху вниз по столбцам, а не по строкам.
  final bool byColumns;
  @override
  final int answer;

  @override
  Tr get hint => byColumns
      ? Tr('${rule.hint.ru} — в каждом столбце сверху вниз',
          '${rule.hint.en}, in each column from top to bottom')
      : Tr('${rule.hint.ru} — в каждой строке',
          '${rule.hint.en}, in each row');
}

// --- Уравнения с фигурами --------------------------------------------------

enum Shape { triangle, circle, square, star }

/// Элемент уравнения: фигура, число или знак (+ − × ÷).
class Token {
  const Token.shape(Shape this.shape) : number = null, op = null;
  const Token.number(int this.number) : shape = null, op = null;
  const Token.op(String this.op) : shape = null, number = null;

  final Shape? shape;
  final int? number;
  final String? op;
}

class Equation {
  const Equation(this.left, this.right);

  /// Разбирает запись вида 'T+T=6' или 'C*C-T=?'.
  /// T — треугольник, C — круг, S — квадрат, R — звезда;
  /// знаки + - * / показываются как + − × ÷.
  factory Equation.parse(String text) {
    final parts = text.split('=');
    final tokens = <Token>[];
    final number = StringBuffer();
    void flush() {
      if (number.isNotEmpty) {
        tokens.add(Token.number(int.parse(number.toString())));
        number.clear();
      }
    }

    for (final ch in parts[0].split('')) {
      switch (ch) {
        case 'T':
          flush();
          tokens.add(const Token.shape(Shape.triangle));
        case 'C':
          flush();
          tokens.add(const Token.shape(Shape.circle));
        case 'S':
          flush();
          tokens.add(const Token.shape(Shape.square));
        case 'R':
          flush();
          tokens.add(const Token.shape(Shape.star));
        case '+':
          flush();
          tokens.add(const Token.op('+'));
        case '-':
          flush();
          tokens.add(const Token.op('−'));
        case '*':
          flush();
          tokens.add(const Token.op('×'));
        case '/':
          flush();
          tokens.add(const Token.op('÷'));
        default:
          number.write(ch);
      }
    }
    flush();
    final right = parts[1].trim();
    return Equation(tokens, right == '?' ? null : int.parse(right));
  }

  final List<Token> left;

  /// null — «?».
  final int? right;

  /// Значение левой части: × и ÷ раньше + и −, слева направо.
  /// null, если деление не нацело.
  int? evaluate(Map<Shape, int> values) {
    final nums = <int>[];
    final ops = <String>[];
    for (final t in left) {
      if (t.op != null) {
        ops.add(t.op!);
      } else {
        nums.add(t.number ?? values[t.shape]!);
      }
    }
    // Первый проход: × и ÷.
    final n2 = <int>[nums.first];
    final o2 = <String>[];
    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      final x = nums[i + 1];
      if (op == '×') {
        n2.add(n2.removeLast() * x);
      } else if (op == '÷') {
        final a = n2.removeLast();
        if (x == 0 || a % x != 0) return null;
        n2.add(a ~/ x);
      } else {
        o2.add(op);
        n2.add(x);
      }
    }
    var result = n2.first;
    for (var i = 0; i < o2.length; i++) {
      result = o2[i] == '+' ? result + n2[i + 1] : result - n2[i + 1];
    }
    return result;
  }
}

class ShapesPuzzle extends Puzzle {
  ShapesPuzzle(List<String> lines, this.values, this.answer, this._hint)
    : equations = [for (final l in lines) Equation.parse(l)];

  final List<Equation> equations;

  /// Значения фигур: для проверки в тестах и для разбора.
  final Map<Shape, int> values;
  @override
  final int answer;
  final Tr _hint;

  @override
  Tr get hint => _hint;

  @override
  Tr get solution {
    const ru = {
      Shape.triangle: '▲', Shape.circle: '●', Shape.square: '■', Shape.star: '★',
    };
    final v = values.entries.map((e) => '${ru[e.key]} = ${e.value}').join(', ');
    return Tr('$v. Ответ: $answer', '$v. Answer: $answer');
  }
}

// --- Пирамида сумм ---------------------------------------------------------

typedef Cell = (int row, int col);

class PyramidPuzzle extends Puzzle {
  PyramidPuzzle(this.bottom, this.visible, this.question)
    : full = _build(bottom);

  /// Нижний ряд целиком (он определяет всю пирамиду).
  final List<int> bottom;

  /// Клетки, которые видны игроку. Ряд 0 — нижний.
  final Set<Cell> visible;
  final Cell question;

  /// Все значения: full[ряд][столбец].
  final List<List<int>> full;

  static List<List<int>> _build(List<int> bottom) {
    final rows = [bottom];
    while (rows.last.length > 1) {
      final r = rows.last;
      rows.add([for (var i = 0; i + 1 < r.length; i++) r[i] + r[i + 1]]);
    }
    return rows;
  }

  int get height => bottom.length;

  @override
  int get answer => full[question.$1][question.$2];

  @override
  Tr get hint => const Tr('Каждый блок равен сумме двух блоков под ним',
      'Each block is the sum of the two blocks below it');
}
