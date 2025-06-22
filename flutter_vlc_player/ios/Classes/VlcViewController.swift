import Flutter
import Foundation
import VLCKit
import UIKit


public class VLCViewController: NSObject, FlutterPlatformView {
    
    var hostedView: UIView
    var vlcMediaPlayer: VLCMediaPlayer
    var mediaEventChannel: FlutterEventChannel
    let mediaEventChannelHandler: VLCPlayerEventStreamHandler
    var rendererEventChannel: FlutterEventChannel
    let rendererEventChannelHandler: VLCRendererEventStreamHandler
    var rendererdiscoverers: [VLCRendererDiscoverer] = .init()
    
    public func view() -> UIView {
        return self.hostedView
    }
    
    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
        print("🔧 [VLC Controller] Initializing VLCViewController for viewId: \(viewId)")
        print("🔧 [VLC Controller] Frame: \(frame)")
        
        let mediaEventChannel = FlutterEventChannel(
            name: "flutter_video_plugin/getVideoEvents_\(viewId)",
            binaryMessenger: messenger
        )
        let rendererEventChannel = FlutterEventChannel(
            name: "flutter_video_plugin/getRendererEvents_\(viewId)",
            binaryMessenger: messenger
        )
        
        print("🔧 [VLC Controller] Created event channels")
        print("🔧 [VLC Controller] Media channel: flutter_video_plugin/getVideoEvents_\(viewId)")
        print("🔧 [VLC Controller] Renderer channel: flutter_video_plugin/getRendererEvents_\(viewId)")
        
        self.hostedView = UIView(frame: frame)
        print("🔧 [VLC Controller] Created hosted view")
        
        self.vlcMediaPlayer = VLCMediaPlayer()
        print("✅ [VLC Controller] Successfully created VLCMediaPlayer")
        print("🔧 [VLC Controller] VLCMediaPlayer: \(self.vlcMediaPlayer)")
        
//        self.vlcMediaPlayer.libraryInstance.debugLogging = true
//        self.vlcMediaPlayer.libraryInstance.debugLoggingLevel = 3
        self.mediaEventChannel = mediaEventChannel
        self.mediaEventChannelHandler = VLCPlayerEventStreamHandler()
        self.rendererEventChannel = rendererEventChannel
        self.rendererEventChannelHandler = VLCRendererEventStreamHandler()
        
        print("🔧 [VLC Controller] Created event handlers")
        
        //
        self.mediaEventChannel.setStreamHandler(self.mediaEventChannelHandler)
        self.rendererEventChannel.setStreamHandler(self.rendererEventChannelHandler)
        print("🔧 [VLC Controller] Set event stream handlers")
        
        self.vlcMediaPlayer.drawable = self.hostedView
        self.vlcMediaPlayer.delegate = self.mediaEventChannelHandler
        self.mediaEventChannelHandler.mediaPlayer = self.vlcMediaPlayer // Store reference
        print("🔧 [VLC Controller] Set drawable and delegate")
        
