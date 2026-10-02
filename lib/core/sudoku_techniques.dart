import 'constants.dart';
import 'sudoku_logic.dart';

/// Logical techniques the hint engine can detect and explain.
///
/// Kept as an enum (rather than inferring from explanation prose) so the
/// targeted generator can match strategies structurally and callers can check
/// support before requesting a technique.
enum SolvingStrategy {
  nakedSingle('Naked Single'),
  hiddenSingle('Hidden Single'),
  lockedCandidates('Locked Candidates'),
  nakedPair('Naked Pair'),
  hiddenPair('Hidden Pair'),
  nakedTriple('Naked Triple'),
  hiddenTriple('Hidden Triple'),
  xWing('X-Wing'),
  swordfish('Swordfish'),
  jellyfish('Jellyfish'),
  finnedXWing('Finned X-Wing'),
  sashimiXWing('Sashimi X-Wing'),
  skyscraper('Skyscraper'),
  twoStringKite('Two-String-Kite'),
  emptyRectangle('Empty Rectangle'),
  yWing('Y-Wing'),
  xyzWing('XYZ-Wing'),
  wWing('W-Wing'),
  simpleColoring('Simple Coloring'),
  xChain('X-Chain'),
  xyChain('XY-Chain'),
  alternatingInferenceChain('Alternating Inference Chain'),
  uniqueRectangles('Unique Rectangles'),
  advancedElimination('Advanced Elimination');

  const SolvingStrategy(this.label);

  /// Name shown in the UI. Must match the strategy picker's strings exactly.
  final String label;
}

/// A candidate digit ruled out at a cell by a technique.
class TechniqueElimination {
  final int row;
  final int col;
  final int digit;

  const TechniqueElimination(this.row, this.col, this.digit);

  String get cellKey => '$row,$col';
  String get label => 'R${row + 1}C${col + 1}:$digit';
}

/// One detected occurrence of a solving technique.
class TechniqueHit {
  final SolvingStrategy strategy;
  final String title;
  final String body;

  /// Candidates this technique proves cannot be placed.
  final List<TechniqueElimination> eliminations;

  /// `"r,c"` keys of cells worth painting as part of the pattern.
  final List<String> highlights;

  const TechniqueHit({
    required this.strategy,
    required this.title,
    required this.body,
    required this.eliminations,
    this.highlights = const [],
  });

  /// Whether this technique rules a candidate out at ([row], [col]), i.e.
  /// whether it can justify the value being placed there.
  bool eliminates(int row, int col) =>
      eliminations.any((e) => e.row == row && e.col == col);

  String render() => '$title\n\n$body';
}

typedef TechCell = ({int r, int c});

/// Pre-computed candidates and unit geometry shared by every detector.
class TechniqueContext {
  final List<List<int>> board;
  final List<List<Set<int>>> cand;
  final List<List<TechCell>> units;

  TechniqueContext(this.board)
    : cand = computeCandidates(board),
      units = buildUnits();

  /// Reuses candidates the caller already computed.
  TechniqueContext.withCandidates(this.board, this.cand)
    : units = buildUnits();

  /// Per-digit implication graphs, built on first use and then reused.
  ///
  /// The hint path asks "which technique justifies this cell?" once per cell,
  /// and the targeted generator walks every cell of every generated board. The
  /// chain engine was rebuilding all nine graphs on each of those calls, which
  /// dominated the cost of the whole analyzer.
  late final List<_DigitGraph> _digitGraphs = [
    for (var d = 1; d <= GameConstants.boardSize; d++)
      _DigitGraph(d, this)..build(),
  ];

  static List<List<Set<int>>> computeCandidates(List<List<int>> board) {
    final size = GameConstants.boardSize;
    return List.generate(size, (r) {
      return List.generate(size, (c) {
        if (board[r][c] != 0) return <int>{};
        final set = <int>{};
        for (var v = 1; v <= size; v++) {
          if (SudokuLogic.isValid(board, r, c, v)) set.add(v);
        }
        return set;
      });
    });
  }

  /// 27 units: 9 rows, then 9 columns, then 9 boxes.
  static List<List<TechCell>> buildUnits() {
    final size = GameConstants.boardSize;
    final box = size ~/ 3;
    final units = <List<TechCell>>[];
    for (var r = 0; r < size; r++) {
      units.add([for (var c = 0; c < size; c++) (r: r, c: c)]);
    }
    for (var c = 0; c < size; c++) {
      units.add([for (var r = 0; r < size; r++) (r: r, c: c)]);
    }
    for (var b = 0; b < size; b++) {
      final br = (b ~/ box) * box;
      final bc = (b % box) * box;
      units.add([
        for (var r = br; r < br + box; r++)
          for (var c = bc; c < bc + box; c++) (r: r, c: c),
      ]);
    }
    return units;
  }

  bool has(TechCell cell, int digit) => cand[cell.r][cell.c].contains(digit);

  Set<int> candidatesAt(TechCell cell) => cand[cell.r][cell.c];

  /// Every empty cell in the grid.
  List<TechCell> get emptyCells {
    final size = GameConstants.boardSize;
    return [
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++)
          if (board[r][c] == 0) (r: r, c: c),
    ];
  }

  /// Cells holding [digit] as a candidate within the row of [row].
  List<TechCell> rowPositions(int row, int digit) => [
    for (var c = 0; c < GameConstants.boardSize; c++)
      if (has((r: row, c: c), digit)) (r: row, c: c),
  ];

  List<TechCell> colPositions(int col, int digit) => [
    for (var r = 0; r < GameConstants.boardSize; r++)
      if (has((r: r, c: col), digit)) (r: r, c: col),
  ];

  List<TechCell> boxPositions(int row, int col, int digit) {
    final box = GameConstants.boardSize ~/ 3;
    final br = (row ~/ box) * box;
    final bc = (col ~/ box) * box;
    return [
      for (var r = br; r < br + box; r++)
        for (var c = bc; c < bc + box; c++)
          if (has((r: r, c: c), digit)) (r: r, c: c),
    ];
  }

  /// Row, column or box containing [cell].
  List<TechCell> unitOf(TechCell cell) => units[cell.r];

  bool sameUnit(TechCell a, TechCell b) =>
      a.r == b.r || a.c == b.c || (a.r ~/ 3 == b.r ~/ 3 && a.c ~/ 3 == b.c ~/ 3);

  /// Cells sharing a unit with [cell], excluding [cell] itself.
  List<TechCell> peers(TechCell cell) => units[cell.r]
      .where((u) => u.r != cell.r || u.c != cell.c)
      .toList(growable: false);

  static bool linked(TechCell a, TechCell b) =>
      a.r == b.r ||
      a.c == b.c ||
      (a.r ~/ 3 == b.r ~/ 3 && a.c ~/ 3 == b.c ~/ 3);
}

/// Detector signature. Returns every occurrence it can prove, or an empty list.
typedef TechniqueDetector = List<TechniqueHit> Function(TechniqueContext ctx);

