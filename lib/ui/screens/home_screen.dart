import 'package:flutter/material.dart';
import '../theme.dart';
import 'game_screen.dart';
import 'solver_screen.dart';

/// The entry screen of the application offering play options and the solver utility.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 4.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Ambient glowing blobs in the background
              _buildBackgroundBlob(
                color: AppTheme.neonViolet.withOpacity(0.12),
                top: -100,
                left: -50,
                size: 300,
              ),
              _buildBackgroundBlob(
                color: AppTheme.neonCyan.withOpacity(0.12),
                bottom: -100,
                right: -50,
                size: 300,
              ),
              
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo Area
                      _buildLogo(),
                      const SizedBox(height: 50),
                      
                      // Play Mode Card
                      _buildPlayCard(),
                      const SizedBox(height: 24),
                      
                      // Solver Mode Card
                      _buildSolverCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundBlob({
    required Color color,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 100,
              spreadRadius: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.neonViolet,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonViolet.withOpacity(0.35),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.grid_3x3_rounded,
                size: 56,
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'SUDOKU',
          style: AppTheme.titleStyle.copyWith(fontSize: 38),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'N E X U S',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: AppTheme.neonCyan.withOpacity(0.5),
                blurRadius: 10,
              )
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlayCard() {
    return AppTheme.glassEffect(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_outline_rounded, color: AppTheme.neonCyan, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Select Game Level',
                  style: AppTheme.titleStyle.copyWith(fontSize: 20, shadows: []),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Challenge yourself with standard game boards featuring unique, solvable solutions.',
              style: AppTheme.subtitleStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildDifficultyButton(
              label: 'EASY',
              color: AppTheme.neonGreen,
              onTap: () => _startGame('easy'),
            ),
            const SizedBox(height: 12),
            _buildDifficultyButton(
              label: 'MEDIUM',
              color: AppTheme.neonAmber,
              onTap: () => _startGame('medium'),
            ),
            const SizedBox(height: 12),
            _buildDifficultyButton(
              label: 'HARD',
              color: AppTheme.neonRed,
              onTap: () => _startGame('hard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolverCard() {
    return AppTheme.glassEffect(
      borderColor: AppTheme.neonCyan.withOpacity(0.2),
      child: InkWell(
        onTap: _openSolver,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate_rounded, color: AppTheme.neonCyan, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Sudoku Solver',
                          style: AppTheme.titleStyle.copyWith(fontSize: 20, shadows: []),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Input your custom grids and let the solver resolve the board completely, or query answers for selected squares only.',
                      style: AppTheme.subtitleStyle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.neonCyan,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          color: color.withOpacity(0.08),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(difficulty: difficulty),
      ),
    );
  }

  void _openSolver() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SolverScreen(),
      ),
    );
  }
}