        print("✅ [VLC Controller] VLCViewController initialization completed")
    }
    
    public func play() {
        print("🔧 [VLC Controller] Playing media player")
        self.vlcMediaPlayer.play()
    }
    
    public func pause() {
        print("🔧 [VLC Controller] Pausing media player")
        self.vlcMediaPlayer.pause()
    }
    
    public func stop() {
        print("🔧 [VLC Controller] Stopping media player")
        self.vlcMediaPlayer.stop()
    }
    
    public func isPlaying() -> NSNumber?{
        
        return self.vlcMediaPlayer.isPlaying as NSNumber
    }
    
    public func isSeekable() -> NSNumber? {
        
        return self.vlcMediaPlayer.isSeekable as NSNumber
    }
    
    public func setLooping(isLooping: NSNumber?) {
        
        let enableLooping = isLooping?.boolValue ?? false;
        self.vlcMediaPlayer.media?.addOption(enableLooping ? "--loop" : "--no-loop")
    }
    
    public func seek(position: NSNumber?) {
        
        self.vlcMediaPlayer.time = VLCTime(number: position ?? 0)
    }
    
    public func position() -> NSNumber? {
        
        return self.vlcMediaPlayer.time.value
    }
    
    public func duration() -> NSNumber? {
        
        return self.vlcMediaPlayer.media?.length.value ?? 0
        
    }
    
    public func setVolume(volume: NSNumber?) {
        
        self.vlcMediaPlayer.audio?.volume = volume?.int32Value ?? 100
    }
    
    public func getVolume() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.audio?.volume ?? 100)
    }
    
    public func setPlaybackSpeed(speed: NSNumber?) {
        
        self.vlcMediaPlayer.rate = speed?.floatValue ?? 1
    }
    
    public func getPlaybackSpeed() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.rate)
    }
    
    public func takeSnapshot() -> String? {
        
        let drawable: UIView = self.vlcMediaPlayer.drawable as! UIView
        let size = drawable.frame.size
        UIGraphicsBeginImageContextWithOptions(size, _: false, _: 0.0)
        let rec = drawable.frame
        drawable.drawHierarchy(in: rec, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let byteArray = (image ?? UIImage()).pngData()
        //
        return byteArray?.base64EncodedString()
    }
    
    /// Generate thumbnail from video file using VLCMediaThumbnailer
    /// - Parameters:
    ///   - uri: The video file URI
    ///   - width: Desired thumbnail width (0 for original)
    ///   - height: Desired thumbnail height (0 for original)
    ///   - position: Position in video (0.0 to 1.0, default is 0.5)
    ///   - completion: Completion handler with base64 encoded image
    public func generateThumbnail(
        uri: String,
        width: Int = 0,
        height: Int = 0,
        position: Float = 0.5,
        completion: @escaping (String?) -> Void
    ) {
        print("🔧 [VLC Thumbnailer] Generating thumbnail for: \(uri)")
        print("🔧 [VLC Thumbnailer] Size: \(width)x\(height), Position: \(position)")
        
        // Create VLCMedia from URI
        guard let url = URL(string: uri) else {
            print("❌ [VLC Thumbnailer] Invalid URI: \(uri)")
            completion(nil)
            return
        }
        
        let media = VLCMedia(url: url)
        print("✅ [VLC Thumbnailer] Created VLCMedia")
        
        // Create thumbnailer using the proper VLCKit approach
        let thumbnailer = VLCMediaThumbnailer(
            media: media,
            delegate: nil,
            andVLCLibrary: VLCLibrary.shared()
        )
        print("✅ [VLC Thumbnailer] Created VLCMediaThumbnailer")
        
        // Set thumbnail size
        if width > 0 {
            thumbnailer.thumbnailWidth = width
        }
        if height > 0 {
            thumbnailer.thumbnailHeight = height
        }
        
        // Set snapshot position (if supported)
        if thumbnailer.responds(to: #selector(setter: VLCMediaThumbnailer.snapshotPosition)) {
            thumbnailer.snapshotPosition = position
        }
        
        print("🔧 [VLC Thumbnailer] Starting thumbnail fetch...")
        
        // Create delegate wrapper to handle the callback
        let delegateWrapper = VLCThumbnailerDelegateWrapper(completion: completion)
        thumbnailer.delegate = delegateWrapper
        
        // Store reference to prevent deallocation during async operation
        objc_setAssociatedObject(
            thumbnailer,
            &VLCThumbnailerDelegateWrapper.associatedObjectKey,
            delegateWrapper,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        thumbnailer.fetchThumbnail()
    }
    
    /// Static method for generating thumbnails without needing a view controller instance
    public static func generateThumbnail(
        from uri: String,
        width: Int = 0,
        height: Int = 0,
        position: Float = 0.5,
        completion: @escaping (String?) -> Void
    ) {
        print("🔧 [VLC Static Thumbnailer] Generating thumbnail for: \(uri)")
        print("🔧 [VLC Static Thumbnailer] Size: \(width)x\(height), Position: \(position)")
        
        // Create VLCMedia from URI
        guard let url = URL(string: uri) else {
            print("❌ [VLC Static Thumbnailer] Invalid URI: \(uri)")
            completion(nil)
            return
        }
        
        let media = VLCMedia(url: url)
        print("✅ [VLC Static Thumbnailer] Created VLCMedia")
        
        // Create thumbnailer using the proper VLCKit approach
        let thumbnailer = VLCMediaThumbnailer(
            media: media,
            delegate: nil,
            andVLCLibrary: VLCLibrary.shared()
        )
        print("✅ [VLC Static Thumbnailer] Created VLCMediaThumbnailer")
        
        // Set thumbnail size
        if width > 0 {
            thumbnailer.thumbnailWidth = width
        }
        if height > 0 {
            thumbnailer.thumbnailHeight = height
        }
        
        // Set snapshot position (if supported)
        if thumbnailer.responds(to: #selector(setter: VLCMediaThumbnailer.snapshotPosition)) {
            thumbnailer.snapshotPosition = position
        }
        
        print("🔧 [VLC Static Thumbnailer] Starting thumbnail fetch...")
        
        // Create delegate wrapper to handle the callback
        let delegateWrapper = VLCThumbnailerDelegateWrapper(completion: completion)
        thumbnailer.delegate = delegateWrapper
        
        // Store reference to prevent deallocation during async operation
        objc_setAssociatedObject(
            thumbnailer,
            &VLCThumbnailerDelegateWrapper.associatedObjectKey,
            delegateWrapper,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        thumbnailer.fetchThumbnail()
    }
    
    public func getSpuTracksCount() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.subtitles().count)
    }
    
    public func getSpuTracks() -> [Int:String]? {
        
        return self.vlcMediaPlayer.subtitles()
    }
    
    public func setSpuTrack(spuTrackNumber: NSNumber?) {
        
        let trackNumber = spuTrackNumber?.intValue ?? 0
        self.vlcMediaPlayer.selectTrack(at: trackNumber, type: .text)
    }
    
    public func getSpuTrack() -> NSNumber? {
        
        let textTracks = self.vlcMediaPlayer.textTracks
        for (index, track) in textTracks.enumerated() {
            if track.isSelected {
                return NSNumber(value: index)
            }
        }
        return NSNumber(value: -1)
    }
    
    public func setSpuDelay(delay: NSNumber?) {
        
        self.vlcMediaPlayer.currentVideoSubTitleDelay = delay?.intValue ?? 0
    }
    
    public func getSpuDelay() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.currentVideoSubTitleDelay)
    }
    
    public func addSubtitleTrack(uri: String?, isSelected: NSNumber?) {
        
        // TODO: check for file type
        guard let urlString = uri,
              let url = URL(string: urlString)
        else {
            return
        }
        
        self.vlcMediaPlayer.addPlaybackSlave(
            url,
            type: VLCMediaPlaybackSlaveType.subtitle,
            enforce: isSelected?.boolValue ?? true
        )
    }
    
    public func getAudioTracksCount() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.audioTracks.count)
    }
    
    public func getAudioTracks() -> [Int:String]? {
        
        return self.vlcMediaPlayer.audioTracks()
    }
    
    public func setAudioTrack(audioTrackNumber: NSNumber?) {
        
        let trackNumber = audioTrackNumber?.intValue ?? 0
        self.vlcMediaPlayer.selectTrack(at: trackNumber, type: .audio)
    }
    
    public func getAudioTrack() -> NSNumber? {
        
        let audioTracks = self.vlcMediaPlayer.audioTracks
        for (index, track) in audioTracks.enumerated() {
            if track.isSelected {
                return NSNumber(value: index)
            }
        }
        return NSNumber(value: -1)
    }
    
    public func setAudioDelay(delay: NSNumber?) {
        
        self.vlcMediaPlayer.currentAudioPlaybackDelay = delay?.intValue ?? 0
    }
    
    public func getAudioDelay() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.currentAudioPlaybackDelay)
    }
    
    public func addAudioTrack(uri: String?, isSelected: NSNumber?) {
        
        // TODO: check for file type
        guard let urlString = uri,
              let url = URL(string: urlString)
        else {
            return
        }
        self.vlcMediaPlayer.addPlaybackSlave(
            url,
            type: VLCMediaPlaybackSlaveType.audio,
            enforce: isSelected?.boolValue ?? true
        )
    }
    
    public func getVideoTracksCount() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.videoTracks.count)
    }
    
    public func getVideoTracks() -> [Int:String]? {
        
        return self.vlcMediaPlayer.videoTracks()
    }
    
    public func setVideoTrack(videoTrackNumber: NSNumber?) {
        
        let trackNumber = videoTrackNumber?.intValue ?? 0
        self.vlcMediaPlayer.selectTrack(at: trackNumber, type: .video)
    }
    
    public func getVideoTrack() -> NSNumber? {
        
        let videoTracks = self.vlcMediaPlayer.videoTracks
        for (index, track) in videoTracks.enumerated() {
            if track.isSelected {
                return NSNumber(value: index)
            }
        }
        return NSNumber(value: -1)
    }
    
    public func setVideoScale(scale: NSNumber?) {
        
        self.vlcMediaPlayer.scaleFactor = scale?.floatValue ?? 1
    }
    
    public func getVideoScale() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.scaleFactor)
    }
    
    public func setVideoAspectRatio(aspectRatio: String?) {
        
        self.vlcMediaPlayer.videoAspectRatio = aspectRatio
    }
    
    public func getVideoAspectRatio() -> String? {
        
        return self.vlcMediaPlayer.videoAspectRatio ?? "1"
    }
    
    public func getAvailableRendererServices() -> [String]? {
        
        return self.vlcMediaPlayer.rendererServices()
    }
    
    public func startRendererScanning() {
        
        self.rendererdiscoverers.removeAll()
        self.rendererEventChannelHandler.renderItems.removeAll()
        // chromecast service name: "Bonjour_renderer"
        let rendererServices = self.vlcMediaPlayer.rendererServices()
        for rendererService in rendererServices {
            guard let rendererDiscoverer
                = VLCRendererDiscoverer(name: rendererService)
            else {
                continue
            }
            rendererDiscoverer.delegate = self.rendererEventChannelHandler
            rendererDiscoverer.start()
            self.rendererdiscoverers.append(rendererDiscoverer)
        }
    }
    
    public func stopRendererScanning() {
        
        for rendererDiscoverer in self.rendererdiscoverers {
            rendererDiscoverer.stop()
            rendererDiscoverer.delegate = nil
        }
        self.rendererdiscoverers.removeAll()
        self.rendererEventChannelHandler.renderItems.removeAll()
        if self.vlcMediaPlayer.isPlaying {
            self.vlcMediaPlayer.pause()
        }
        self.vlcMediaPlayer.setRendererItem(nil)
    }
    
    public func getRendererDevices() -> [String: String]? {
        
        var rendererDevices: [String: String] = [:]
        let rendererItems = self.rendererEventChannelHandler.renderItems
        for (_, item) in rendererItems.enumerated() {
            rendererDevices[item.name] = item.name
        }
        return rendererDevices
    }
    
    public func cast(rendererDevice: String?) {
        
        if self.vlcMediaPlayer.isPlaying {
            self.vlcMediaPlayer.pause()
        }
        let rendererItems = self.rendererEventChannelHandler.renderItems
        let rendererItem = rendererItems.first {
            $0.name.contains(rendererDevice ?? "")
        }
        self.vlcMediaPlayer.setRendererItem(rendererItem)
        self.vlcMediaPlayer.play()
    }
    
    public func startRecording(saveDirectory: String) -> NSNumber{
        self.vlcMediaPlayer.startRecording(atPath: saveDirectory)
        return NSNumber(value: true) // VLCKit v4: startRecording returns Void, so we return true to indicate success
    }
    
    public func stopRecording() -> NSNumber{
        self.vlcMediaPlayer.stopRecording()
        return NSNumber(value: true) // VLCKit v4: stopRecording returns Void, so we return true to indicate success
    }
    
    public func dispose(){
        self.mediaEventChannel.setStreamHandler(nil)
        self.rendererEventChannel.setStreamHandler(nil)
        self.rendererdiscoverers.removeAll()
        self.rendererEventChannelHandler.renderItems.removeAll()
        self.vlcMediaPlayer.stop()
    }
    
    func setMediaPlayerUrl(uri: String, isAssetUrl: Bool, autoPlay: Bool, hwAcc: Int, options: [String]){
        print("🔧 [VLC Controller] Setting media URL: \(uri)")
        print("🔧 [VLC Controller] isAssetUrl: \(isAssetUrl), autoPlay: \(autoPlay), hwAcc: \(hwAcc)")
        print("🔧 [VLC Controller] Options: \(options)")
        
        self.vlcMediaPlayer.stop()
        print("🔧 [VLC Controller] Stopped current media player")
        
        var media: VLCMedia
        if isAssetUrl {
            print("🔧 [VLC Controller] Processing asset URL...")
            guard let path = Bundle.main.path(forResource: uri, ofType: nil) else {
                print("❌ [VLC Controller] Failed to find asset path for: \(uri)")
                return
            }
            print("🔧 [VLC Controller] Found asset path: \(path)")
            
            guard let vlcMedia = VLCMedia(path: path) else {
                print("❌ [VLC Controller] Failed to create VLCMedia from path: \(path)")
                return
            }
            print("✅ [VLC Controller] Successfully created VLCMedia from asset path")
            media = vlcMedia
        }
        else {
            print("🔧 [VLC Controller] Processing network/file URL...")
            guard let url = URL(string: uri) else {
                print("❌ [VLC Controller] Failed to create URL from string: \(uri)")
                return
            }
            print("🔧 [VLC Controller] Created URL: \(url)")
            
            guard let vlcMedia = VLCMedia(url: url) else {
                print("❌ [VLC Controller] Failed to create VLCMedia from URL: \(url)")
                return
            }
            print("✅ [VLC Controller] Successfully created VLCMedia from URL")
            media = vlcMedia
        }
        
        if !options.isEmpty {
            print("🔧 [VLC Controller] Adding \(options.count) custom options...")
            for option in options {
                media.addOption(option)
                print("🔧 [VLC Controller] Added option: \(option)")
            }
        } else {
            print("🔧 [VLC Controller] No custom options to add")
        }
        
        print("🔧 [VLC Controller] Configuring hardware acceleration: \(hwAcc)")
        switch HWAccellerationType(rawValue: hwAcc) {
        case .HW_ACCELERATION_DISABLED:
            media.addOption("--codec=avcodec")
            print("🔧 [VLC Controller] Added HW acceleration disabled option")

        case .HW_ACCELERATION_DECODING:
            media.addOption("--codec=all")
            media.addOption(":no-mediacodec-dr")
            media.addOption(":no-omxil-dr")
            print("🔧 [VLC Controller] Added HW acceleration decoding options")

        case .HW_ACCELERATION_FULL:
            media.addOption("--codec=all")
            print("🔧 [VLC Controller] Added HW acceleration full option")

        case .HW_ACCELERATION_AUTOMATIC:
            print("🔧 [VLC Controller] Using automatic HW acceleration")
            break

        case .none:
            print("🔧 [VLC Controller] No HW acceleration type specified")
            break
        }
        
        print("🔧 [VLC Controller] Assigning media to player...")
        self.vlcMediaPlayer.media = media
        print("✅ [VLC Controller] Successfully assigned media to player")
        
//        self.vlcMediaPlayer.media!.parse(withOptions: VLCMediaParsingOptions(VLCMediaParseLocal | VLCMediaFetchLocal | VLCMediaParseNetwork | VLCMediaFetchNetwork))
        
        if autoPlay {
            print("🔧 [VLC Controller] Starting playback (autoPlay = true)")
            self.vlcMediaPlayer.play()
            print("✅ [VLC Controller] Started playback")
        } else {
            print("🔧 [VLC Controller] Not auto-playing (autoPlay = false)")
            self.vlcMediaPlayer.play()
            self.vlcMediaPlayer.stop()
            print("🔧 [VLC Controller] Player prepared but stopped")
        }
        
        print("✅ [VLC Controller] setMediaPlayerUrl completed successfully")
    }
}

