# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.0] - 2026-10-02

### Added
- **Fifteen advanced solving techniques** in a new `lib/core/sudoku_techniques.dart` registry, each with a structured detector and a human-readable explanation:
  - Tier 1 — **Naked Triple**, **Hidden Triple**
  - Tier 2 — **Swordfish**, **Jellyfish**, **Finned X-Wing**, **Sashimi X-Wing**
  - Tier 3 — **Y-Wing**, **XYZ-Wing**, **W-Wing**, **Empty Rectangle**
  - Tier 4 — **Simple Coloring**, **X-Chain**, **XY-Chain**, **Alternating Inference Chain**, **Unique Rectangles**
- **A binary-implication chain engine** backing the contradiction techniques. For each digit it builds an implication graph over "cell holds digit" and "cell does not hold digit" literals — candidate elimination between peers, plus the two-way and XY-Wing implications that arise when a unit is down to two candidate cells — then searches for alternating chains from established truth values. X-Chain, XY-Chain and Alternating Inference Chain are distinguished purely by chain shape (XY pivots present or not, four or more positive literals), so one engine serves all three.
- **A soundness oracle** (`test/sudoku_techniques_test.dart`) that asserts every elimination any detector reports is actually wrong in the puzzle's unique solution, across all difficulties and 40 seeds each. A wrong elimination teaches the player something false, so this is enforced as a test rather than trusted to review.
- **A detector-coverage test** asserting that every technique the picker advertises is actually produced somewhere in a generated-puzzle corpus. "The oracle didn't flag it" had been silently indistinguishable from "it never ran".
- **`SolvingStrategy`** enum with `strategyForName` / `isStrategySupported` / `supportedStrategyNames`, so the UI can advertise only techniques that genuinely work.
- **Technique hit metadata**: every hit now carries its eliminations and highlight cells, so the grid can paint the pattern that justified the hint rather than just the target cell.

### Fixed
- **Two unsound chain-engine bugs caught by the oracle before release**:
  - The contradiction rule eliminated the digit from the *second-to-last positive literal anywhere on the chain*. That is only valid when every positive follows the previous one directly; when a positive is separated from its neighbour by a negative, the conclusion does not follow. Elimination is now derived by walking the chain backwards from the contradiction and proving each antecedent false via the contrapositive `¬B ⟹ ¬A`, so a digit is only removed where that is genuinely established.
  - A second search pass built "forced placement" chains starting from a *known-false* antecedent. A false antecedent implies nothing, so the pass asserted placements it had not proved — and then cleared the digit from every peer of those invented placements. The pass is deleted; only chains terminating in a real contradiction now produce eliminations.
- **Three unsound pattern detectors caught by the oracle**:
  - The hidden-triple rule accepted digit sets containing digits already placed in the unit. A row containing `1` made `{1,2,6}` look like a hidden triple in three cells, so the technique eliminated the `1` that was actually sitting there. It now requires every digit to be unplaced and to still have a position.
  - `_digitCombinations` generated combinations *with repeats* (`[1,1]`), silently turning "hidden triple" into a bogus single-digit rule. Combinations are now strictly increasing.
  - The empty-rectangle rule eliminated its own candidates from the four corners, which are exactly where the confined digits still have to go. Eliminations are now confined to the cells *outside* the rectangle.

### Changed
- **The strategy picker now offers 21 real techniques** across four tiers. Techniques that are sound but too rare for generated puzzles to contain are marked with a dice icon and a tooltip explaining that the generator may not be able to build one — instead of implying a guarantee the generator cannot keep.
- **Targeted generation reports honestly**: `generateTargetedPuzzle` returns a `TargetedPuzzleResult` carrying `achievedTarget` and a note, and the dialog surfaces a snackbar when the requested technique could not be built instead of quietly substituting another puzzle.
- **Strategy matching is structural**: a technique is identified from a `SolvingStrategy` enum rather than a substring search over the explanation prose, which previously matched whenever one technique's wording mentioned another's name.

