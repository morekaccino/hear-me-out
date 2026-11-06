import '../../core/music/playability.dart';
import '../score/authoring.dart';
import 'etude_generator.dart';

/// Review state of a generated etude candidate.
///
/// A new candidate is always [pendingHuman]. Only [approved] records may be
/// presented as library content, and only a human reviewer can create one.
enum CandidateStatus {
  pendingHuman('pending-human'),
  approved('approved'),
  rejected('rejected');

  const CandidateStatus(this.wireName);

  /// Stable value used in approval records and tooling output.
  final String wireName;

  static CandidateStatus? tryParse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final status in CandidateStatus.values) {
      if (status.wireName == normalized) return status;
    }
    return null;
  }
}

/// A generated etude plus its review record.
///
/// The candidate defaults to [CandidateStatus.pendingHuman]. [approve] is the
/// only way to reach [CandidateStatus.approved], and it re-runs both the
/// structural score checks and the playability validator first. A candidate
/// that fails either check cannot be approved.
class GeneratedEtudeCandidate {
  const GeneratedEtudeCandidate({
    required this.etude,
    this.status = CandidateStatus.pendingHuman,
    this.reviewer,
    this.reviewedOn,
    this.notes,
  });

  final GeneratedEtude etude;
  final CandidateStatus status;

  /// Human pedagogue who approved or rejected the candidate. Never set by the
  /// generator.
  final String? reviewer;

  /// ISO-8601 review date, filled by the human reviewer.
  final String? reviewedOn;

  final String? notes;

  String get id => etude.candidateId;

  bool get isPendingHuman => status == CandidateStatus.pendingHuman;

  bool get isApproved =>
      status == CandidateStatus.approved &&
      (reviewer?.trim().isNotEmpty ?? false) &&
      (reviewedOn?.trim().isNotEmpty ?? false);

  bool get isRejected => status == CandidateStatus.rejected;

  /// Approves the candidate after re-validating it.
  ///
  /// Throws [ArgumentError] when the reviewer or date is blank, and
  /// [StateError] when the score fails `Score.validate()`, the T3.2 authoring
  /// validator, or the T3.7 playability validator.
  GeneratedEtudeCandidate approve({
    required String reviewer,
    required String reviewedOn,
    String? notes,
  }) {
    final trimmedReviewer = reviewer.trim();
    if (trimmedReviewer.isEmpty) {
      throw ArgumentError.value(
        reviewer,
        'reviewer',
        'A human reviewer is required to approve a candidate.',
      );
    }
    final trimmedDate = reviewedOn.trim();
    if (trimmedDate.isEmpty) {
      throw ArgumentError.value(
        reviewedOn,
        'reviewedOn',
        'A review date is required to approve a candidate.',
      );
    }

    final report = validateCandidateScore(
      etude.score,
      limits: etude.spec.playabilityLimits,
    );
    final authoringIssues = AuthoringValidator(etude.score).validate();
    final blocking = <String>[
      for (final issue in report.scoreIssues)
        if (issue.isError) issue.toString(),
      for (final issue in report.playabilityIssues)
        if (issue.isError) issue.toString(),
      for (final issue in authoringIssues)
        if (issue.isError) issue.toString(),
    ];
    if (blocking.isNotEmpty) {
      throw StateError(
        'Candidate $id cannot be approved because it fails validation:\n'
        '${blocking.join('\n')}',
      );
    }

    return GeneratedEtudeCandidate(
      etude: etude,
      status: CandidateStatus.approved,
      reviewer: trimmedReviewer,
      reviewedOn: trimmedDate,
      notes: notes,
    );
  }

  /// Rejects the candidate. Rejection is also a human decision; it never
  /// changes the generated score.
  GeneratedEtudeCandidate reject({
    required String reviewer,
    required String reviewedOn,
    String? notes,
  }) {
    final trimmedReviewer = reviewer.trim();
    if (trimmedReviewer.isEmpty) {
      throw ArgumentError.value(
        reviewer,
        'reviewer',
        'A human reviewer is required to reject a candidate.',
      );
    }
    final trimmedDate = reviewedOn.trim();
    if (trimmedDate.isEmpty) {
      throw ArgumentError.value(
        reviewedOn,
        'reviewedOn',
        'A review date is required to reject a candidate.',
      );
    }
    return GeneratedEtudeCandidate(
      etude: etude,
      status: CandidateStatus.rejected,
      reviewer: trimmedReviewer,
      reviewedOn: trimmedDate,
      notes: notes,
    );
  }