class VLCRendererEventStreamHandler: NSObject, FlutterStreamHandler, VLCRendererDiscovererDelegate {
    
    private var rendererEventSink: FlutterEventSink?
    var renderItems: [VLCRendererItem] = .init()
    
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        self.rendererEventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        
        self.rendererEventSink = nil
        return nil
    }
    
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        
        self.renderItems.append(item)
        
        guard let rendererEventSink = self.rendererEventSink else { return }
        
        DispatchQueue.main.async {
            rendererEventSink([
                "event": "attached",
                "id": item.name,
                "name": item.name,
            ])
        }
    }
    
    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        
        if let index = self.renderItems.firstIndex(of: item) {
            self.renderItems.remove(at: index)
        }
        
        guard let rendererEventSink = self.rendererEventSink else { return }
        
        DispatchQueue.main.async {
            rendererEventSink([
                "event": "detached",
                "id": item.name,
                "name": item.name,
            ])
        }
    }
}

class VLCPlayerEventStreamHandler: NSObject, FlutterStreamHandler, VLCMediaPlayerDelegate, VLCMediaDelegate  {
    
    private var mediaEventSink: FlutterEventSink?
    weak var mediaPlayer: VLCMediaPlayer? // Store reference to the player
    
    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        self.mediaEventSink = events
        return nil
    }
    
    func onCancel(withArguments _: Any?) -> FlutterError? {
        
        self.mediaEventSink = nil
        return nil
    }
    
    // Helper method to get the selected track index from a track array
    private func getSelectedTrackIndex(tracks: [VLCMediaPlayer.Track]?) -> Int {
        guard let tracks = tracks else { return -1 }
        for (index, track) in tracks.enumerated() {
            if track.isSelected {
                return index
            }
        }
        return -1
    }
    
    @objc func mediaPlayerStateChanged(_ state: VLCMediaPlayerState) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        guard let player = self.mediaPlayer else { return }
        
        // Dispatch to main thread to avoid Flutter threading issues
        DispatchQueue.main.async {
            let media = player.media
            
            // Safe access to video properties - only when in playing state
            var height: CGFloat = 0
            var width: CGFloat = 0
            
            if state == .playing || state == .buffering {
                let videoSize = player.videoSize
                height = videoSize.height
                width = videoSize.width
            }
            
            let audioTracksCount = player.audioTracks.count
            let activeAudioTrack = self.getSelectedTrackIndex(tracks: player.audioTracks)
            let spuTracksCount = player.textTracks.count
            let activeSpuTrack = self.getSelectedTrackIndex(tracks: player.textTracks)
            let duration = media?.length.value ?? 0
            let speed = player.rate
            let position = player.time.value?.intValue ?? 0
            let buffering = 100.0
            let isPlaying = player.isPlaying
                    
            switch state {
            case .opening:
                mediaEventSink([
                    "event": "opening",
                ])
                
            case .paused:
                mediaEventSink([
                    "event": "paused",
                ])
                
            case .stopped:
                mediaEventSink([
                    "event": "stopped",
                ])
                
            case .playing:
                mediaEventSink([
                    "event": "playing",
                    "height": height,
                    "width": width,
                    "speed": speed,
                    "duration": duration,
                    "audioTracksCount": audioTracksCount,
                    "activeAudioTrack": activeAudioTrack,
                    "spuTracksCount": spuTracksCount,
                    "activeSpuTrack": activeSpuTrack,
                ])
                
            case .stopping:
                mediaEventSink([
                    "event": "ended",
                    "position": position,
                ])
                
            case .buffering:
                mediaEventSink([
                    "event": "timeChanged",
                    "height": height,
                    "width": width,
                    "speed": speed,
                    "duration": duration,
                    "position": position,
                    "buffer": buffering,
                    "audioTracksCount": audioTracksCount,
                    "activeAudioTrack": activeAudioTrack,
                    "spuTracksCount": spuTracksCount,
                    "activeSpuTrack": activeSpuTrack,
                    "isPlaying": isPlaying,
                ])
                
            case .error:
                mediaEventSink([
                    "event": "error",
                ])
                
            default:
                break
            }
        }
    }
    
    func mediaPlayerStartedRecording(_ player: VLCMediaPlayer) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        DispatchQueue.main.async {
            mediaEventSink([
                "event": "recording",
                "isRecording": true,
                "recordPath": "",
            ])
        }
    }
    
    func mediaPlayer(_ player: VLCMediaPlayer, recordingStoppedAt url: URL?) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        DispatchQueue.main.async {
            mediaEventSink([
                "event": "recording",
                "isRecording": false,
                "recordPath": url?.path ?? "",
            ])
        }
    }
    
    @objc func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        let player = aNotification.object as? VLCMediaPlayer
        
        // Dispatch to main thread to avoid Flutter threading issues
        DispatchQueue.main.async {
            // Safe access to video properties - only when playing
            var height: CGFloat = 0
            var width: CGFloat = 0
            
            if let player = player, player.isPlaying && player.state == .playing {
                let videoSize = player.videoSize
                height = videoSize.height
                width = videoSize.width
            }
            
            let speed = player?.rate ?? 1
            let duration = player?.media?.length.value ?? 0
            let audioTracksCount = player?.audioTracks.count ?? 0
            let activeAudioTrack = self.getSelectedTrackIndex(tracks: player?.audioTracks)
            let spuTracksCount = player?.textTracks.count ?? 0
            let activeSpuTrack = self.getSelectedTrackIndex(tracks: player?.textTracks)
            let buffering = 100.0
            let isPlaying = player?.isPlaying ?? false
            
            if let position = player?.time.value {
                mediaEventSink([
                    "event": "timeChanged",
                    "height": height,
                    "width": width,
                    "speed": speed,
                    "duration": duration,
                    "position": position,
                    "buffer": buffering,
                    "audioTracksCount": audioTracksCount,
                    "activeAudioTrack": activeAudioTrack,
                    "spuTracksCount": spuTracksCount,
                    "activeSpuTrack": activeSpuTrack,
                    "isPlaying": isPlaying,
                ])
            }
        }
    }
}

