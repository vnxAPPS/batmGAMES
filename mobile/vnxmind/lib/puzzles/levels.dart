// Уровни vnxMIND. Порядок — по возрастанию сложности; типы чередуются, чтобы
// не надоедало. Каждый уровень проверяется в test/levels_test.dart.
import 'model.dart';

const tri = Shape.triangle;
const circ = Shape.circle;
const sq = Shape.square;

final List<Puzzle> levels = [
  // 1–10: разминка.
  const SequencePuzzle([2, 4, 6, 8, null], AddRule(2), 10),
  PyramidPuzzle([1, 2, 3], {(0, 0), (0, 1), (0, 2)}, (2, 0)),
  ShapesPuzzle(['T+T=6', 'T+C=7', 'C+C=?'], {tri: 3, circ: 4}, 8,
      const Tr('Из первой строки узнай, чему равен треугольник',
          'Use the first line to find the triangle')),
  const SequencePuzzle([5, 10, 15, 20, null], AddRule(5), 25),
  GridPuzzle([[1, 2, 3], [2, 3, 5], [4, 1, null]], GridRules.add, 5),
  TrianglePuzzle(
      const [Tri(1, 2, 3, 6), Tri(2, 3, 4, 9), Tri(3, 4, 5)], TriRules.sum, 12),
  const SequencePuzzle([1, 2, 4, 8, null], MulRule(2), 16),
  PyramidPuzzle([2, 3, 4, 1], {(0, 0), (0, 1), (0, 2), (0, 3)}, (3, 0)),
  ShapesPuzzle(['S+S+S=12', 'S+T=7', 'T*S=?'], {sq: 4, tri: 3}, 12,
      const Tr('Три одинаковых квадрата дают 12 — значит, один квадрат…',
          'Three equal squares make 12, so one square is…')),
  const SequencePuzzle([20, 17, 14, 11, null], AddRule(-3), 8),

  // 11–20.
  const SequencePuzzle([1, 3, 6, 10, null], GrowingAddRule(2, 1), 15),
  GridPuzzle([[2, 3, 6], [4, 2, 8], [3, 5, null]], GridRules.mul, 15),
  TrianglePuzzle(const [Tri(2, 1, 3, 8), Tri(3, 2, 2, 12), Tri(2, 4, 5)],
      TriRules.lrTimesT, 18),
  PyramidPuzzle([3, 4, 5], {(0, 0), (1, 0), (0, 2)}, (0, 1)),
  const SequencePuzzle([1, 1, 2, 3, 5, 8, null], FibRule(), 13),
  ShapesPuzzle(['C+C=10', 'C-T=2', 'C+T+S=12', 'S=?'], {circ: 5, tri: 3, sq: 4}, 4,
      const Tr('Начни с круга, потом найди треугольник',
          'Start with the circle, then find the triangle')),
  GridPuzzle([[5, 2, 4], [3, 6, 1], [8, 8, null]], GridRules.add, 5,
      byColumns: true),
  const SequencePuzzle([3, 6, 12, 24, null], MulRule(2), 48),
  TrianglePuzzle(const [Tri(2, 3, 4, 10), Tri(5, 2, 6, 7), Tri(4, 5, 3)],
      TriRules.lrMinusT, 11),
  PyramidPuzzle([4, 1, 3, 2], {(0, 0), (0, 2), (1, 0), (1, 2)}, (3, 0)),

  // 21–30.
  const SequencePuzzle([2, 3, 5, 8, 12, null], GrowingAddRule(1, 1), 17),
  ShapesPuzzle(['T*T=16', 'T+C=9', 'C*C-T=?'], {tri: 4, circ: 5}, 21,
      const Tr('Какое число, умноженное само на себя, даёт 16?',
          'Which number times itself makes 16?')),
  GridPuzzle([[3, 4, 11], [5, 2, 9], [6, 3, null]], GridRules.mulMinus1, 17),
  const SequencePuzzle([1, 4, 3, 6, 5, 8, null],
      CycleRule([Step.add(3), Step.add(-1)]), 7),
  TrianglePuzzle(const [Tri(2, 3, 1, 7), Tri(4, 2, 3, 11), Tri(3, 5, 2)],
      TriRules.tlPlusR, 17),
  const SequencePuzzle([1, 4, 9, 16, 25, null], SquareRule(), 36),
  PyramidPuzzle([2, 5, 1, 4], {(3, 0), (2, 0), (1, 2), (0, 3), (0, 0)}, (0, 1)),
  ShapesPuzzle(['T+C=10', 'T-C=4', 'S+C=8', 'T+S*C=?'], {tri: 7, circ: 3, sq: 5}, 22,
      const Tr('Сумма треугольника и круга 10, а разность 4. И помни: '
          'умножение выполняется раньше сложения',
          'Their sum is 10 and the difference is 4. And remember: '
          'multiply before you add')),
  GridPuzzle([[2, 3, 4], [5, 2, 3], [10, 6, null]], GridRules.mul, 12,
      byColumns: true),
  const SequencePuzzle([2, 6, 18, 54, null], MulRule(3), 162),

  // 31–40.
  const SequencePuzzle([1, 3, 7, 15, 31, null], MulAddRule(2, 1), 63),
  TrianglePuzzle(const [Tri(5, 2, 3, 9), Tri(7, 3, 2, 8), Tri(9, 4, 3)],
      TriRules.tMinusLTimesR, 15),
  PyramidPuzzle(
      [1, 2, 3, 4, 5], {(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)}, (4, 0)),
  GridPuzzle([[1, 2, 6], [3, 4, 14], [5, 2, null]], GridRules.sum2x, 14),
  ShapesPuzzle(['C+C+C=15', 'T*C=20', 'S-T=3', 'S+T*C=?'], {circ: 5, tri: 4, sq: 7},
      27, const Tr('Круг найдёшь из первой строки, дальше по цепочке',
          'Find the circle from the first line, then follow the chain')),
  const SequencePuzzle([2, 4, 5, 10, 11, 22, null],
      CycleRule([Step.mul(2), Step.add(1)]), 23),
  TrianglePuzzle(const [Tri(1, 2, 3, 7), Tri(4, 3, 2, 10), Tri(5, 4, 4)],
      TriRules.tPlusLR, 21),
  const SequencePuzzle([1, 8, 27, 64, null], CubeRule(), 125),
  PyramidPuzzle([3, 1, 4, 1, 5],
      {(4, 0), (3, 0), (2, 2), (1, 3), (0, 4), (0, 0), (0, 1)}, (0, 2)),
  GridPuzzle([[2, 3, 7], [3, 1, 10], [4, 2, null]], GridRules.sqPlus, 18),

  // 41–50.
  const SequencePuzzle([2, 2, 4, 6, 10, 16, null], FibRule(), 26),
  ShapesPuzzle(['T+T+C=11', 'C+C+T=13', 'T*C=?'], {tri: 3, circ: 5}, 15,
      const Tr('Подбери треугольник: попробуй числа от 1 до 5',
          'Guess the triangle: try numbers from 1 to 5')),
  TrianglePuzzle(const [Tri(1, 2, 3, 6), Tri(2, 2, 2, 8), Tri(3, 1, 4)],
      TriRules.product, 12),
  const SequencePuzzle([1, 2, 5, 10, 17, null], GrowingAddRule(1, 2), 26),
  GridPuzzle([[9, 7, 8], [4, 2, 5], [5, 5, null]], GridRules.sub, 3,
      byColumns: true),
  PyramidPuzzle([6, 2, 7, 3], {(3, 0), (2, 1), (1, 0), (0, 1), (0, 3)}, (0, 2)),
  ShapesPuzzle(['S+S=8', 'T*S=12', 'C-T=2', 'C*C-S*T=?'], {sq: 4, tri: 3, circ: 5},
      13, const Tr('Иди сверху вниз: каждая строка открывает новую фигуру',
          'Go top to bottom: each line reveals a new shape')),
  const SequencePuzzle([10, 15, 13, 18, 16, 21, null],
      CycleRule([Step.add(5), Step.add(-2)]), 19),
  TrianglePuzzle(const [Tri(1, 2, 3, 12), Tri(2, 4, 1, 14), Tri(3, 3, 5)],
      TriRules.sumTimes2, 22),
  const SequencePuzzle([1, 2, 5, 14, 41, null], MulAddRule(3, -1), 122),

  // 51–60: для самых упорных.
  GridPuzzle([[2, 3, 9], [4, 2, 10], [5, 3, null]], GridRules.mulPlusB, 18),
  PyramidPuzzle([2, 4, 1, 3, 5],
      {(4, 0), (3, 0), (2, 0), (1, 0), (0, 0), (2, 2), (1, 3), (0, 4)}, (0, 2)),
  ShapesPuzzle(['T+C=9', 'C+S=11', 'S+T=10', 'T+C+S=?'], {tri: 4, circ: 5, sq: 6},
      15, const Tr('Сложи все три строки: каждая фигура войдёт дважды',
          'Add all three lines: each shape appears twice')),
  const SequencePuzzle([2, 3, 5, 7, 11, 13, null], PrimeRule(), 17),
  TrianglePuzzle(const [Tri(4, 3, 5, 8), Tri(5, 10, 7, 8), Tri(6, 20, 9)],
      TriRules.tSqMinus, 7),
  GridPuzzle([[3, 4, 5], [5, 2, 3], [6, 3, null]], GridRules.mulMinusBoth, 9),
  const SequencePuzzle([5, 10, 7, 14, 11, 22, null],
      CycleRule([Step.mul(2), Step.add(-3)]), 19),
  PyramidPuzzle([5, 3, 6, 2, 4],
      {(4, 0), (3, 1), (2, 0), (1, 3), (0, 4), (0, 2), (0, 0)}, (0, 1)),
  ShapesPuzzle(['T+T+T=18', 'T/C=3', 'S*C=10', 'S+T/C*S=?'],
      {tri: 6, circ: 2, sq: 5}, 20,
      const Tr('Умножение и деление — раньше сложения, по порядку слева направо',
          'Multiply and divide before adding, left to right')),
  TrianglePuzzle(const [Tri(2, 4, 3, 8), Tri(3, 5, 4, 14), Tri(5, 6, 7)],
      TriRules.lrMinus2t, 32),
];
