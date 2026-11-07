import 'take_share_gateway.dart';

/// The web build has no reliable file share sheet.
///
/// The bundle exporter already downloaded the three files through the browser,
/// so this gateway reports that sharing is unavailable instead of pretending a
/// Web Share API call succeeded. See `docs/MANUAL_EXPORT.md`.
TakeShareGateway createTakeShareGateway() =>
    const UnsupportedTakeShareGateway(
      message:
          'Your browser downloaded the three files. Share them from your '
          'downloads folder.',
    );