/// The ordered detector registry.
///
/// Order matters: `analyzeCell` reports the first technique that justifies a
/// value, and easier-to-explain techniques should win.
const List<TechniqueDetector> advancedDetectors = [
  _nakedTriples,
  _hiddenTriples,
  _basicFish,
  _finnedXWings,
  _sashimiXWings,
  _yWings,
  _xyzWings,
  _wWings,
  _emptyRectangles,
  _simpleColorings,
  _uniqueRectangles,
  _chainHits,
];

// ---------------------------------------------------------------------------
// Binary implication chain engine
// ---------------------------------------------------------------------------
//
// Chains are built on a per-digit implication graph. Nodes are literals:
// `pos(X)` means "this digit sits at X", `neg(X)` means "this digit does not
// sit at X". Only three edge kinds are used, and every one of them is
// individually sound:
//
//   N   pos(X) -> neg(Y)
//       For every cell Y linked to X (same row, column or box). If the digit
//       is at X then no peer of X can hold it.
//
//   E   neg(A) -> pos(B)
//       When some unit has exactly two candidate cells for the digit, A and B.
//       Exactly one of them must hold it, so ruling one out forces the other.
//       This is the "strong link" of an X-Chain.
//
//   X   neg(A) -> pos(B)
//       When A and B are linked and both carry exactly the same candidate set
//       {digit, other}. If the digit is not at A then `other` must be at A, so
//       `other` is not at B, so the digit is at B. This pivot is what turns an
//       X-Chain into an XY-Chain.
//
// A path starting from a node whose polarity is already established is an
// unconditional deduction. It yields a placement when it lands on `pos`, and
// it yields an elimination when it lands on a `neg` node whose positive
// counterpart is a known placement (a genuine contradiction).
//
// Nothing here infers a polarity from candidate counts alone — that is exactly
// what made the first colouring attempt unsound.
//
// The three chain detectors differ only in how they classify a discovered path:
//
//   X-Chain                    uses only N and E links
//   XY-Chain                   uses at least one X link
//   Alternating Inference Chain   is long (4+ positive cells)
//
// ---------------------------------------------------------------------------

/// A literal in one digit's implication graph.
typedef ChainNode = ({int r, int c, bool positive});

ChainNode _posOf(TechCell cell) =>
    (r: cell.r, c: cell.c, positive: true);
ChainNode _negOf(TechCell cell) =>
    (r: cell.r, c: cell.c, positive: false);

ChainNode _opposite(ChainNode n) => (
  r: n.r,
  c: n.c,
  positive: !n.positive,
);

/// One implication edge plus whether it is an XY pivot.
class _Edge {
  final ChainNode to;
  final bool xy;
  const _Edge(this.to, {this.xy = false});
}

/// A path through a digit's implication graph.
class _ChainPath {
  final List<ChainNode> path;
  final bool usedXy;
  const _ChainPath(this.path, this.usedXy);

  /// Cells that carry the digit's candidate on this chain.
  int get positiveCount => path.where((n) => n.positive).length;

  List<TechCell> get cells => [
    for (final n in path) (r: n.r, c: n.c),
  ];

  /// Alternating Inference Chains are the long ones; short paths are named
  /// after their most distinctive link.
  bool get isLong => positiveCount >= 4;
}

/// Implication graph for a single digit.
class _DigitGraph {
  _DigitGraph(this.digit, this.ctx);

  final int digit;
  final TechniqueContext ctx;

  final Map<ChainNode, List<_Edge>> _out = {};
  final Set<ChainNode> _true = {};
  final Set<ChainNode> _false = {};

  /// Cells that can still hold [digit].
  late final Set<TechCell> positions = {
    for (var r = 0; r < GameConstants.boardSize; r++)
      for (var c = 0; c < GameConstants.boardSize; c++)
        if (ctx.has((r: r, c: c), digit)) (r: r, c: c),
  };

  void _edge(ChainNode from, ChainNode to, {bool xy = false}) {
    (_out[from] ??= <_Edge>[]).add(_Edge(to, xy: xy));
  }

  bool isTrue(ChainNode n) => _true.contains(n);
  bool isFalse(ChainNode n) => _false.contains(n);
  List<_Edge> successors(ChainNode n) => _out[n] ?? const [];

  void build() {
    for (final x in positions) {
      for (final y in ctx.peers(x)) {
        _edge(_posOf(x), _negOf(y));
      }
    }

    for (final unit in ctx.units) {
      final spots = unit.where(positions.contains).toList();
      if (spots.length != 2) continue;
      final a = spots[0];
      final b = spots[1];
      _edge(_negOf(a), _posOf(b));
      _edge(_negOf(b), _posOf(a));
    }

    // XY pivots: linked cells sharing an identical two-candidate set that
    // includes this digit.
    final bivalue = <TechCell, Set<int>>{};
    for (final cell in positions) {
      final cands = ctx.candidatesAt(cell);
      if (cands.length == 2) bivalue[cell] = cands;
    }
    for (final entry in bivalue.entries) {
      for (final other in bivalue.entries) {
        if (identical(entry.key, other.key)) continue;
        if (!TechniqueContext.linked(entry.key, other.key)) continue;
        if (!setEquals(entry.value, other.value)) continue;
        // Same set, so it is the digit plus exactly one partner.
        _edge(_negOf(entry.key), _posOf(other.key), xy: true);
      }
    }

    // Known-placement seeds.
    for (var r = 0; r < GameConstants.boardSize; r++) {
      for (var c = 0; c < GameConstants.boardSize; c++) {
        final cell = (r: r, c: c);
        if (ctx.board[r][c] == digit) {
          _true.add(_posOf(cell));
        } else if (ctx.board[r][c] == 0) {
          // An empty cell without this candidate cannot hold it.
          _false.add(_negOf(cell));
        }
      }
    }
    // A unit left with a single candidate for the digit forces it there.
    for (final unit in ctx.units) {
      final spots = unit.where(positions.contains).toList();
      if (spots.length == 1) _true.add(_posOf(spots.first));
    }
  }