  /// Serializes the approval record, not the etude itself.
  ///
  /// The record is safe to store next to a scratch candidate. It is not a
  /// shipped asset and carries no musical authority.
  Map<String, dynamic> toRecordJson() {
    return <String, dynamic>{
      'id': id,
      'level': etude.level,
      'seed': etude.seed,
      'status': status.wireName,
      if (reviewer != null) 'reviewer': reviewer,
      if (reviewedOn != null) 'reviewedOn': reviewedOn,
      if (notes != null) 'notes': notes,
    };
  }
}

/// In-memory candidate registry with a human-approval gate.
///
/// [approved] and [approvedEtudes] are the only library-facing views. New
/// candidates are registered as `pending-human`. The library never writes to
/// `assets/content/etudes/`; promotion to the shipped set is a separate
/// reviewed commit.
class GeneratedEtudeLibrary {
  GeneratedEtudeLibrary();

  final Map<String, GeneratedEtudeCandidate> _candidates =
      <String, GeneratedEtudeCandidate>{};

  /// Registers a candidate as `pending-human`.
  ///
  /// Re-registering an existing id returns the existing record so a later
  /// generation cannot silently downgrade an approval.
  GeneratedEtudeCandidate register(GeneratedEtude etude) {
    final existing = _candidates[etude.candidateId];
    if (existing != null) return existing;
    final candidate = GeneratedEtudeCandidate(etude: etude);
    _candidates[etude.candidateId] = candidate;
    return candidate;
  }

  /// Only approved candidates, with a reviewer and date.
  List<GeneratedEtudeCandidate> get approved => <GeneratedEtudeCandidate>[
    for (final candidate in _candidates.values)
      if (candidate.isApproved) candidate,
  ];

  /// Only approved scores, for a future reviewed library loader.
  List<GeneratedEtude> get approvedEtudes => <GeneratedEtude>[
    for (final candidate in approved) candidate.etude,
  ];

  /// Candidates waiting for a pedagogue. This is a review queue, not a
  /// library view.
  List<GeneratedEtudeCandidate> get pendingHuman => <GeneratedEtudeCandidate>[
    for (final candidate in _candidates.values)
      if (candidate.isPendingHuman) candidate,
  ];

  List<GeneratedEtudeCandidate> get rejected => <GeneratedEtudeCandidate>[
    for (final candidate in _candidates.values)
      if (candidate.isRejected) candidate,
  ];

  List<GeneratedEtudeCandidate> get all =>
      List<GeneratedEtudeCandidate>.unmodifiable(_candidates.values);

  GeneratedEtudeCandidate? candidate(String id) => _candidates[id];

  /// Approves a registered candidate. Returns false when the id is unknown.
  bool approve(
    String id, {
    required String reviewer,
    required String reviewedOn,
    String? notes,
  }) {
    final candidate = _candidates[id];
    if (candidate == null) return false;
    _candidates[id] = candidate.approve(
      reviewer: reviewer,
      reviewedOn: reviewedOn,
      notes: notes,
    );
    return true;
  }

  /// Rejects a registered candidate. Returns false when the id is unknown.
  bool reject(
    String id, {
    required String reviewer,
    required String reviewedOn,
    String? notes,
  }) {
    final candidate = _candidates[id];
    if (candidate == null) return false;
    _candidates[id] = candidate.reject(
      reviewer: reviewer,
      reviewedOn: reviewedOn,
      notes: notes,
    );
    return true;
  }

  /// Approval records for every registered candidate, in registration order.
  List<Map<String, dynamic>> get approvalRecords => <Map<String, dynamic>>[
    for (final candidate in _candidates.values) candidate.toRecordJson(),
  ];
}