### Known limitations
- **Skyscraper and Two-String-Kite are not implemented** and are absent from the picker. A Skyscraper's eliminations reduce to X-Wing and fish eliminations, so it is not a distinct technique here, and no sound distinct formulation of Two-String-Kite was found. Rather than invent one, both are omitted. The earlier attempt at Simple Coloring and X-Chain — which two-coloured each digit's candidate graph, a vacuous colouring because that graph is always bipartite — was written, rejected by the oracle, and replaced by the chain engine above.
- **X-Wing, Swordfish, Jellyfish, XYZ-Wing, Empty Rectangle, X-Chain, XY-Chain and Alternating Inference Chain are sound but do not fire on randomly generated puzzles.** Fish patterns only eliminate once their base rows or columns shed further candidates, and a chain needs a propagated contradiction that a generated position does not produce. They remain selectable and the generator reports honestly when it cannot build one, but they are excluded from the corpus reachability assertion for that reason.

## [0.9.1] - 2026-10-02

### Fixed
- **Daily challenges were not reproducible across retries**: `newGame` re-seeded the generator with `seed + attempt` on retry, so a player whose first generation attempt failed received a *different* puzzle from everyone else on the same date. Retries now reuse the same seed, and the retry budget comes from `GameConstants.maxGenerationRetries` instead of a hardcoded `3`.
- **A loss could be recorded as a win**: after the final mistake, `enterNumber` set `gameOver` and then fell through to the win check, which could overwrite the status and record a phantom victory. It now returns immediately.
- **Duplicate daily-challenge writes**: completions were recorded by both `GameScreen` and `DailyChallengeManager`, which wrote two divergent lists. `DailyChallengeManager` is now the single source of truth, and legacy dates are migrated once rather than dual-written forever.
- **Legacy daily completions were invisible**: the home screen only read the new preference key, so days completed by older builds looked unplayed.
- **Hint highlights leaked for the rest of the game**: choosing "KEEP THINKING" left the hint overlay painted on the board permanently. The overlay is now anchored to its cell and retires on selection change or the next move.
- **Hint highlights were invisible in portrait**: only the landscape layout passed `customCellBgs` to the grid, so hint annotations never rendered in the default orientation.
- **Mistake diagnostics pointed at the wrong cell**: the logical-violation fallback returned the cell the player had just typed into as the "conflicting" cell. `conflictCell` is now nullable and is only set for genuine conflicts; the UI flashes the peer cell when one exists.
- **Resumed games lost hints and cell colours**: `loadSavedGame` reset the hint counter to zero (letting a resumed game retroactively qualify for a no-hint achievement) and discarded all colour annotations. Both are now persisted and validated on restore.
- **Hint-highlight and flash state survived into new games**: applying a new puzzle did not clear the previous board's overlays.
- **Undo could resurrect a stale redo stack**: the redo stack had no depth cap, so repeated undo/redo grew memory without bound. Both stacks are now capped at `GameConstants.maxUndoHistory`.
- **Entering an out-of-range digit was accepted**: `enterNumber` had no 1-9 validation.
- **Streak counting broke across DST boundaries**: the daily-challenge streak used `Duration(days: 1)` arithmetic, which can yield 0 or 2 days across a daylight-saving transition. It now uses calendar arithmetic and rejects impossible dates.
- **Stats silently no-opped for unknown difficulties**: `recordGameStart` used a null-aware increment that discarded the result when a difficulty had no entry yet, and `recordGameWin` force-unwrapped the same map and could throw.
- **Achievements could be lost to a write race**: `unlockDetailed` performed an unsynchronised read-modify-write, so two concurrent unlocks could clobber each other.
- **Spurious input**: `Ctrl`/`Alt`/`Meta` combinations such as `Ctrl+N` were treated as digit or navigation input in both the game and solver screens.
- **The game never resumed after a spurious pause**: the app paused on the transient `inactive` lifecycle state (fired by the notification shade and system dialogs) and never auto-resumed, so a momentary interruption could leave a game frozen.
- **Invisible mistakes in endless mode**: the mistake row always rendered exactly three hearts, so mistakes four and beyond were never shown.
- **Killer puzzles could generate an unsolvable cage set**: cage generation did not verify distinct digits per cage or full board coverage, and the solver had no cage-sum feasibility pruning.
- **Solver accepted invalid input**: `SudokuSolverProvider.solverBoard` exposed the mutable internal grid, letting callers bypass validation entirely.
- **Indefinite search on empty candidates**: minimum-remaining-values cell selection did not short-circuit on zero candidates, so unsatisfiable boards explored the full search space before giving up.
- **Puzzle generation silently ignored the requested difficulty**: when no attempt reached the target removal count, the generator returned whatever it had without indicating the shortfall.
- **Player notes were invisible in dark mode**: candidate colours used fixed light-mode tones with very low contrast on dark cells.