  /// Every implication path that ends on a contradiction.
  ///
  /// A contradiction is a node whose opposite is already established, which
  /// means the node itself is established false. Only such paths are reported:
  /// the previous version also collected "forced placement" paths, but those
  /// were built from implications whose antecedent was *false*, and a false
  /// antecedent implies nothing at all. Those paths asserted placements that
  /// had never been proved, and the oracle rejected them.
  List<_ChainPath> chains({int maxResults = 6, int maxCells = 5}) {
    final found = <_ChainPath>[];
    final seen = <String>{};

    // Bounds the search. Chains are the most expensive detector by a wide
    // margin, and a hint only needs one good explanation — not an exhaustive
    // enumeration of every chain on the board.
    var budget = _expansionBudget;

    void walk(ChainNode node, List<ChainNode> path, bool usedXy) {
      if (found.length >= maxResults) return;
      if (budget <= 0) return;
      budget--;

      // Contradiction: the opposite of this node is established, so the node is
      // established false.
      if (isTrue(_opposite(node))) {
        if (seen.add(_signature(path))) found.add(_ChainPath(path, usedXy));
        return;
      }

      for (final edge in successors(node)) {
        if (budget <= 0) return;
        final next = edge.to;
        // A node already proven false cannot contribute a new contradiction,
        // and revisiting a node would only loop.
        if (path.contains(next)) continue;
        if (isTrue(_opposite(next)) && path.length < 3) continue;
        final nextPath = [...path, next];
        if (nextPath.length >= maxCells) continue;
        walk(next, nextPath, usedXy || edge.xy);
      }
    }

    // Only nodes with somewhere to go are worth starting from. Anchoring on
    // established poles is what makes a chain a proof rather than a guess.
    final starts = <ChainNode>{..._true, ..._false};
    for (final start in starts) {
      if (found.length >= maxResults) break;
      if (budget <= 0) break;
      if (successors(start).isEmpty) continue;
      walk(start, [start], false);
    }
    return found;
  }

  /// Upper bound on node expansions per digit graph.
  static const int _expansionBudget = 400;

  static String _signature(List<ChainNode> path) => path
      .map((n) => '${n.r},${n.c},${n.positive ? 1 : 0}')
      .join('>');
}

/// Turns a chain into the eliminations it proves.
///
/// An edge `A ⟹ B` carries its contrapositive `¬B ⟹ ¬A`. So once a node is
/// established **false**, walking backwards one step establishes the
/// *opposite* of its predecessor:
///
///   * if the predecessor is positive (cell X holds the digit) then `¬X` holds,
///     so the digit can be eliminated from X;
///   * if the predecessor is negative then `¬(¬X)` holds, so the digit is
///     forced into X — and X is in turn established false, so the walk
///     continues.
///
/// Only positive nodes the walk actually reaches are eliminated. The previous
/// version eliminated the second-to-last positive *anywhere* on the path, which
/// is unjustified whenever intermediate positives are separated by negatives —
/// the oracle caught it removing the true value of a cell on easy, medium and
/// hard boards alike.
///
/// Chains that end without a contradiction are discarded: nothing is proved.
List<TechniqueElimination>? _chainEliminations(
  _DigitGraph graph,
  _ChainPath chain,
) {
  final path = chain.path;
  final last = path.last;

  // Without a contradiction there is no proof to extract.
  if (!graph.isTrue(_opposite(last))) return null;

  final eliminations = <TechniqueElimination>[];
  final seen = <String>{};

  // Nodes proven false by the backward walk, seeded with the contradiction.
  final provenFalse = <ChainNode>{last};

  for (var i = path.length - 2; i >= 0; i--) {
    final node = path[i];
    if (!provenFalse.contains(path[i + 1])) continue;

    if (node.positive) {
      final cell = (r: node.r, c: node.c);
      if (graph.ctx.has(cell, graph.digit) &&
          seen.add('${cell.r},${cell.c},${graph.digit}')) {
        eliminations.add(TechniqueElimination(cell.r, cell.c, graph.digit));
      }
      // The cell is now known not to hold the digit, so the walk continues.
      provenFalse.add(node);
    } else {
      // A negative predecessor here becomes a forced placement, which is
      // itself established — keep walking so a later positive still proves out.
      provenFalse.add(node);
    }
  }

  if (eliminations.isEmpty) return null;
  return eliminations;
}

String _chainTitle(SolvingStrategy strategy) => strategy.label;

/// Runs the chain engine and labels each chain by its shape.
List<TechniqueHit> _chainHits(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  for (final graph in ctx._digitGraphs) {
    final digit = graph.digit;
    for (final chain in graph.chains()) {
      final eliminations = _chainEliminations(graph, chain);
      if (eliminations == null) continue;

      final strategy = chain.isLong
          ? SolvingStrategy.alternatingInferenceChain
          : (chain.usedXy ? SolvingStrategy.xyChain : SolvingStrategy.xChain);

      // De-duplicate: several paths can prove the same elimination.
      final signature = eliminations
          .map((e) => '${e.row},${e.col},${e.digit}')
          .toSet()
          .join('|');
      final duplicate = hits.any(
        (h) =>
            h.strategy == strategy &&
            h.eliminations
                .map((e) => '${e.row},${e.col},${e.digit}')
                .toSet()
                .join('|') ==
                signature,
      );
      if (duplicate) continue;

      hits.add(
        TechniqueHit(
          strategy: strategy,
          title: _chainTitle(strategy),
          body:
              'Digit $digit chains through ${_describeCells(chain.cells)}.\n\n'
              '${chainDescription(strategy)}\n\n'
              'This eliminates $digit from '
              '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))}.',
          eliminations: eliminations,
          highlights: _keys(chain.cells),
        ),
      );
      if (hits.length >= 12) return hits;
    }
  }
  return hits;
}

String chainDescription(SolvingStrategy strategy) => switch (strategy) {
  SolvingStrategy.xChain =>
    'Every link is forced: a placement rules the digit out of its peers, and '
        'a unit left with two candidate cells must put the digit in one of '
        'them.',
  SolvingStrategy.xyChain =>
    'The chain pivots on a pair of linked cells that both allow exactly the '
        'same two digits. If this digit is absent from one it must occupy the '
        'other, and the rest of the chain follows.',
  SolvingStrategy.alternatingInferenceChain =>
    'This chain alternates strong and weak links several times over, so each '
        'step is forced in turn.',
  _ => 'This chain is forced link by link.',
};

/// Detects Simple Coloring: a cell that sees *every* remaining candidate for a
/// digit inside one unit cannot hold that digit itself.
///
/// If the digit went into the observing cell it would clear the whole unit of
/// candidates, leaving the unit with nowhere to put the digit — a contradiction.
List<TechniqueHit> _simpleColorings(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  final size = GameConstants.boardSize;

  for (var d = 1; d <= size; d++) {
    final positions = <TechCell>{
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++)
          if (ctx.has((r: r, c: c), d)) (r: r, c: c),
    };
    if (positions.isEmpty) continue;

    for (final unit in ctx.units) {
      final spots = unit.where(positions.contains).toList();
      if (spots.length < 2) continue;

      for (final observer in positions) {
        if (spots.contains(observer)) continue;
        // Every candidate in this unit must see the observer, otherwise the
        // digit still has somewhere to go.
        if (!spots.every((s) => TechniqueContext.linked(observer, s))) {
          continue;
        }
        if (hits.length >= 8) return hits;
        hits.add(
          TechniqueHit(
            strategy: SolvingStrategy.simpleColoring,
            title: SolvingStrategy.simpleColoring.label,
            body:
                'Digit $d can only go in '
                '${_describeCells(spots)} within this unit, but '
                '${_describeCells([observer])} sees every one of them.\n\n'
                'Placing $d at that cell would rule $d out of all of '
                '${_describeCells(spots)}, leaving the unit with nowhere to put '
                '$d. So $d cannot be there.\n\n'
                'This Simple Coloring eliminates $d from '
                '${_describeCells([observer])}.',
            eliminations: [TechniqueElimination(observer.r, observer.c, d)],
            highlights: _keys([observer, ...spots]),
          ),
        );
      }
    }
  }
  return hits;
}

