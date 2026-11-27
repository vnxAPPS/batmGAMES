// Проверка каждого уровня исполнением его правила: видимые числа должны
// подчиняться правилу, ответ — из него следовать, а задача — решаться
// однозначно. Ошибка в уровне детской головоломки хуже любого бага в коде:
// ребёнок решит верно, а игра скажет «неверно».
import 'package:flutter_test/flutter_test.dart';
import 'package:vnxmath/puzzles/levels.dart';
import 'package:vnxmath/puzzles/model.dart';

void main() {
  test('уровней 60, ответы положительные и помещаются в поле ввода', () {
    expect(levels, hasLength(60));
    for (final (i, p) in levels.indexed) {
      expect(p.answer, greaterThan(0), reason: 'уровень ${i + 1}');
      expect(p.answer, lessThan(10000), reason: 'уровень ${i + 1}');
    }
  });

  test('подсказки не пустые на обоих языках', () {
    for (final (i, p) in levels.indexed) {
      expect(p.hint.ru.trim(), isNotEmpty, reason: 'уровень ${i + 1}');
      expect(p.hint.en.trim(), isNotEmpty, reason: 'уровень ${i + 1}');
      expect(p.solution.ru, contains('${p.answer}'), reason: 'уровень ${i + 1}');
    }
  });

  test('числовые ряды подчиняются своему правилу', () {
    for (final (i, p) in levels.indexed) {
      if (p is! SequencePuzzle) continue;
      final q = p.items.indexOf(null);
      expect(q, isNot(-1), reason: 'уровень ${i + 1}: нет «?»');
      expect(p.items.where((x) => x == null), hasLength(1),
          reason: 'уровень ${i + 1}');
      final seq = [for (final x in p.items) x ?? p.answer];
      for (var k = p.rule.seeds; k < seq.length; k++) {
        expect(seq[k], p.rule.next(seq.sublist(0, k)),
            reason: 'уровень ${i + 1}, число №${k + 1}');
      }
      expect(p.items.length - 1, greaterThanOrEqualTo(3),
          reason: 'уровень ${i + 1}: мало чисел, чтобы угадать правило');
    }
  });

  test('треугольники: правило сходится и не путается с другими', () {
    for (final (i, p) in levels.indexed) {
      if (p is! TrianglePuzzle) continue;
      final examples = p.tris.where((t) => t.center != null).toList();
      final unknown = p.tris.where((t) => t.center == null).toList();
      expect(unknown, hasLength(1), reason: 'уровень ${i + 1}');
      expect(examples.length, greaterThanOrEqualTo(2), reason: 'уровень ${i + 1}');
      for (final t in examples) {
        expect(p.rule.apply(t.top, t.left, t.right), t.center,
            reason: 'уровень ${i + 1}');
      }
      final u = unknown.single;
      expect(p.rule.apply(u.top, u.left, u.right), p.answer,
          reason: 'уровень ${i + 1}');
      // Любое другое правило из набора, подходящее к примерам, обязано
      // давать тот же ответ: иначе у задачи два верных решения.
      for (final other in TriRules.all) {
        final fits = examples
            .every((t) => other.apply(t.top, t.left, t.right) == t.center);
        if (fits) {
          expect(other.apply(u.top, u.left, u.right), p.answer,
              reason: 'уровень ${i + 1}: неоднозначно (${other.hint.ru})');
        }
      }
    }
  });

  test('таблицы 3×3: правило сходится и не путается с другими', () {
    for (final (i, p) in levels.indexed) {
      if (p is! GridPuzzle) continue;
      List<List<int?>> lines(List<List<int?>> c) => p.byColumns
          ? [for (var col = 0; col < 3; col++) [for (var r = 0; r < 3; r++) c[r][col]]]
          : c;
      final ls = lines(p.cells);
      expect(ls.expand((l) => l).where((x) => x == null), hasLength(1),
          reason: 'уровень ${i + 1}');
      final complete = ls.where((l) => !l.contains(null)).toList();
      final open = ls.singleWhere((l) => l.contains(null));
      expect(open.indexOf(null), 2,
          reason: 'уровень ${i + 1}: «?» должен быть результатом');
      for (final l in complete) {
        expect(p.rule.apply(l[0]!, l[1]!), l[2], reason: 'уровень ${i + 1}');
      }
      expect(p.rule.apply(open[0]!, open[1]!), p.answer,
          reason: 'уровень ${i + 1}');
      for (final other in GridRules.all) {
        final fits = complete.every((l) => other.apply(l[0]!, l[1]!) == l[2]);
        if (fits) {
          expect(other.apply(open[0]!, open[1]!), p.answer,
              reason: 'уровень ${i + 1}: неоднозначно (${other.hint.ru})');
        }
      }
    }
  });

  test('фигуры: все уравнения верны, значения находятся однозначно', () {
    for (final (i, p) in levels.indexed) {
      if (p is! ShapesPuzzle) continue;
      final last = p.equations.last;
      expect(last.right, isNull, reason: 'уровень ${i + 1}');
      for (final e in p.equations.take(p.equations.length - 1)) {
        expect(e.evaluate(p.values), e.right, reason: 'уровень ${i + 1}');
      }
      expect(last.evaluate(p.values), p.answer, reason: 'уровень ${i + 1}');

      // Перебор всех значений фигур от 1 до 30: решения уравнений, кроме
      // последнего, должны давать один и тот же ответ.
      final shapes = p.values.keys.toList();
      final answers = <int>{};
      void search(int k, Map<Shape, int> v) {
        if (k == shapes.length) {
          final ok = p.equations
              .take(p.equations.length - 1)
              .every((e) => e.evaluate(v) == e.right);
          if (ok) {
            final a = last.evaluate(v);
            if (a != null) answers.add(a);
          }
          return;
        }
        for (var x = 1; x <= 30; x++) {
          v[shapes[k]] = x;
          search(k + 1, v);
        }
        v.remove(shapes[k]);
      }

      search(0, {});
      expect(answers, {p.answer}, reason: 'уровень ${i + 1}');
    }
  });

  test('пирамиды: «?» выводится из видимых блоков', () {
    for (final (i, p) in levels.indexed) {
      if (p is! PyramidPuzzle) continue;
      expect(p.visible.contains(p.question), isFalse, reason: 'уровень ${i + 1}');
      // Решатель повторяет рассуждение игрока: блок известен, если известны
      // оба под ним, либо он сам и один из соседей под ним.
      final known = <Cell, int>{
        for (final c in p.visible) c: p.full[c.$1][c.$2],
      };
      var progress = true;
      while (progress) {
        progress = false;
        for (var r = 1; r < p.height; r++) {
          for (var c = 0; c < p.height - r; c++) {
            final top = (r, c), a = (r - 1, c), b = (r - 1, c + 1);
            void put(Cell cell, int v) {
              if (!known.containsKey(cell)) {
                known[cell] = v;
                progress = true;
              }
            }

            if (known.containsKey(a) && known.containsKey(b)) {
              put(top, known[a]! + known[b]!);
            }
            if (known.containsKey(top) && known.containsKey(a)) {
              put(b, known[top]! - known[a]!);
            }
            if (known.containsKey(top) && known.containsKey(b)) {
              put(a, known[top]! - known[b]!);
            }
          }
        }
      }
      expect(known[p.question], p.answer, reason: 'уровень ${i + 1}');
      for (final e in known.entries) {
        expect(e.value, p.full[e.key.$1][e.key.$2], reason: 'уровень ${i + 1}');
      }
    }
  });

  test('склонение «раза/раз» в подсказках', () {
    expect(const MulRule(2).hint.ru, contains('в 2 раза'));
    expect(const MulRule(5).hint.ru, contains('в 5 раз '));
    expect(const MulRule(12).hint.ru, contains('в 12 раз '));
    expect(const MulRule(22).hint.ru, contains('в 22 раза'));
  });
}
