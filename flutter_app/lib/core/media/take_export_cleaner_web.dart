import 'take_export_cleaner.dart';

/// The browser owns downloaded files, so the app has no exports folder to
/// clear on web. The screen hides the app-owned clear action and the docs
/// point at the browser's downloads list.
TakeExportCleaner createTakeExportCleaner({String exportsDirectory = ''}) =>
    const WebTakeExportCleaner();

class WebTakeExportCleaner implements TakeExportCleaner {
  const WebTakeExportCleaner();

  @override
  bool get isSupported => false;

  @override
  Future<TakeExportClearResult> clearExports() async =>
      const TakeExportClearResult();
}
