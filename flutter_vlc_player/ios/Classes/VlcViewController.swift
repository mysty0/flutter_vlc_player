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
        print("🔧 [VLC Controller] Set drawable and delegate")
        
        print("✅ [VLC Controller] VLCViewController initialization completed")
    }
    
    public func play() {
        self.vlcMediaPlayer.play()
    }
    
    public func pause() {
        self.vlcMediaPlayer.pause()
    }
    
    public func stop() {
        self.vlcMediaPlayer.stop()
    }
    
    public var isPlaying: Bool {
        self.vlcMediaPlayer.isPlaying
    }
    
    public var isSeekable: Bool {
        self.vlcMediaPlayer.isSeekable
    }
    
    public func setLooping(isLooping: Bool) {
        self.vlcMediaPlayer.media?.addOption(isLooping ? "--loop" : "--no-loop")
    }
    
    public func seek(position: Int64) {
        self.vlcMediaPlayer.time = VLCTime(number: position as NSNumber)
    }
    
    public var position: Int32 {
        self.vlcMediaPlayer.time.intValue
    }
    
    public var duration: Int32 {
        self.vlcMediaPlayer.media?.length.intValue ?? 0
    }
    
    public func setVolume(volume: Int64) {
        self.vlcMediaPlayer.audio?.volume = volume.int32
    }
    
    public var volume: Int32 {
        self.vlcMediaPlayer.audio?.volume ?? 100
    }
    
    public func setPlaybackSpeed(speed: Float) {
        self.vlcMediaPlayer.rate = speed
    }
    
    public var playbackSpeed: Float {
        self.vlcMediaPlayer.rate
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
    
    public var spuTracksCount: Int {
        return self.vlcMediaPlayer.subtitles().count
    }
    
    public var spuTracks: [Int: String] {
        self.vlcMediaPlayer.subtitles()
    }
    
    public func setSpuTrack(spuTrackNumber: Int) {
        self.vlcMediaPlayer.selectTrack(at: spuTrackNumber, type: .text)
    }
    
    public var spuTrack: Int {
        let textTracks = self.vlcMediaPlayer.textTracks
        for (index, track) in textTracks.enumerated() {
            if track.isSelected {
                return index
            }
        }
        return -1
    }
    
    public func setSpuDelay(delay: Int) {
        self.vlcMediaPlayer.currentVideoSubTitleDelay = delay
    }
    
    public var spuDelay: Int {
        self.vlcMediaPlayer.currentVideoSubTitleDelay
    }
    
    public func addSubtitleTrack(uri: String, isSelected: Bool) {
        // TODO: check for file type
        guard
            let url = URL(string: uri)
        else {
            return
        }
        
        self.vlcMediaPlayer.addPlaybackSlave(
            url,
            type: VLCMediaPlaybackSlaveType.subtitle,
            enforce: isSelected
        )
    }
    
    public var audioTracksCount: Int32 {
        Int32(self.vlcMediaPlayer.audioTracks.count)
    }
    
    public var audioTracks: [Int: String] {
        self.vlcMediaPlayer.audioTracks()
    }
    
    public func setAudioTrack(audioTrackNumber: Int32) {
        self.vlcMediaPlayer.selectTrack(at: Int(audioTrackNumber), type: .audio)
    }
    
    public var audioTrack: Int32 {
        let audioTracks = self.vlcMediaPlayer.audioTracks
        for (index, track) in audioTracks.enumerated() {
            if track.isSelected {
                return Int32(index)
            }
        }
        return -1
    }
    
    public func setAudioDelay(delay: Int) {
        self.vlcMediaPlayer.currentAudioPlaybackDelay = delay
    }
    
    public var audioDelay: Int {
        self.vlcMediaPlayer.currentAudioPlaybackDelay
    }
    
    public func addAudioTrack(uri: String, isSelected: Bool) {
        // TODO: check for file type
        guard let url = URL(string: uri)
        else {
            return
        }
        self.vlcMediaPlayer.addPlaybackSlave(
            url,
            type: VLCMediaPlaybackSlaveType.audio,
            enforce: isSelected
        )
    }
    
    public var videoTracksCount: Int32 {
        Int32(self.vlcMediaPlayer.videoTracks.count)
    }
    
    public var videoTracks: [Int: String] {
        self.vlcMediaPlayer.videoTracks()
    }
    
    public func setVideoTrack(videoTrackNumber: Int32) {
        self.vlcMediaPlayer.selectTrack(at: Int(videoTrackNumber), type: .video)
    }
    
    public var videoTrack: Int32 {
        let videoTracks = self.vlcMediaPlayer.videoTracks
        for (index, track) in videoTracks.enumerated() {
            if track.isSelected {
                return Int32(index)
            }
        }
        return -1
    }
    
    public func setVideoScale(scale: Float) {
        self.vlcMediaPlayer.scaleFactor = scale
    }
    
    public var videoScale: Float {
        self.vlcMediaPlayer.scaleFactor
    }
    
    public func setVideoAspectRatio(aspectRatio: String) {
        self.vlcMediaPlayer.videoAspectRatio = aspectRatio
    }
    
    public var videoAspectRatio: String {
        return self.vlcMediaPlayer.videoAspectRatio ?? "1"
    }
    
    public var availableRendererServices: [String] {
        self.vlcMediaPlayer.rendererServices()
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
    
    public var rendererDevices: [String: String] {
        var rendererDevices: [String: String] = [:]
        let rendererItems = self.rendererEventChannelHandler.renderItems
        for (_, item) in rendererItems.enumerated() {
            rendererDevices[item.name] = item.name
        }
        return rendererDevices
    }
    
    public func cast(rendererDevice: String) {
        if self.vlcMediaPlayer.isPlaying {
            self.vlcMediaPlayer.pause()
        }
        let rendererItems = self.rendererEventChannelHandler.renderItems
        let rendererItem = rendererItems.first {
            $0.name.contains(rendererDevice)
        }
        self.vlcMediaPlayer.setRendererItem(rendererItem)
        self.vlcMediaPlayer.play()
    }
    
    public func startRecording(saveDirectory: String) -> Bool {
        self.vlcMediaPlayer.startRecording(atPath: saveDirectory)
        return true // VLCKit v4: startRecording returns Void, so we return true to indicate success
    }
    
    public func stopRecording() -> Bool {
        self.vlcMediaPlayer.stopRecording()
        return true // VLCKit v4: stopRecording returns Void, so we return true to indicate success
    }
    
    public func dispose() {
        self.mediaEventChannel.setStreamHandler(nil)
        self.rendererEventChannel.setStreamHandler(nil)
        self.rendererdiscoverers.removeAll()
        self.rendererEventChannelHandler.renderItems.removeAll()
        self.vlcMediaPlayer.stop()
    }
    
    func setMediaPlayerUrl(uri: String, isAssetUrl: Bool, autoPlay: Bool, hwAcc: Int, options: [String]) {
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
        rendererEventSink([
            "event": "attached",
            "id": item.name,
            "name": item.name,
        ])
    }
    
    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        if let index = renderItems.firstIndex(of: item) {
            self.renderItems.remove(at: index)
        }
        
        guard let rendererEventSink = self.rendererEventSink else { return }
        rendererEventSink([
            "event": "detached",
            "id": item.name,
            "name": item.name,
        ])
    }
}

