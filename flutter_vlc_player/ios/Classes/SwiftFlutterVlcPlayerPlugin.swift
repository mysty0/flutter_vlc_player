import Foundation
import Flutter

public class SwiftFlutterVlcPlayerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let vlcViewFactory = VLCViewFactory(registrar: registrar)
        registrar.register(vlcViewFactory, withId: "flutter_video_plugin/getVideoView")
        
        // Register thumbnail generation method channel
        let thumbnailChannel = FlutterMethodChannel(
            name: "flutter_vlc_player/thumbnail",
            binaryMessenger: registrar.messenger()
        )
        
        let thumbnailHandler = VLCThumbnailMethodChannelHandler()
        thumbnailChannel.setMethodCallHandler(thumbnailHandler.handle)
    }
}

/// Handles method channel calls for thumbnail generation
class VLCThumbnailMethodChannelHandler: NSObject {
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "generateThumbnail":
            handleGenerateThumbnail(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleGenerateThumbnail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let uri = arguments["uri"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid arguments for generateThumbnail",
                details: nil
            ))
            return
        }
        
        let width = arguments["width"] as? Int ?? 0
        let height = arguments["height"] as? Int ?? 0
        let position = arguments["position"] as? Double ?? 0.5
        
        print("🔧 [Thumbnail Handler] Generating thumbnail for: \(uri)")
        print("🔧 [Thumbnail Handler] Size: \(width)x\(height), Position: \(position)")
        
        // Call the static thumbnail generation method
        VLCViewController.generateThumbnail(
            from: uri,
            width: width,
            height: height,
            position: Float(position)
        ) { thumbnailBase64 in
            DispatchQueue.main.async {
                if let thumbnailBase64 = thumbnailBase64 {
                    print("✅ [Thumbnail Handler] Successfully generated thumbnail")
                    result(thumbnailBase64)
                } else {
                    print("❌ [Thumbnail Handler] Failed to generate thumbnail")
                    result(FlutterError(
                        code: "THUMBNAIL_GENERATION_FAILED",
                        message: "Failed to generate thumbnail",
                        details: nil
                    ))
                }
            }
        }
    }
}
