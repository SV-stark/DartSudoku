class TierDefinition {
  final int tierNumber;
  final String name;
  final String description;
  final int startLessonIndex;
  final int endLessonIndex;
  final int
  requiredPractices; // Practices required of this tier to unlock the NEXT tier

  const TierDefinition({
    required this.tierNumber,
    required this.name,
    required this.description,
    required this.startLessonIndex,
    required this.endLessonIndex,
    required this.requiredPractices,
  });

  int get totalLessons => endLessonIndex - startLessonIndex + 1;

  bool containsLesson(int lessonIndex) {
    return lessonIndex >= startLessonIndex && lessonIndex <= endLessonIndex;
  }
}

const List<TierDefinition> appTiers = [
  TierDefinition(
    tierNumber: 1,
    name: 'Tier 1: Basics & scanning',
    description:
        'Naked/Hidden Singles, Pairs, Triples, Quads, Locked Candidates',
    startLessonIndex: 0,
    endLessonIndex: 11,
    requiredPractices: 3,
  ),
  TierDefinition(
    tierNumber: 2,
    name: 'Tier 2: Advanced Fish',
    description: 'X-Wing, Swordfish, Jellyfish, Finned/Sashimi variants',
    startLessonIndex: 12,
    endLessonIndex: 21,
    requiredPractices: 3,
  ),
  TierDefinition(
    tierNumber: 3,
    name: 'Tier 3: Wing Strategies',
    description:
        'Skyscraper, Two-String-Kite, Crane, Empty Rectangle, Y-Wing, XYZ-Wing, W-Wing',
    startLessonIndex: 22,
    endLessonIndex: 29,
    requiredPractices: 3,
  ),
  TierDefinition(
    tierNumber: 4,
    name: 'Tier 4: Chaining & Uniqueness',
    description:
        'Simple Coloring, X-Chain, XY-Chain, AIC, Forcing Chains, Unique Rectangles, BUG',
    startLessonIndex: 30,
    endLessonIndex: 44,
    requiredPractices: 3,
  ),
  TierDefinition(
    tierNumber: 5,
    name: 'Tier 5: ALS & Advanced Geometry',
    description:
        'Almost Locked Sets (ALS-XZ, ALS-XY-Wing, Death Blossom), Advanced Uniqueness (UR Type 6, Avoidable Rectangle), Sue de Coq, Exocet',
    startLessonIndex: 45,
    endLessonIndex: 51,
    requiredPractices: 0,
  ),
];
