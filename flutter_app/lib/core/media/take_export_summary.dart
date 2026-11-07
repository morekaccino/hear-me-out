import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../app_metadata.dart' as metadata;
import 'recording_index.dart';

/// What the summary can honestly say about stored practice evidence.
enum TakeExportEvidenceStatus {
  /// A real phrase progress record was read and copied into the summary.
  stored,

  /// The take is a free take, or its phrase has no stored progress record.
  /// This is a positive finding: there is nothing to include.
  none,

  /// The progress aggregate could not be read. The app must not claim there is
  /// no evidence when it simply could not look.
  unavailable,
}

/// One section of the plain-language header shared by the PDF and the
/// pre-export sheet.
class TakeSummaryHeaderSection {
  const TakeSummaryHeaderSection({
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;
}

/// The COPPA §6.5 export header: what the bundle contains, who it is for, the
/// retention rule, and how to delete it.
///
/// The pre-export sheet shows these sections before the share sheet opens, and
/// the PDF repeats them. A test asserts that every required statement is
/// present, so the sheet and the PDF cannot drift.
const List<TakeSummaryHeaderSection> takeSummaryHeader =
    <TakeSummaryHeaderSection>[
      TakeSummaryHeaderSection(
        title: 'WHAT THIS FILE CONTAINS',
        paragraphs: <String>[
          'One recorded guitar take (WAV), this one-page summary (PDF), and a '
              'JSON copy of this summary.',
        ],
      ),
      TakeSummaryHeaderSection(
        title: 'WHO IT IS FOR',
        paragraphs: <String>[
          'A teacher or another person the student chooses. The app does not '
              'send it to anyone; the student shares the files from the device '
              'share sheet or downloads them in a web browser.',
        ],
      ),
      TakeSummaryHeaderSection(
        title: 'KEEPING AND DELETING IT',
        paragraphs: <String>[
          'The teacher should delete this copy after the review, and no later '
              'than 90 days after receiving it.',
          "To delete the student's own copy, open Recordings and use Clear "
              'exported files on Android or iOS, or the browser downloads list '
              'on web. Delete and Clear all remove the stored take, not an '
              'export copy. The app never uploads the files.',
        ],
      ),
    ];

/// Human-readable piece details resolved from the launch-piece catalogue.
///
/// The summary never invents a title: when the catalogue has no entry the
/// caller passes null and the summary says the piece was not identified.
class TakeExportPiece {
  const TakeExportPiece({
    required this.title,
    required this.composer,
    this.stage,
  });

  final String title;
  final String composer;

  /// The V1 stage outcome number, when the piece has one.
  final int? stage;

  Map<String, Object?> toJson() => <String, Object?>{
    'title': title,
    'composer': composer,
    'stage': stage,
  };
}

/// Raw phrase evidence copied from `PhraseProgress`.
///
/// This is stored practice evidence, never a teacher grade and never a mastery
/// claim. The caller supplies it only when the take has a phrase id and a real
/// progress record exists.
class TakeExportEvidence {
  const TakeExportEvidence({
    required this.attempts,
    required this.performanceDays,
    required this.masteryDays,
    required this.contentVersion,
    this.bestAccuracy,
    this.bestTempoBpm,
    this.performanceSpanDays = 0,
    this.lastPerformedAt,
  });

  /// The fixed label carried with the JSON so the numbers cannot be mistaken
  /// for a teacher grade.
  static const String label = 'Stored practice evidence, not a teacher grade';

  final int attempts;

  /// Best raw note accuracy as a fraction in `[0, 1]`, when one was recorded.
  final double? bestAccuracy;

  /// Best tempo the learner played this phrase at, when known.
  final int? bestTempoBpm;

  /// Number of local days with a counted performance.
  final int performanceDays;

  /// Number of local days with a qualifying mastery take. This is raw evidence;
  /// the summary does not decide mastery.
  final int masteryDays;

  /// Days between the first and last counted performance day.
  final int performanceSpanDays;

  /// The phrase content version the evidence was earned against.
  final int contentVersion;

  final DateTime? lastPerformedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'attempts': attempts,
    'bestAccuracy': bestAccuracy,
    'bestTempoBpm': bestTempoBpm,
    'performanceDays': performanceDays,
    'masteryDays': masteryDays,
    'performanceSpanDays': performanceSpanDays,
    'contentVersion': contentVersion,
    'lastPerformedAt': lastPerformedAt?.toUtc().toIso8601String(),
  };
}

/// The versioned, one-take summary shared with a teacher.
///
/// The document deliberately contains no name, account, device or install id,
/// audio path, or free text the learner typed. It carries only the take's own
/// metadata, the resolved piece details, and stored phrase evidence when the
/// learner has some.
class TakeExportSummary {
  const TakeExportSummary({
    required this.takeId,
    required this.createdAt,
    required this.durationMs,
    required this.exportedAt,
    required this.appVersion,
    this.capped = false,
    this.pieceId,
    this.piece,
    this.phraseId,
    this.evidenceStatus = TakeExportEvidenceStatus.none,
    this.evidence,
  }) : assert(
         evidenceStatus != TakeExportEvidenceStatus.stored || evidence != null,
         'Stored evidence status requires an evidence block.',
       ),
       assert(
         evidenceStatus == TakeExportEvidenceStatus.stored || evidence == null,
         'An evidence block requires the stored status.',
       );

