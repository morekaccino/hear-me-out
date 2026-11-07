/// The app version written into exported take summaries.
///
/// Keep this in sync with the `version:` line in `pubspec.yaml`. The version is
/// defined here once so the summary JSON and the PDF cannot drift from each
/// other; `test/take_export_summary_test.dart` fails when this constant and
/// `pubspec.yaml` disagree.
const String appVersion = '4.0.0';
