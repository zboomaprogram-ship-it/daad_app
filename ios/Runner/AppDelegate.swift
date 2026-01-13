import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ✅ Configure audio session category ONLY - don't activate yet
    do {
      let audioSession = AVAudioSession.sharedInstance()
      // Set category and options but DON'T activate (setActive) yet
      // This prevents crash from early activation while still configuring the session
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
    } catch {
      print("⚠️ Failed to configure audio session: \(error)")
    }

    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