/// Detects Unique Rectangles.
///
/// Four cells at the corners of a rectangle in a unit, where two of them share
/// a two-candidate set {d, e}. If the other two corners sit in *different*
/// boxes, at most one of them can also be {d, e}, so the pair is eliminated
/// from whichever corner shares a box with neither.
List<TechniqueHit> _uniqueRectangles(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];

  bool isBivalue(TechCell cell) {
    final cands = ctx.candidatesAt(cell);
    return cands.length == 2 && ctx.board[cell.r][cell.c] == 0;
  }

  for (final unit in ctx.units) {
    final empties = unit.where((c) => ctx.board[c.r][c.c] == 0).toList();
    if (empties.length < 2) continue;
    for (final a in empties) {
      for (final b in empties) {
        if (identical(a, b)) continue;
        if (!isBivalue(a) || !isBivalue(b)) continue;
        final pair = ctx.candidatesAt(a);
        if (!setEquals(pair, ctx.candidatesAt(b))) continue;

        final eliminations = <TechniqueElimination>[];
        final remaining = empties
            .where((c) => !identical(c, a) && !identical(c, b))
            .toList();
        if (remaining.length < 2) continue;

        // The other two corners. If they live in different boxes they cannot
        // both hold {d, e}, so the pair is struck from each.
        final c = remaining[0];
        final e = remaining[1];
        final sameBox = (c.r ~/ 3 == e.r ~/ 3) && (c.c ~/ 3 == e.c ~/ 3);
        if (sameBox) {
          // Stronger form: when the other two corners are in one box, neither
          // of the original pair can stay {d, e} unless the third also can.
          final third = remaining.where((x) => !identical(x, c) && !identical(x, e)).toList();
          if (third.isEmpty) continue;
          if (!third.any((x) => setEquals(ctx.candidatesAt(x), pair))) continue;
          for (final cell in [a, b]) {
            for (final value in pair) {
              if (seenAdd(eliminations, cell, value)) {
                eliminations.add(TechniqueElimination(cell.r, cell.c, value));
              }
            }
          }
        } else {
          for (final cell in [c, e]) {
            for (final value in pair) {
              if (seenAdd(eliminations, cell, value)) {
                eliminations.add(TechniqueElimination(cell.r, cell.c, value));
              }
            }
          }
        }

        if (eliminations.isEmpty) continue;
        if (hits.length >= 8) return hits;

        hits.add(
          TechniqueHit(
            strategy: SolvingStrategy.uniqueRectangles,
            title: SolvingStrategy.uniqueRectangles.label,
            body:
                'Cells ${_describeCells([a, b])} both allow exactly '
                '${_digits(pair)}.\n\n'
                '${sameBox
                    ? 'The remaining corners sit in the same box, and a third '
                          'cell there cannot also take ${_digits(pair)} — so at '
                          'least one of these two is wrong.'
                    : 'The remaining corners sit in different boxes, so they '
                          'cannot both be ${_digits(pair)}. At most one is, so '
                          'both lose the pair.'}\n\n'
                'This Unique Rectangle eliminates '
                '${_digits(eliminations.map((x) => x.digit).toSet())} from '
                '${_describeCells(eliminations.map((x) => (r: x.row, c: x.col)).toSet())}.',
            eliminations: eliminations,
            highlights: _keys([a, b, c, e]),
          ),
        );
      }
    }
  }
  return hits;
}

bool seenAdd(List<TechniqueElimination> into, TechCell cell, int digit) {
  final key = '${cell.r},${cell.c},$digit';
  return into.every((e) => '${e.row},${e.col},${e.digit}' != key);
}

bool setEquals(Set<int> a, Set<int> b) =>
    a.length == b.length && a.every(b.contains);

/// Runs every [advancedDetectors] entry and returns the hits that rule out at
/// least one candidate at ([row], [col]).
List<TechniqueHit> findJustifyingHits(
  TechniqueContext ctx,
  int row,
  int col,
) {
  final found = <TechniqueHit>[];
  for (final detector in advancedDetectors) {
    for (final hit in detector(ctx)) {
      if (hit.eliminates(row, col)) {
        found.add(hit);
      }
    }
    if (found.isNotEmpty) break;
  }
  return found;
}

/// Every technique hit on the board, used by the targeted generator to check
/// whether a puzzle genuinely requires a strategy.
List<TechniqueHit> findAllHits(TechniqueContext ctx) {
  final found = <TechniqueHit>[];
  for (final detector in advancedDetectors) {
    found.addAll(detector(ctx));
  }
  return found;
}

/// Every subset of [items] with exactly [n] elements, in index order.
Iterable<List<T>> _combinations<T>(List<T> items, int n) sync* {
  if (n == 0) {
    yield const [];
    return;
  }
  if (items.length < n) return;
  for (var i = 0; i <= items.length - n; i++) {
    for (final rest in _combinations(items.sublist(i + 1), n - 1)) {
      yield [items[i], ...rest];
    }
  }
}

/// Strictly increasing combinations of digits, e.g. `[1, 4, 7]`.
///
/// [start] carries the previous digit forward so the recursion cannot emit a
/// repeated digit. Without it the generator produced combinations such as
/// `[1, 1]`, and a "hidden triple" built on those degenerates into a bogus
/// single-digit rule.
Iterable<List<int>> _digitCombinations(int n, {int start = 1}) sync* {
  if (n == 0) {
    yield const [];
    return;
  }
  for (var i = start; i <= 10 - n; i++) {
    for (final rest in _digitCombinations(n - 1, start: i + 1)) {
      yield [i, ...rest];
    }
  }
}

List<String> _keys(Iterable<TechCell> cells) =>
    cells.map((c) => '${c.r},${c.c}').toList(growable: false);

/// Formats a digit set the way a solver writes it, e.g. `{1, 4, 7}`.
String _digits(Iterable<int> digits) {
  final sorted = digits.toList()..sort();
  return '{${sorted.join(', ')}}';
}

String _describeCells(Iterable<TechCell> cells) {
  final sorted = cells.toList()
    ..sort((a, b) => a.r != b.r ? a.r - b.r : a.c - b.c);
  return sorted.map((c) => 'R${c.r + 1}C${c.c + 1}').join(', ');
}

// ---------------------------------------------------------------------------
// Tier 1: naked / hidden combinations
// ---------------------------------------------------------------------------

