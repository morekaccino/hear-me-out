/// The plain invitation sent with a shared before/after card.
///
/// This is the only text a card share carries. It is an invitation, not a
/// claim: it names no score, percentage, rank, streak, leaderboard, or
/// comparison, and it contains no link or referral code. V1 has no server,
/// account, or install attribution, so a referral code would imply a
/// shares-to-installs metric the app cannot measure (decision 0012).
const String beforeAfterInviteText =
    'I practice guitar with Hear Me Out. If you want to read music and play '
    'guitar too, here is my progress card.';

/// The share-sheet subject for the before/after card.
const String beforeAfterShareSubject = 'Hear Me Out progress card';