### Changed
- **Targeted Strategy Generator no longer overpromises**: the picker listed 23 techniques but the hint engine only implements 6, so requests for the other 17 silently returned an unrelated puzzle. Unimplemented tiers are now shown as "coming soon" and disabled, strategy matching is structural (via a new `SolvingStrategy` enum) rather than a substring search over explanation prose, and `generateTargetedPuzzle` returns a `TargetedPuzzleResult` that reports when the target technique could not be built.
- **Kill candidate rendering is theme-aware**: candidate colours now derive from the active colour scheme. Cell-highlight hues are unchanged so a given colour always means the same thing.
- **Mistake counter and header layout are overflow-safe**: the mistake row uses a `Wrap` sized to the actual count, and the header adapts on narrow screens instead of overflowing.
- **Worksheet export can be copied**: the printable-HTML dialog gained a "COPY HTML" action and explanatory instructions.
- **Resuming a saved game restores its variant**: the home screen passed hardcoded `easy`/`standard` placeholders, so restarting a resumed Killer or hard game silently downgraded it.
- **Restart paths use live provider state**: the retry/try-again/play-again buttons now read the active difficulty and variant from the provider rather than the stale constructor arguments.
- **Unmodified dependencies**: upgraded `cupertino_icons` to `^2.0.0` and refreshed 15 transitive dependencies. 17 further updates remain held back because they are pinned by the Flutter SDK.

### Performance
- **Puzzle uniqueness checking no longer blocks the UI thread**: the designer screen ran `hasUniqueSolution` synchronously on every cell edit, freezing the interface on near-empty grids. It is now debounced and executed in a background isolate, with a progress indicator and stale-result protection.
- **SDK puzzle import dropped from 160+ rebuilds to one**: importing an 81-character string called `selectCell` plus `enterNumber`/`clearCell` per cell. It now uses a single validating `loadBoard` call, and no longer leaves the cursor stranded on the bottom-right cell.
- **Worksheet export solves off the UI thread**: the solvability check moved into an isolate.
- **Killer cage lookup is now O(1)**: per-cell cage scans were replaced with a prebuilt index, and the three duplicated minimum-remaining-values scans were consolidated into one.
- **Solver board views are cached**: the read-only mirror is rebuilt only when the grid actually changes.
- **Achievement and stats writes are serialised**: concurrent read-modify-write cycles are queued rather than racing.
- **Hesitation heatmap uses peak timings**: revisiting a cell overwrote its recorded hesitation instead of keeping the slowest time, and the normaliser ignored all but the single slowest move.

### Added
- **`SudokuSolverProvider.loadBoard`** for validated bulk grid replacement.
- **`SolvingStrategy` and `SudokuAnalyzer.classifyStrategy`** for structured technique detection, plus `isStrategySupported` / `supportedStrategyNames` so callers can check support before requesting a technique.
- **Persistable hint count and cell/candidate colours**, restored and validated when a saved game is loaded.
- **`AchievementsManager.resetAchievements`** to complement the existing stats reset.
- **`SudokuLogic.countSolutions`**, `KillerCageIndex`, `isCageConfigurationValid` and `areCagesSatisfied` for public solver and generator checks.