/// Cells whose candidate union is exactly [n] digits cannot hold anything
/// else, so those [n] digits can be struck from the rest of the unit.
List<TechniqueHit> _nakedCombination(
  TechniqueContext ctx,
  int n,
  SolvingStrategy strategy,
) {
  final hits = <TechniqueHit>[];
  for (final unit in ctx.units) {
    final empties = unit.where((c) => ctx.board[c.r][c.c] == 0).toList();
    for (final combo in _combinations(empties, n)) {
      final union = <int>{};
      for (final cell in combo) {
        union.addAll(ctx.candidatesAt(cell));
      }
      if (union.length != n) continue;

      final eliminations = <TechniqueElimination>[];
      for (final cell in unit) {
        if (combo.contains(cell)) continue;
        for (final d in ctx.candidatesAt(cell)) {
          if (union.contains(d)) {
            eliminations.add(TechniqueElimination(cell.r, cell.c, d));
          }
        }
      }
      if (eliminations.isEmpty) continue;

      final digits = union.toList()..sort();
      hits.add(
        TechniqueHit(
          strategy: strategy,
          title: strategy.label,
          body:
              'The cells ${_describeCells(combo)} hold between them only the '
              'candidates {${digits.join(', ')}}. Those digits are therefore '
              'spoken for and can be eliminated from every other cell in this '
              'unit.\n\nThis ${strategy.label} eliminates '
              '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))} '
              'of the listed candidates.',
          eliminations: eliminations,
          highlights: _keys([...combo]),
        ),
      );
    }
  }
  return hits;
}

/// [n] digits that only fit inside [n] cells of a unit force those cells to
/// hold exactly those digits, eliminating everything else from them.
List<TechniqueHit> _hiddenCombination(
  TechniqueContext ctx,
  int n,
  SolvingStrategy strategy,
) {
  final hits = <TechniqueHit>[];
  for (final unit in ctx.units) {
    for (final combo in _digitCombinations(n)) {
      final wanted = combo.toSet();

      // Every digit must still be unplaced in this unit, and each must still
      // have somewhere to go. Without this a digit that is *already* in the
      // row contributes no positions at all, so a set of fewer than [n] real
      // candidates can masquerade as a hidden [n]-tuple.
      final placed = unit.any((c) => wanted.contains(ctx.board[c.r][c.c]));
      if (placed) continue;

      final positions = unit
          .where(
            (cell) =>
                ctx.board[cell.r][cell.c] == 0 &&
                ctx.candidatesAt(cell).intersection(wanted).isNotEmpty,
          )
          .toList();
      if (positions.length != n) continue;
      // Each digit needs at least one position, or the board has no solution.
      final covered = <int>{};
      for (final cell in positions) {
        covered.addAll(ctx.candidatesAt(cell).intersection(wanted));
      }
      if (covered.length != n) continue;

      final eliminations = <TechniqueElimination>[];
      for (final cell in positions) {
        for (final d in ctx.candidatesAt(cell)) {
          if (!wanted.contains(d)) {
            eliminations.add(TechniqueElimination(cell.r, cell.c, d));
          }
        }
      }
      if (eliminations.isEmpty) continue;

      final digits = combo..sort();
      hits.add(
        TechniqueHit(
          strategy: strategy,
          title: strategy.label,
          body:
              'In this unit the digits {${digits.join(', ')}} can only go in '
              '${_describeCells(positions)}. That is exactly as many cells as '
              'there are digits, so every other candidate in them is '
              'excluded.\n\nThis ${strategy.label} narrows '
              '${_describeCells(positions)} to {${digits.join(', ')}}.',
          eliminations: eliminations,
          highlights: _keys(positions),
        ),
      );
    }
  }
  return hits;
}

List<TechniqueHit> _nakedTriples(TechniqueContext ctx) =>
    _nakedCombination(ctx, 3, SolvingStrategy.nakedTriple);

List<TechniqueHit> _hiddenTriples(TechniqueContext ctx) =>
    _hiddenCombination(ctx, 3, SolvingStrategy.hiddenTriple);

// ---------------------------------------------------------------------------
// Tier 2: fish
// ---------------------------------------------------------------------------

List<TechniqueHit> _basicFish(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  for (var digit = 1; digit <= GameConstants.boardSize; digit++) {
    const bySize = <int, SolvingStrategy>{
      2: SolvingStrategy.xWing,
      3: SolvingStrategy.swordfish,
      4: SolvingStrategy.jellyfish,
    };
    for (final entry in bySize.entries) {
      hits.addAll(_fishOfSize(ctx, digit, entry.key, entry.value));
    }
  }
  return hits;
}

/// Classic n x n fish. [size] 2/3/4 gives X-Wing/Swordfish/Jellyfish.
List<TechniqueHit> _fishOfSize(
  TechniqueContext ctx,
  int digit,
  int size,
  SolvingStrategy strategy,
) {
  final hits = <TechniqueHit>[];
  final size9 = GameConstants.boardSize;

  // Row-based: base rows restricted to a set of base columns.
  for (final baseRows in _combinations(
    List.generate(size9, (r) => (r: r, c: 0)),
    size,
  )) {
    final rowIndices = baseRows.map((e) => e.r).toSet();
    final cols = <int>{};
    var covered = true;
    for (final r in rowIndices) {
      final positions = ctx.rowPositions(r, digit);
      for (final p in positions) {
        if (!rowIndices.contains(p.r)) covered = false;
        cols.add(p.c);
      }
    }
    if (!covered || cols.length != size) continue;
    final baseCols = cols.toList()..sort();

    // Each base column must hold the digit only inside the base rows.
    var valid = true;
    for (final c in baseCols) {
      for (final p in ctx.colPositions(c, digit)) {
        if (!rowIndices.contains(p.r)) valid = false;
      }
    }
    if (!valid) continue;

    final eliminations = <TechniqueElimination>[];
    for (final c in baseCols) {
      for (final p in ctx.colPositions(c, digit)) {
        if (!rowIndices.contains(p.r)) {
          eliminations.add(TechniqueElimination(p.r, p.c, digit));
        }
      }
    }
    for (final r in rowIndices) {
      for (final p in ctx.rowPositions(r, digit)) {
        if (!cols.contains(p.c)) {
          eliminations.add(TechniqueElimination(p.r, p.c, digit));
        }
      }
    }
    if (eliminations.isEmpty) continue;

    final rowLabel = rowIndices.toList()..sort();
    hits.add(
      TechniqueHit(
        strategy: strategy,
        title: strategy.label,
        body:
            'Digit $digit only fits in ${rowLabel.map((r) => 'row ${r + 1}').join(' and ')} '
            'at columns ${baseCols.map((c) => c + 1).join(', ')}. '
            '$size columns each need a $digit but only $size rows are '
            'available, so one row must take two of them — forcing every other '
            'candidate $digit out of those columns and rows.\n\n'
            'This ${strategy.label} eliminates $digit from '
            '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))}.',
        eliminations: eliminations,
        highlights: _keys([
          for (final r in rowIndices)
            for (final c in baseCols) (r: r, c: c),
        ]),
      ),
    );
  }

  // Column-based transpose.
  for (final baseColCells in _combinations(
    List.generate(size9, (c) => (r: 0, c: c)),
    size,
  )) {
    final colIndices = baseColCells.map((e) => e.c).toSet();
    final rows = <int>{};
    var covered = true;
    for (final c in colIndices) {
      for (final p in ctx.colPositions(c, digit)) {
        if (!colIndices.contains(p.c)) covered = false;
        rows.add(p.r);
      }
    }
    if (!covered || rows.length != size) continue;
    final baseRows = rows.toList()..sort();

    var valid = true;
    for (final r in baseRows) {
      for (final p in ctx.rowPositions(r, digit)) {
        if (!colIndices.contains(p.c)) valid = false;
      }
    }
    if (!valid) continue;

    final eliminations = <TechniqueElimination>[];
    for (final r in baseRows) {
      for (final p in ctx.rowPositions(r, digit)) {
        if (!colIndices.contains(p.c)) {
          eliminations.add(TechniqueElimination(p.r, p.c, digit));
        }
      }
    }
    for (final c in colIndices) {
      for (final p in ctx.colPositions(c, digit)) {
        if (!rows.contains(p.r)) {
          eliminations.add(TechniqueElimination(p.r, p.c, digit));
        }
      }
    }
    if (eliminations.isEmpty) continue;

    final colLabel = colIndices.toList()..sort();
    hits.add(
      TechniqueHit(
        strategy: strategy,
        title: strategy.label,
        body:
            'Digit $digit only fits in columns ${colLabel.map((c) => c + 1).join(' and ')} '
            'at rows ${baseRows.map((r) => r + 1).join(', ')}. '
            '$size rows each need a $digit but only $size columns are '
            'available, forcing every other candidate $digit out of them.\n\n'
            'This ${strategy.label} eliminates $digit from '
            '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))}.',
        eliminations: eliminations,
        highlights: _keys([
          for (final c in colIndices)
            for (final r in baseRows) (r: r, c: c),
        ]),
      ),
    );
  }

  return hits;
}

