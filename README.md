# 🌌 Sudoku Nexus

A premium, neon-themed Sudoku game and solver built with Flutter. Sudoku Nexus blends state-of-the-art glassmorphic aesthetics with a robust backtracking engine to deliver a highly interactive Sudoku playing and solving experience.

---

## ✨ Features

### 🎮 Play Mode
- **Three Levels of Difficulty**:
  - **Easy**: 32 starting clues.
  - **Medium**: 27 starting clues.
  - **Hard**: 22 starting clues.
- **Engine-Backed Unique Solutions**: All generated puzzles are guaranteed to have exactly **one unique solution**.
- **Interactive Tooling**:
  - **Notes (Pencil Mode)**: Jot down candidates. The board automatically filters out conflicting notes in the same row, column, or 3x3 box as you input correct values.
  - **Mistake Limits**: Play with up to 3 mistake hearts.
  - **Hint System**: Need a hand? Get a hint for your currently selected cell.
  - **Unlimited Undo**: Complete list of moves kept so you can backtrack your steps at any time.
  - **Pause/Resume Timer**: Keep track of your solving time with an active game timer that can be paused at will.

### 🧮 Custom Grid Solver
Enter your custom Sudoku grids (e.g., from newspapers or other puzzles) and choose between two ways to solve:
1. **Solve Complete**: Resolves the entire board instantly.
2. **Solve Selected**: Computes the solution and reveals **only the selected cell**, allowing you to get a single clue while keeping the rest of the board in your current custom layout.
- **Real-Time Input Validation**: Instantly flags violations of Sudoku rules (e.g., duplicate entries in rows, columns, or subgrids) to prevent unsolvable runs.

---

## 🎨 Design Language
- **Visuals**: Futuristic deep-space dark theme (`#050811`) highlighted by glowing neon violet, cyan, and indigo accents.
- **Components**: Glassmorphic panels featuring radial blur and thin neon borders.
- **Micro-Animations**: Smooth scale/fade transitions on selection, input updates, and game overlays.

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
- **Sudoku Algorithm**: Optimized recursive backtracking utilizing the **Minimum Remaining Values (MRV)** heuristic to speed up unique solution validation and complete solvers.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