enum DataSourceType: Int {
    case ASSET = 0
    case NETWORK = 1
    case FILE = 2
}

enum HWAccellerationType: Int {
    case HW_ACCELERATION_AUTOMATIC = 0
    case HW_ACCELERATION_DISABLED = 1
    case HW_ACCELERATION_DECODING = 2
    case HW_ACCELERATION_FULL = 3
}


extension VLCMediaPlayer {
    
    func subtitles() -> [Int: String] {
        // VLCKit v4: Use new track API instead of deprecated properties
        let tracks = self.textTracks
        var subtitles: [Int: String] = [:]
        
        for (index, track) in tracks.enumerated() {
            subtitles[index] = track.trackName
        }
        
        return subtitles
    }
    
    func audioTracks() -> [Int: String] {
        // VLCKit v4: Use new track API instead of deprecated properties
        let tracks = self.audioTracks
        var audios: [Int: String] = [:]
        
        for (index, track) in tracks.enumerated() {
            audios[index] = track.trackName
        }
        
        return audios
    }
    
    func videoTracks() -> [Int: String] {
        // VLCKit v4: Use new track API instead of deprecated properties
        let tracks = self.videoTracks
        var videos: [Int: String] = [:]
        
        for (index, track) in tracks.enumerated() {
            videos[index] = track.trackName
        }
        
        return videos
    }
    