/// Finned X-Wing: 2 base rows x 3 base columns plus exactly one fin cell in a
/// third row. Columns 1 and 2 are consumed inside the base rows, which forces
/// the third base column's digit into the fin.
List<TechniqueHit> _finnedXWings(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  final size = GameConstants.boardSize;

  for (var digit = 1; digit <= size; digit++) {
    // Horizontal: base rows r1, r2; base cols c1..c3; fin row r3.
    for (final r1 in List.generate(size, (i) => i)) {
      for (final r2 in List.generate(size, (i) => i)) {
        if (r1 == r2) continue;
        final rows = [r1, r2];
        // Candidate base column triples.
        final colPool = <int>{};
        for (final r in rows) {
          for (final p in ctx.rowPositions(r, digit)) {
            colPool.add(p.c);
          }
        }
        for (final cols in _combinations(colPool.toList()..sort(), 3)) {
          // All digit positions in the base rows live in the base columns.
          var ok = true;
          for (final r in rows) {
            for (final p in ctx.rowPositions(r, digit)) {
              if (!cols.contains(p.c)) ok = false;
            }
          }
          if (!ok) continue;
          // Positions inside the base columns live in the base rows, except a
          // single fin.
          final extra = <TechCell>[];
          for (final c in cols) {
            for (final p in ctx.colPositions(c, digit)) {
              if (!rows.contains(p.r)) extra.add(p);
            }
          }
          if (extra.length != 1) continue;
          final fin = extra.single;
          if (cols.contains(fin.c) == false) continue;

          // The fin's column needs at least one body position to be a real
          // finned X-Wing rather than a stray candidate.
          final bodyInFinCol = cols.contains(fin.c) &&
              rows.any(
                (r) => ctx.has((r: r, c: fin.c), digit),
              );
          if (!bodyInFinCol) continue;

          final finRow = fin.r;
          final eliminations = <TechniqueElimination>[];
          final seen = <String>{};
          void addElim(int r, int c) {
            if (ctx.has((r: r, c: c), digit) && seen.add('$r,$c')) {
              eliminations.add(TechniqueElimination(r, c, digit));
            }
          }

          // Base rows are spent on the two non-fin base columns.
          for (final r in rows) {
            addElim(r, fin.c);
          }
          // Fin row is spent on the fin column.
          for (final c in cols) {
            if (c != fin.c) addElim(finRow, c);
          }
          // Base columns are otherwise closed.
          for (final c in cols) {
            for (final p in ctx.colPositions(c, digit)) {
              if (!rows.contains(p.r) && p.r != finRow) {
                addElim(p.r, p.c);
              }
            }
          }
          if (eliminations.isEmpty) continue;

          hits.add(
            TechniqueHit(
              strategy: SolvingStrategy.finnedXWing,
              title: SolvingStrategy.finnedXWing.label,
              body:
                  'Digit $digit is confined to rows ${r1 + 1} and ${r2 + 1} '
                  'within columns ${cols.map((c) => c + 1).join(', ')}, with one '
                  'extra position at ${_describeCells([fin])} as the fin.\n\n'
                  'Columns ${cols.where((c) => c != fin.c).map((c) => c + 1).join(' and ')} '
                  'can only take $digit inside the base rows, so both base rows '
                  'are already used up and cannot take it again; the fin row '
                  'already holds its $digit at column ${fin.c + 1}.\n\n'
                  'This Finned X-Wing eliminates $digit from '
                  '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))}.',
              eliminations: eliminations,
              highlights: _keys([
                for (final r in rows)
                  for (final c in cols) (r: r, c: c),
                fin,
              ]),
            ),
          );
        }
      }
    }
  }
  return hits;
}