  /// Version of the JSON document written by this build.
  static const int schemaVersion = 1;

  final String takeId;

  /// Creation time in UTC.
  final DateTime createdAt;

  final int durationMs;

  /// True when the recorder stopped the take at the 60-second limit.
  final bool capped;

  /// When this summary was written, in UTC.
  final DateTime exportedAt;

  /// The app build that wrote the summary.
  final String appVersion;

  /// Stable piece id for machine matching, or null for a free take.
  final String? pieceId;

  /// Resolved human metadata. Null when the catalogue does not know the id.
  final TakeExportPiece? piece;

  /// The phrase the take was recorded against, when the take has one.
  final String? phraseId;

  /// Whether the evidence block is stored, absent, or unreadable.
  final TakeExportEvidenceStatus evidenceStatus;

  /// Stored practice evidence. Non-null only when [evidenceStatus] is
  /// [TakeExportEvidenceStatus.stored].
  final TakeExportEvidence? evidence;

  /// Builds the summary for one stored take.
  ///
  /// [piece] and [evidence] must already be resolved by the caller; core code
  /// does not import the content catalogue or the progress aggregate. Pass
  /// [TakeExportEvidenceStatus.unavailable] when the progress read failed;
  /// never report an unread record as [TakeExportEvidenceStatus.none].
  factory TakeExportSummary.fromTake({
    required RecordingTake take,
    required DateTime exportedAt,
    TakeExportPiece? piece,
    TakeExportEvidenceStatus evidenceStatus = TakeExportEvidenceStatus.none,
    TakeExportEvidence? evidence,
  }) => TakeExportSummary(
    takeId: take.id,
    createdAt: take.createdAt.toUtc(),
    durationMs: take.durationMs,
    capped: take.capped,
    exportedAt: exportedAt.toUtc(),
    appVersion: metadata.appVersion,
    pieceId: take.pieceId,
    piece: piece,
    phraseId: take.phraseId,
    evidenceStatus: evidenceStatus,
    evidence: evidence,
  );

  /// A stable, versioned map. Key order and nulls do not change between
  /// builds with the same schema version.
  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'takeId': takeId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'durationMs': durationMs,
    'capped': capped,
    'pieceId': pieceId,
    'piece': piece?.toJson(),
    'phraseId': phraseId,
    'appVersion': appVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'evidenceStatus': evidenceStatus.name,
    'evidence': evidence?.toJson(),
  };
}