class VLCPlayerEventStreamHandler: NSObject, FlutterStreamHandler, VLCMediaPlayerDelegate, VLCMediaDelegate {
    private var mediaEventSink: FlutterEventSink?
    
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
    
    @objc func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        let player = aNotification.object as? VLCMediaPlayer
        let media = player?.media
        let height = player?.videoSize.height ?? 0
        let width = player?.videoSize.width ?? 0
        let audioTracksCount = player?.audioTracks.count ?? 0
        let activeAudioTrack = self.getSelectedTrackIndex(tracks: player?.audioTracks)
        let spuTracksCount = player?.textTracks.count ?? 0
        let activeSpuTrack = self.getSelectedTrackIndex(tracks: player?.textTracks)
        let duration = media?.length.value ?? 0
        let speed = player?.rate ?? 1
        let position = player?.time.value?.intValue ?? 0
        let buffering = 100.0
        let isPlaying = player?.isPlaying ?? false
                
        switch player?.state {
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
            // VLCKit v4: Use .stopping instead of .ended
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
            /* mediaEventSink(
             FlutterError(
             code: "500",
             message: "Player State got an error",
             details: nil)
             ) */
            mediaEventSink([
                "event": "error",
            ])
            
        default:
            break
        }
    }
    
    func mediaPlayerStartedRecording(_ player: VLCMediaPlayer) {
        guard let mediaEventSink = self.mediaEventSink else { return }
                
        mediaEventSink([
            "event": "recording",
            "isRecording": true,
            "recordPath": "",
        ])
    }
    
    func mediaPlayer(_ player: VLCMediaPlayer, recordingStoppedAt url: URL?) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        mediaEventSink([
            "event": "recording",
            "isRecording": false,
            "recordPath": url?.path ?? "",
        ])
    }
    
    @objc func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        let player = aNotification.object as? VLCMediaPlayer
        //
        let height = player?.videoSize.height ?? 0
        let width = player?.videoSize.width ?? 0
        let speed = player?.rate ?? 1
        let duration = player?.media?.length.value ?? 0
        let audioTracksCount = player?.audioTracks.count ?? 0
        let activeAudioTrack = self.getSelectedTrackIndex(tracks: player?.audioTracks)
        let spuTracksCount = player?.textTracks.count ?? 0
        let activeSpuTrack = self.getSelectedTrackIndex(tracks: player?.textTracks)
        let buffering = 100.0
        let isPlaying = player?.isPlaying ?? false
        //
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