/// Sashimi X-Wing: 2 base rows x 3 base columns where the rectangle holds five
/// positions and the sixth cell is the "sashimi" fin.
List<TechniqueHit> _sashimiXWings(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  final size = GameConstants.boardSize;

  for (var digit = 1; digit <= size; digit++) {
    for (final r1 in List.generate(size, (i) => i)) {
      for (final r2 in List.generate(size, (i) => i)) {
        if (r1 == r2) continue;
        final rows = [r1, r2];
        final colPool = <int>{};
        for (final r in rows) {
          for (final p in ctx.rowPositions(r, digit)) {
            colPool.add(p.c);
          }
        }
        if (colPool.length < 3) continue;
        for (final cols in _combinations(colPool.toList()..sort(), 3)) {
          // Every base-row position must sit in a base column.
          var ok = true;
          for (final r in rows) {
            for (final p in ctx.rowPositions(r, digit)) {
              if (!cols.contains(p.c)) ok = false;
            }
          }
          if (!ok) continue;

          // The rectangle must hold exactly five positions.
          final bodyPositions = <TechCell>[];
          TechCell? gap;
          for (final r in rows) {
            for (final c in cols) {
              if (ctx.has((r: r, c: c), digit)) {
                bodyPositions.add((r: r, c: c));
              } else {
                gap ??= (r: r, c: c);
              }
            }
          }
          if (gap == null || bodyPositions.length != 5) continue;

          // Outside the base rows, the base columns hold a single fin aligned
          // with the gap.
          final extra = <TechCell>[];
          for (final c in cols) {
            for (final p in ctx.colPositions(c, digit)) {
              if (!rows.contains(p.r)) extra.add(p);
            }
          }
          if (extra.length != 1) continue;
          final fin = extra.single;
          if (fin.c != gap.c) continue;
          if (ctx.rowPositions(fin.r, digit).length != 1) continue;

          final eliminations = <TechniqueElimination>[];
          final seen = <String>{};
          void addElim(int r, int c) {
            if (ctx.has((r: r, c: c), digit) && seen.add('$r,$c')) {
              eliminations.add(TechniqueElimination(r, c, digit));
            }
          }

          // The gap column can only resolve onto the fin, so its other base
          // cell is out.
          for (final r in rows) {
            addElim(r, gap.c);
          }
          // The fin row is spent.
          for (final c in cols) {
            if (c != gap.c) addElim(fin.r, c);
          }
          // Base columns are otherwise closed.
          for (final c in cols) {
            for (final p in ctx.colPositions(c, digit)) {
              if (!rows.contains(p.r) && p.r != fin.r) addElim(p.r, p.c);
            }
          }
          if (eliminations.isEmpty) continue;

          hits.add(
            TechniqueHit(
              strategy: SolvingStrategy.sashimiXWing,
              title: SolvingStrategy.sashimiXWing.label,
              body:
                  'Digit $digit fills five of the six cells of the rectangle '
                  'rows ${r1 + 1}/${r2 + 1} x columns '
                  '${cols.map((c) => c + 1).join(', ')}, and its only position '
                  'outside those rows is the fin at ${_describeCells([fin])}.\n\n'
                  'The other two columns still need a $digit and only rows '
                  '${r1 + 1} and ${r2 + 1} are available, so those two rows are '
                  'fully committed; the gap column\'s $digit must therefore be '
                  'the fin.\n\nThis Sashimi X-Wing eliminates $digit from '
                  '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))}.',
              eliminations: eliminations,
              highlights: _keys([...bodyPositions, fin]),
            ),
          );
        }
      }
    }
  }
  return hits;
}

// ---------------------------------------------------------------------------
// Tier 3: wings
// ---------------------------------------------------------------------------

/// Y-Wing: pivot {a,b}, one bi-value {a,c} and one {b,c}. Then c goes in the
/// pivot, a is out of cells seeing the {a,c} cell and b out of cells seeing
/// the {b,c} cell.
List<TechniqueHit> _yWings(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  for (final pivot in ctx.emptyCells) {
    final pivots = ctx.candidatesAt(pivot);
    if (pivots.length != 2) continue;
    final digits = pivots.toList()..sort();
    final a = digits[0];
    final b = digits[1];

    for (final c1 in ctx.peers(pivot)) {
      final set1 = ctx.candidatesAt(c1);
      if (set1.length != 2 || !set1.contains(a)) continue;
      for (final c2 in ctx.peers(pivot)) {
        if (c2.r == c1.r && c2.c == c1.c) continue;
        final set2 = ctx.candidatesAt(c2);
        if (set2.length != 2 || !set2.contains(b)) continue;
        final shared = set1.intersection(set2);
        if (shared.length != 1) continue;
        final c = shared.first;
        if (c == a || c == b) continue;

        final eliminations = <TechniqueElimination>[];
        final seen = <String>{};
        void addElim(TechCell cell, int digit) {
          if (ctx.has(cell, digit) && seen.add('${cell.r},${cell.c}')) {
            eliminations.add(
              TechniqueElimination(cell.r, cell.c, digit),
            );
          }
        }

        for (final cell in ctx.peers(c1)) {
          if (cell.r == pivot.r && cell.c == pivot.c) continue;
          addElim(cell, a);
        }
        for (final cell in ctx.peers(c2)) {
          if (cell.r == pivot.r && cell.c == pivot.c) continue;
          addElim(cell, b);
        }
        if (eliminations.isEmpty) continue;

        hits.add(
          TechniqueHit(
            strategy: SolvingStrategy.yWing,
            title: SolvingStrategy.yWing.label,
            body:
                '${_describeCells([pivot])} is the pivot, holding {$a, $b}. '
                '${_describeCells([c1])} is limited to {$a, $c} and '
                '${_describeCells([c2])} to {$b, $c}.\n\n'
                'If ${_describeCells([pivot])} were $a it would rule $a out of '
                '${_describeCells([c1])} and force $c into '
                '${_describeCells([pivot])}; symmetrically for $b. Either way $c '
                'lands in the pivot, so $a cannot go in cells seeing '
                '${_describeCells([c1])} and $b cannot go in cells seeing '
                '${_describeCells([c2])}.\n\nThis Y-Wing eliminates '
                '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))} '
                'of $a/$b.',
            eliminations: eliminations,
            highlights: _keys([pivot, c1, c2]),
          ),
        );
      }
    }
  }
  return hits;
}

/// XYZ-Wing: pivot {x,y,z} plus two bi-value cells sharing x. The shared digit
/// x is eliminated from any cell seeing both bi-value cells.
List<TechniqueHit> _xyzWings(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  for (final pivot in ctx.emptyCells) {
    final pivots = ctx.candidatesAt(pivot);
    if (pivots.length != 3) continue;
    for (final shared in pivots) {
      final others = pivots.where((d) => d != shared).toList();
      for (final b1 in ctx.peers(pivot)) {
        final s1 = ctx.candidatesAt(b1);
        if (s1.length != 2 || !s1.contains(shared)) continue;
        if (!s1.contains(others[0])) continue;
        for (final b2 in ctx.peers(pivot)) {
          if (b2.r == b1.r && b2.c == b1.c) continue;
          final s2 = ctx.candidatesAt(b2);
          if (s2.length != 2 || !s2.contains(shared)) continue;
          if (!s2.contains(others[1])) continue;
          // Bi-value cells must not see each other, otherwise the pattern is
          // already resolved differently.
          if (TechniqueContext.linked(b1, b2)) continue;

          final eliminations = <TechniqueElimination>[];
          final seen = <String>{};
          for (final cell in ctx.peers(b1)) {
            if (!ctx.has(cell, shared)) continue;
            if (TechniqueContext.linked(cell, b2)) {
              if (seen.add('${cell.r},${cell.c}')) {
                eliminations.add(
                  TechniqueElimination(cell.r, cell.c, shared),
                );
              }
            }
          }
          if (eliminations.isEmpty) continue;

          hits.add(
            TechniqueHit(
              strategy: SolvingStrategy.xyzWing,
              title: SolvingStrategy.xyzWing.label,
              body:
                  '${_describeCells([pivot])} holds ${_digits(pivots)}. '
                  '${_describeCells([b1])} is limited to ${_digits(s1)} and '
                  '${_describeCells([b2])} to ${_digits(s2)}.\n\n'
                  'Whichever of the pivot\'s three digits is used, $shared ends up '
                  'in exactly one of the two bi-value cells — so it cannot sit '
                  'in any cell that sees both of them.\n\n'
                  'This XYZ-Wing eliminates $shared from '
                  '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))}.',
              eliminations: eliminations,
              highlights: _keys([pivot, b1, b2]),
            ),
          );
        }
      }
    }
  }
  return hits;
}

