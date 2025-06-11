import Foundation
import Flutter
import VLCKit

public class SwiftFlutterVlcPlayerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("🔧 [VLC Plugin] Starting plugin registration...")
        
        // Check if VLCKit is available
        let vlcLibrary = VLCLibrary.shared()
        print("🔧 [VLC Plugin] VLCKit library initialized: \(vlcLibrary)")
        print("🔧 [VLC Plugin] VLCKit version: \(vlcLibrary.version)")
        
        let vlcViewFactory = VLCViewFactory(registrar: registrar)
        registrar.register(vlcViewFactory, withId: "flutter_video_plugin/getVideoView")
        print("✅ [VLC Plugin] Successfully registered VLC view factory with ID: flutter_video_plugin/getVideoView")
        
        print("🔧 [VLC Plugin] Plugin registration completed")
    }
}
