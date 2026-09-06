# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