---

## [0.9.0] - 2026-09-06

### Added
- **Targeted Generator Injection Pipeline**: Direct puzzle injection route via `GameScreen.fromPuzzle` and `SudokuGameProvider.loadPuzzle`, avoiding dropped generation results.
- **Provider Error State & Timeout Guard**: Added `GameStatus.error` with user-facing error UI, a 3x generation retry budget, and a 15-second timeout on puzzle generation.
- **Solve Replay State Snapshots**: `MoveRecord` now stores full board snapshots (`BoardState`) and `MoveActionType`, guaranteeing 100% deterministic replay playback across undo, redo, hints, and erases.
- **Granular Achievement Results**: Added `unlockDetailed` on `AchievementsManager` returning `AchievementUnlockResult` (`unlocked`, `alreadyUnlocked`, `error`).
- **Strict Static Analysis**: Enforced `await_only_futures`, `unawaited_futures`, `use_build_context_synchronously`, `cancel_subscriptions`, and `close_sinks`.
- **Regression Test Suite**: Added dedicated unit tests covering puzzle injection, move snapshots, error state resilience, achievement unlocking, and provider lifecycle cleanup (60 tests passing).

### Fixed
- **Win & Game Over Re-triggering**: Added guard flags (`_hasHandledWin`, `_hasHandledGameOver`, `_isShowingMistakeDialog`) preventing duplicate victory fanfares, streak increments, and mistake dialogs on notify calls.
- **Targeted Generator UI Freeze**: Offloaded heavy generation in `TargetedGeneratorDialog` to background isolate (`Isolate.run`) with progress spinner and error SnackBar.
- **Custom Answers Dialog Freeze**: Moved step-by-step breakdown solver in `CustomAnswersDialog` off the UI thread via `Isolate.run`.
- **Shift-Key Notes Race Condition**: `enterNumber` now accepts an explicit `asNote` argument, eliminating asynchronous key-toggle races.
- **Corrupt Saved Game Handling**: Guarded saved game loading against corrupt/empty JSON states by cleanly falling back to a fresh game.
- **Designer Screen Validation**: Added board validity and solvability checks before generating printable PDFs.
- **Daily Challenge Midnight & Navigation**: Fixed date-only comparisons, calendar navigation month boundaries, and post-pop reload lifecycle.
- **Controller & Timer Memory Leaks**: Added `SudokuGameProvider.dispose()` to flush pending state and cancel timers; disposed `TextEditingController` in solver dialog; auto-paused confetti animations after 15 seconds.
- **Tutorial Screen State Mutation**: Eliminated `setState` calls during `didChangeDependencies` and ensured deterministic lesson RNG.

### Performance
- **Optimized Grid Rendering**: Removed 81 individual `RepaintBoundary` wrappers inside cell widgets, preserving the single root boundary.
- **Killer Cage Pre-Indexing**: Pre-computed cage lookups into O(1) hash maps per build cycle, removing redundant O(N) scans.
- **Hesitation Heatmap Caching**: Cached hesitation heatmap computations across non-move rebuilds.

---

## [0.8.5] - 2026-07-23

### Added
- Multi-Color cell and candidate palette for conjugate chain and wing visualization.
- Sudoku variants support: Diagonal Sudoku (Sudoku X) and Killer Sudoku cage sums.
- AI Smart Coach diagnostics with "Why Is This Wrong?" conflict modal.
- Solve Replay scrubber with hesitation heatmap overlay.
- Camera OCR puzzle scanner and 81-character SDK import.

---

## [0.8.0] - 2026-06-15

### Added
- Custom Puzzle Designer with interactive entry and validation.
- Printable PDF Exporter with answer keys and solution sheets.
- Live visual link and candidate relation hints.

---

## [0.7.5] - 2026-05-20

### Added
- Intuitive visual strategy teaching system in Sudoku School.
- Strategy-specific practice boards and guided conjugate link tracing.
