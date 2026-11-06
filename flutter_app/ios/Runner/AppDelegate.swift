import Flutter
import UIKit

private let mediaBackupExclusionChannelName = "hear_me_out/media_backup_exclusion"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerMediaBackupExclusionChannel(
      messenger: engineBridge.applicationRegistrar.messenger()
    )
  }

  /// Registers the channel that keeps the recordings directory out of iCloud
  /// and computer backups. Dart calls `excludeFromBackup` with the directory
  /// path before opening the media store.
  private func registerMediaBackupExclusionChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: mediaBackupExclusionChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String,
        !path.isEmpty
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "A non-empty directory path is required.",
            details: nil
          )
        )
        return
      }

      let fileManager = FileManager.default
      var directory = URL(fileURLWithPath: path, isDirectory: true)

      do {
        // The Dart provider resolves this path before the store is first
        // opened, so the directory may not exist yet. Create it, then set
        // NSURLIsExcludedFromBackupKey so iOS leaves the recordings out of
        // iCloud and computer backups.
        if !fileManager.fileExists(atPath: directory.path) {
          try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)

        let confirmed = try directory.resourceValues(
          forKeys: [.isExcludedFromBackupKey]
        ).isExcludedFromBackup == true

        guard confirmed else {
          result(
            FlutterError(
              code: "exclusion_not_confirmed",
              message: "iOS did not confirm the backup exclusion.",
              details: path
            )
          )
          return
        }

        result(true)
      } catch {
        result(
          FlutterError(
            code: "exclusion_failed",
            message: error.localizedDescription,
            details: path
          )
        )
      }
    }
  }
}