/// Renders [summary] as a one-page A4 PDF using PDF standard fonts.
///
/// The shared [takeSummaryHeader] says what the bundle contains, who it is
/// for, how long the teacher may keep it, and how to delete it. The evidence
/// section is labelled as stored practice evidence; an absent record says so,
/// and an unread record says the evidence could not be read. Neither case
/// invents a score. Standard fonts cover WinAnsi/Latin-1; a future title or
/// composer outside that range needs a bundled font.
Future<Uint8List> buildTakeSummaryPdf(TakeExportSummary summary) async {
  final doc = pw.Document(
    title: 'Hear Me Out take summary',
    author: 'Hear Me Out',
    creator: 'Hear Me Out ${summary.appVersion}',
    theme: pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    ),
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'HEAR ME OUT',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.6,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Take export for a teacher',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'One page. A practice take, not a teacher grade.',
            style: pw.TextStyle(fontSize: 10.5, color: PdfColors.grey700),
          ),
          pw.Divider(height: 18),
          for (final section in takeSummaryHeader) ...[
            _sectionTitle(section.title),
            for (final paragraph in section.paragraphs) _body(paragraph),
          ],
          _sectionTitle('TAKE'),
          _row('Recorded', _formatUtc(summary.createdAt)),
          _row('Length', _formatDuration(summary.durationMs)),
          if (summary.capped)
            _body('The recorder stopped this take at the 60-second limit.'),
          _row('Piece', _pieceLine(summary)),
          if (summary.piece != null) _row('Composer', summary.piece!.composer),
          if (summary.piece?.stage != null)
            _row('Stage', '${summary.piece!.stage}'),
          if (summary.phraseId != null) _row('Phrase', summary.phraseId!),
          _sectionTitle('PRACTICE EVIDENCE'),
          ..._evidenceWidgets(summary),
          pw.SizedBox(height: 14),
          pw.Divider(),
          pw.Text(
            'Exported from Hear Me Out ${summary.appVersion} on '
            '${_formatUtc(summary.exportedAt)}.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'This summary contains no account, device, contact, or free-text '
            'information.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

String _pieceLine(TakeExportSummary summary) {
  final piece = summary.piece;
  if (piece != null) return piece.title;
  if (summary.pieceId == null) return 'Free take';
  return 'Not identified in this build';
}

List<pw.Widget> _evidenceWidgets(TakeExportSummary summary) {
  final evidence = summary.evidence;
  switch (summary.evidenceStatus) {
    case TakeExportEvidenceStatus.unavailable:
      return <pw.Widget>[
        _body('Practice evidence could not be read for this take.'),
        _body(
          'The app does not claim there is none. Reopen the app and export '
          'again if you need the stored evidence.',
        ),
      ];
    case TakeExportEvidenceStatus.none:
      return <pw.Widget>[
        _body('No stored practice evidence for this take.'),
        _body(
          'The take may be a free recording, or this phrase has no stored '
          'practice record. This summary does not invent a score or grade.',
        ),
      ];
    case TakeExportEvidenceStatus.stored:
      if (evidence == null) {
        // Defensive: the constructor asserts this pairing, but a bad caller
        // must still produce an honest page rather than a blank section.
        return <pw.Widget>[
          _body('Practice evidence could not be read for this take.'),
        ];
      }
      return <pw.Widget>[
        _body(TakeExportEvidence.label),
        _row('Attempts recorded', '${evidence.attempts}'),
        _row('Best note accuracy', _formatPercent(evidence.bestAccuracy)),
        _row(
          'Best tempo',
          evidence.bestTempoBpm == null
              ? 'Not recorded'
              : '${evidence.bestTempoBpm} BPM',
        ),
        _row('Practice days', '${evidence.performanceDays}'),
        _row('Full-accuracy at-target days', '${evidence.masteryDays}'),
        _row('Practice span', '${evidence.performanceSpanDays} days'),
        _row('Evidence content version', '${evidence.contentVersion}'),
        if (evidence.lastPerformedAt != null)
          _row('Last practiced', _formatUtc(evidence.lastPerformedAt!)),
      ];
  }
}

pw.Widget _sectionTitle(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 12, bottom: 3),
  child: pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 0.9,
      color: PdfColors.grey700,
    ),
  ),
);

pw.Widget _body(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 3),
  child: pw.Text(text, style: pw.TextStyle(fontSize: 10.5, lineSpacing: 2)),
);

pw.Widget _row(String label, String value) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 3),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.SizedBox(
        width: 170,
        child: pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10.5, color: PdfColors.grey700),
        ),
      ),
      pw.Expanded(
        child: pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  ),
);

String _formatPercent(double? value) {
  if (value == null || !value.isFinite) return 'Not recorded';
  return '${(value.clamp(0.0, 1.0) * 100).round()}%';
}

String _formatDuration(int durationMs) {
  final totalSeconds = (durationMs / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _formatUtc(DateTime time) {
  final utc = time.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)} UTC';
}