    func rendererServices() -> [String] {
        
        let renderers = VLCRendererDiscoverer.list()
        var services: [String] = []
        
        renderers?.forEach { VLCRendererDiscovererDescription in
            services.append(VLCRendererDiscovererDescription.name)
        }
        return services
    }
    
}

/// Delegate wrapper for VLCMediaThumbnailer to handle thumbnail generation
class VLCThumbnailerDelegateWrapper: NSObject, VLCMediaThumbnailerDelegate {
    static var associatedObjectKey: UInt8 = 0
    
    private let completion: (String?) -> Void
    
    init(completion: @escaping (String?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    // MARK: - VLCMediaThumbnailerDelegate
    
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer, didFinishThumbnail thumbnail: CGImage?) {
        print("✅ [VLC Thumbnailer] Successfully generated thumbnail")
        
        guard let thumbnail = thumbnail else {
            print("❌ [VLC Thumbnailer] Thumbnail is nil")
            completion(nil)
            return
        }
        
        // Convert CGImage to UIImage and then to base64
        let uiImage = UIImage(cgImage: thumbnail)
        guard let imageData = uiImage.pngData() else {
            print("❌ [VLC Thumbnailer] Failed to convert thumbnail to PNG data")
            completion(nil)
            return
        }
        
        let base64String = imageData.base64EncodedString()
        print("✅ [VLC Thumbnailer] Converted thumbnail to base64, length: \(base64String.count)")
        
        completion(base64String)
    }
    
    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer) {
        print("⏰ [VLC Thumbnailer] Thumbnail generation timed out")
        completion(nil)
    }
}

