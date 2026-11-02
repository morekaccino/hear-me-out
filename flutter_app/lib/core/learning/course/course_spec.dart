import '../objective.dart';

class CourseSection {
  const CourseSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.units,
  });

  final int number;
  final String title;
  final String subtitle;
  final List<CourseUnit> units;

  String get id => 'c3s$number';
}

class CourseUnit {
  const CourseUnit({
    required this.number,
    required this.title,
    required this.focus,
    required this.concepts,
    this.reviewUnits = const [],
    this.checkpointSize = 20,
  });

  final int number;
  final String title;
  final String focus;

  /// The unit's teachable objectives. Order matters: lessons 1 and 3 introduce
  /// the first four, lesson 5 can introduce the rest.
  final List<ObjectiveRef> concepts;

  /// Earlier unit numbers whose concepts should be eligible for review.
  final List<int> reviewUnits;

  final int checkpointSize;

  String get id => 'c3u$number';

  String get sectionId => 'c3s${((number - 1) ~/ 5) + 1}';
}
