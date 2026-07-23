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

### 🎮 Play Mode & Gamification
- **Three Levels of Difficulty**: Easy (32 clues), Medium (27 clues), Hard (22 clues).
- **Engine-Backed Unique Solutions**: All generated puzzles are guaranteed to have exactly **one unique solution**.
- **Interactive Tooling**:
  - **Notes (Pencil Mode)**: Jot down candidates. The board automatically filters out conflicting notes in the same row, column, or 3x3 box as you input correct values.
  - **Mistake Limits**: Play with up to 3 mistake hearts.
  - **Hint System**: Request a hint to open the Strategy Explainer, explaining why a number belongs in a cell.
  - **Unlimited Undo/Redo**: Complete move history so you can step back and forward at any time.
  - **Pause/Resume Timer**: Keep track of your solving time with an active game timer.
- **Audio & Haptic Feedback System**: Tactile clicks, note toggles, mistake alerts, hint reveals, and victory fanfares (`AudioService`).
- **Trophies & Achievements**: Unlock badges like *First Step*, *Speed Demon*, *Weekly Warrior*, *Sudoku Scholar*, and *Master Tactician*.

### 📅 Daily Challenge & Streak Engine
- **Date-Based Reproducible Puzzles**: Generates a unique daily Sudoku puzzle using deterministic date seeds.
- **Streak & Monthly Progress Tracking**: Complete daily puzzles to build active streaks and earn calendar star badges (`DailyChallengeManager`).

### 🎨 Multi-Color Cell & Candidate Palette (Chaining Tools)
- **5-Color Highlight Palette**: Paint cell backgrounds or individual candidate notes with Blue, Green, Orange, or Purple tints for tracing conjugate chains, wings, and coloring techniques directly on the grid.

### 🧩 Sudoku Variants & Rules Engine
- **Sudoku X (Diagonal Sudoku)**: Enforces rule constraints where both main 9-cell diagonals must contain unique digits 1–9.
- **Killer Sudoku Cages**: Dotted cage outlines with target sum badges requiring digits within each cage to sum up without repeating.

### 🤖 AI Smart Coach Diagnostics & "Why Is This Wrong?"
- **Detailed Conflict Analysis**: Instant diagnostic modal explaining *why* an entered number is incorrect (row, column, 3x3 box, diagonal, or downstream candidate elimination conflict).

### 🎬 Game Session Replay & Hesitation Heatmap
- **Interactive Solve Replay Scrubber**: Step-by-step time-lapse playback modal with play/pause and 1x, 2x, 4x speed controls.
- **Hesitation Heatmap**: Visual green-to-red gradient overlay on cells highlighting where you hesitated or spent the longest duration thinking.

### 🧮 Custom Grid Solver & Camera OCR Importer
Enter custom Sudoku grids (from newspapers or books) and solve:
1. **Solve Complete**: Resolves the entire board instantly.
2. **Solve Selected**: Computes solution for only the selected cell.
3. **Solve Step**: Resolves cells step-by-step with strategy explanations.
- **81-Character SDK & Camera OCR String Import**: Paste standard 81-char Sudoku puzzle strings or raw camera OCR photo text (`SudokuOCRScanner`).
- **Real-Time Input Validation**: Flags rule violations to prevent unsolvable runs.

---


## 🎨 Design Language
- **Visuals**: Modern, elegant Material 3 design with dark mode, customizable seed palettes, and hint highlight styling.
- **Responsive Layout**: Optimized side-by-side dual-pane layout for desktop and tablet screens (>768px width) alongside compact mobile viewports.
- **Grid Layout**: Highly visible line separators utilizing theme `outline` (3x3 grid borders) and `outlineVariant` (cell borders).

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
