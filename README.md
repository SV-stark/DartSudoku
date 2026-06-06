# 🌌 DartSudoku

An elegant, modern Sudoku game and solver built with Flutter. DartSudoku implements a clean Material 3 design and uses a robust backtracking engine to deliver a highly interactive Sudoku playing and solving experience.

---

## ✨ Features

### 🎓 Sudoku School (Syllabus, Lessons & Active Practice)
- **Structured Curriculum**: A learning pathway consisting of 45 advanced solving strategies organized into 4 progressive difficulty tiers:
  - **Tier 1: Basics & Scanning** (e.g., Naked/Hidden Singles, Pairs, Triples, Quads, Locked Candidates)
  - **Tier 2: Advanced Fish** (e.g., X-Wing, Swordfish, Jellyfish, Finned/Sashimi variants)
  - **Tier 3: Wing Strategies** (e.g., Skyscraper, Two-String-Kite, Crane, Empty Rectangle, Y-Wing, XYZ-Wing, W-Wing)
  - **Tier 4: Chaining & Uniqueness** (e.g., Simple Coloring, X-Chain, XY-Chain, AIC, Forcing Chains, Unique Rectangles, BUG)
- **Interactive Autoplay Lessons**: Slide decks with autoplay controls (play/pause) that advance step-by-step, automatically pausing to wait for user interaction at key solving check-points.
- **Active Mastery Practice**:
  - **Realistic Board Generation**: Generates strategy-specific puzzles with ~35% pre-filled clues instead of blank cells, recreating authentic gameplay conditions.
  - **Guided Path/Link Tracing**: Traces conjugate chains and loops sequentially in order (supporting both forward and backward tracing, plus backtracking/untapping) to lock in recognition of advanced wing/chain techniques.
  - **Global Candidate Filtering**: Digit filter bar (1-9) that dims non-matching candidate notes, helping isolate and visualize complex patterns.
- **Time Attack Blitz Lobby**: A timed 3-minute recognition game mode designed to test recognition speed. Correct solves add points, while mistakes apply a 15-second time penalty.
- **School Analytics Dashboard**: A comprehensive statistics sheet tracking total mistakes, tier progress bars, average pattern recognition speed, and personalized training tips.

### 🎮 Play Mode
- **Three Levels of Difficulty**:
  - **Easy**: 32 starting clues.
  - **Medium**: 27 starting clues.
  - **Hard**: 22 starting clues.
- **Engine-Backed Unique Solutions**: All generated puzzles are guaranteed to have exactly **one unique solution**.
- **Interactive Tooling**:
  - **Notes (Pencil Mode)**: Jot down candidates. The board automatically filters out conflicting notes in the same row, column, or 3x3 box as you input correct values.
  - **Mistake Limits**: Play with up to 3 mistake hearts.
  - **Hint System**: Need a hand? Request a hint to open the Strategy Explainer, explaining why a number belongs in a cell.
  - **Unlimited Undo**: Complete list of moves kept so you can backtrack your steps at any time.
  - **Pause/Resume Timer**: Keep track of your solving time with an active game timer that can be paused at will.

### 🧮 Custom Grid Solver
Enter your custom Sudoku grids (e.g., from newspapers or other puzzles) and choose between two ways to solve:
1. **Solve Complete**: Resolves the entire board instantly.
2. **Solve Selected**: Computes the solution and reveals **only the selected cell**, allowing you to get a single clue while keeping the rest of the board in your current custom layout.
- **Real-Time Input Validation**: Instantly flags violations of Sudoku rules (e.g., duplicate entries in rows, columns, or subgrids) to prevent unsolvable runs.

---

## 🎨 Design Language
- **Visuals**: Modern, elegant Material 3 dark theme powered by an indigo seed color.
- **Components**: Solid cards, clean chips, and filled/tonal button configurations.
- **Grid Layout**: Features highly visible line separators utilising theme `outline` (thick lines separating 3x3 grids) and `outlineVariant` (thin lines separating individual cells) color palettes.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, 3.20.0 or higher recommended)
- [Dart SDK](https://dart.dev/get-started)
- Windows development tools (if building for Windows desktop, see [Desktop requirements](https://docs.flutter.dev/desktop))

### Running the App
To run the app locally in debug mode (web, mobile, or desktop depending on your active targets):

```bash
flutter run
```

### Running Unit & Widget Tests
We maintain 100% test coverage over Sudoku generation logic, solving heuristics, and view initialization. Run the test suite:

```bash
flutter test
```

### Building a Release

#### Windows Desktop
To build the standalone Windows executable:

```bash
flutter build windows
```
The build artifacts will be located in: `build/windows/x64/runner/Release/`

---

## 🛠️ Tech Stack & Architecture

- **Core Framework**: Flutter (Dart)
- **State Management**: Built-in `ChangeNotifier` state controllers (`SudokuGameProvider` & `SudokuSolverProvider`) designed for zero-dependency high performance.
- **Sudoku Heuristic Algorithm**: Optimized recursive backtracking utilizing the **Minimum Remaining Values (MRV)** heuristic to speed up unique solution validation and complete solvers.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