/// W-Wing: two cells linked by a line holding exactly {w,x}. Both digits are
/// eliminated from the rest of that line.
List<TechniqueHit> _wWings(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  final size = GameConstants.boardSize;

  for (final a in ctx.emptyCells) {
    final setA = ctx.candidatesAt(a);
    if (setA.length != 2) continue;
    for (final b in ctx.peers(a)) {
      final setB = ctx.candidatesAt(b);
      if (setB.length != 2 || setA.difference(setB).isNotEmpty) continue;
      // Must be linked by exactly one unit, not two.
      final sharesRow = a.r == b.r;
      final sharesCol = a.c == b.c;
      final sharesBox = a.r ~/ 3 == b.r ~/ 3 && a.c ~/ 3 == b.c ~/ 3;
      final unitCount =
          (sharesRow ? 1 : 0) + (sharesCol ? 1 : 0) + (sharesBox ? 1 : 0);
      if (unitCount != 1) continue;

      final eliminations = <TechniqueElimination>[];
      final seen = <String>{};
      final digits = setA.toList()..sort();
      for (final cell in ctx.units[a.r]) {
        if (cell.r == a.r && cell.c == a.c) continue;
        if (cell.r == b.r && cell.c == b.c) continue;
        for (final d in digits) {
          if (ctx.has(cell, d) && seen.add('${cell.r},${cell.c},$d')) {
            eliminations.add(TechniqueElimination(cell.r, cell.c, d));
          }
        }
      }
      if (seen.length < 2) continue;
      // Both digits must actually be eliminated somewhere for the wing to
      // mean anything.
      final byDigit = <int, int>{};
      for (final e in eliminations) {
        byDigit[e.digit] = (byDigit[e.digit] ?? 0) + 1;
      }
      if (byDigit.length < 2) continue;

      final unitName = sharesRow
          ? 'row ${a.r + 1}'
          : sharesCol
          ? 'column ${a.c + 1}'
          : 'the ${a.r ~/ 3 + 1}th block';
      hits.add(
        TechniqueHit(
          strategy: SolvingStrategy.wWing,
          title: SolvingStrategy.wWing.label,
          body:
              '${_describeCells([a])} and ${_describeCells([b])} are linked by '
              '$unitName and both hold only {${digits.join(', ')}}.\n\n'
              'One of the two cells takes ${digits[0]} and the other takes '
              '${digits[1]}, which exhausts both digits for $unitName.\n\n'
              'This W-Wing eliminates ${digits.join(' and ')} from '
              '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))}.',
          eliminations: eliminations,
          highlights: _keys([a, b]),
        ),
      );
      // Break out: one W-Wing per starting cell is enough for hinting.
      if (hits.length > 200) return hits;
      if (size < 0) break;
    }
  }
  return hits;
}

// ---------------------------------------------------------------------------
// Empty rectangles
// ---------------------------------------------------------------------------

/// Two rows and two columns whose four intersections are all empty. When two
/// digits are confined to exactly those intersections, each row and each column
/// receives one of them, which exhausts both digits for both lines.
List<TechniqueHit> _emptyRectangles(TechniqueContext ctx) {
  final hits = <TechniqueHit>[];
  final size = GameConstants.boardSize;

  for (final r1 in List.generate(size, (i) => i)) {
    for (final r2 in List.generate(size, (i) => i).where((i) => i > r1)) {
      // The rectangle must be empty of givens.
      final colPool = <int>[];
      for (var c = 0; c < size; c++) {
        if (ctx.board[r1][c] == 0 && ctx.board[r2][c] == 0) colPool.add(c);
      }
      if (colPool.length < 2) continue;
      for (final cols in _combinations(colPool, 2)) {
        final c1 = cols[0];
        final c2 = cols[1];
        for (final pair in _digitCombinations(2)) {
          final d1 = pair[0];
          final d2 = pair[1];

          bool confined(int digit) {
            for (final r in [r1, r2]) {
              for (final p in ctx.rowPositions(r, digit)) {
                if (p.c != c1 && p.c != c2) return false;
              }
            }
            for (final c in [c1, c2]) {
              for (final p in ctx.colPositions(c, digit)) {
                if (p.r != r1 && p.r != r2) return false;
              }
            }
            return true;
          }

          if (!confined(d1) || !confined(d2)) continue;
          // Both digits must actually be waiting for a slot in the rectangle.
          final corners = [c1, c2].any(
            (c) =>
                ctx.rowPositions(r1, d1).any((p) => p.c == c) ||
                ctx.rowPositions(r2, d1).any((p) => p.c == c),
          );
          if (!corners) continue;

          final eliminations = <TechniqueElimination>[];
          final seen = <String>{};
          void addElim(int r, int c) {
            for (final d in [d1, d2]) {
              if (ctx.has((r: r, c: c), d) && seen.add('$r,$c,$d')) {
                eliminations.add(TechniqueElimination(r, c, d));
              }
            }
          }

          // The two digits are exhausted for rows r1/r2 and columns c1/c2 *outside*
          // the rectangle. The four corners are excluded: they are precisely
          // where the digits still have to go.
          for (final c in List.generate(size, (i) => i)) {
            if (c == c1 || c == c2) continue;
            addElim(r1, c);
            addElim(r2, c);
          }
          for (final r in List.generate(size, (i) => i)) {
            if (r == r1 || r == r2) continue;
            addElim(r, c1);
            addElim(r, c2);
          }
          if (eliminations.length < 2) continue;

          hits.add(
            TechniqueHit(
              strategy: SolvingStrategy.emptyRectangle,
              title: SolvingStrategy.emptyRectangle.label,
              body:
                  'Rows ${r1 + 1} and ${r2 + 1} cross columns ${c1 + 1} and '
                  '${c2 + 1} in an empty rectangle. Digits $d1 and $d2 can only '
                  'ever sit inside it.\n\n'
                  'Each of the two rows and each of the two columns still needs '
                  'one of them, so the four corners take exactly $d1 and $d2 — '
                  'once each per row and per column. Both digits are therefore '
                  'exhausted for those rows and columns.\n\n'
                  'This Empty Rectangle eliminates $d1 and $d2 from '
                  '${_describeCells(eliminations.map((e) => (r: e.row, c: e.col)))}.',
              eliminations: eliminations,
              highlights: _keys([
                (r: r1, c: c1),
                (r: r1, c: c2),
                (r: r2, c: c1),
                (r: r2, c: c2),
              ]),
            ),
          );
        }
      }
    }
  }
  return hits;
}
