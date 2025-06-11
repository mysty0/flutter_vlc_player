import Flutter
import Foundation
import VLCKit

public class VLCViewBuilder: NSObject, VlcPlayerApi {
    var players = [Int: VLCViewController]()
    private var registrar: FlutterPluginRegistrar
    private var messenger: FlutterBinaryMessenger
    private var options: [String]
    
    init(registrar: FlutterPluginRegistrar) {
        print("🔧 [VLC Builder] Initializing VLCViewBuilder...")
        
        self.registrar = registrar
        messenger = registrar.messenger()
        options = []
        
        print("🔧 [VLC Builder] Registrar: \(registrar)")
        print("🔧 [VLC Builder] Messenger: \(messenger)")
        
        super.init()
        
        print("🔧 [VLC Builder] Setting up VlcPlayerApi with messenger...")
        VlcPlayerApiSetup.setUp(binaryMessenger: messenger, api: self)
        print("✅ [VLC Builder] Successfully set up VlcPlayerApi")
        
        print("🔧 [VLC Builder] VLCViewBuilder initialization completed")
    }
    

    
    public func build(frame: CGRect, viewId: Int64) -> VLCViewController {
        print("🔧 [VLC Builder] Building VLCViewController for viewId: \(viewId)")
        print("🔧 [VLC Builder] Frame: \(frame)")
        
        let vlcViewController = VLCViewController(frame: frame, viewId: viewId, messenger: messenger)
        print("✅ [VLC Builder] Successfully created VLCViewController")
        
        players[viewId.int] = vlcViewController
        print("🔧 [VLC Builder] Stored player with viewId: \(viewId)")
        print("🔧 [VLC Builder] Total players: \(players.count)")
        
        return vlcViewController
    }
    
    func getPlayer(id: Int64) throws -> VLCViewController {
        print("🔧 [VLC API] getPlayer() called with ID: \(id)")
        print("🔧 [VLC API] Available player IDs: \(Array(players.keys))")
        
        guard let player = players[id.int] else {
            print("❌ [VLC API] Player with id \(id) not found in players dictionary")
            throw PigeonError(code: "player_not_found", message: "Player with id \(id) not found", details: nil)
        }
        
        print("✅ [VLC API] Found player for ID: \(id)")
        return player
    }
    
    public func initialize() throws {
        print("🔧 [VLC API] initialize() called")
        
        // Check VLCKit availability
        let vlcLibrary = VLCLibrary.shared()
        print("🔧 [VLC API] VLCKit library: \(vlcLibrary)")
        print("🔧 [VLC API] VLCKit version: \(vlcLibrary.version)")
        
        print("✅ [VLC API] initialize() completed successfully")
    }
    
    func create(msg: CreateMessage) throws {
        print("🔧 [VLC API] create() called with playerId: \(msg.playerId), uri: \(msg.uri)")
        print("🔧 [VLC API] Available players: \(Array(players.keys))")
        
        let player = try getPlayer(id: msg.playerId)
        print("🔧 [VLC API] Found player for ID: \(msg.playerId)")
        
        var isAssetUrl = false
        var mediaUrl = ""
        
        if DataSourceType(rawValue: msg.type.int) == DataSourceType.ASSET {
            var assetPath: String
            if let packageName = msg.packageName {
                assetPath = registrar.lookupKey(forAsset: msg.uri, fromPackage: packageName)
                print("🔧 [VLC API] Asset path with package \(packageName): \(assetPath)")
            } else {
                assetPath = registrar.lookupKey(forAsset: msg.uri)
                print("🔧 [VLC API] Asset path: \(assetPath)")
            }
            mediaUrl = assetPath
            isAssetUrl = true
        } else {
            mediaUrl = msg.uri
            isAssetUrl = false
            print("🔧 [VLC API] Using direct URL: \(mediaUrl)")
        }
        
        options = msg.options
        print("🔧 [VLC API] Options: \(options)")
        
        player.setMediaPlayerUrl(
            uri: mediaUrl,
            isAssetUrl: isAssetUrl,
            autoPlay: msg.autoPlay,
            hwAcc: msg.hwAcc?.int ?? HWAccellerationType.HW_ACCELERATION_AUTOMATIC.rawValue,
            options: options
        )
        print("✅ [VLC API] Successfully set media player URL")
    }
    
    func dispose(playerId: Int64) throws {
        print("🔧 [VLC API] dispose() called with playerId: \(playerId)")
        let player = try getPlayer(id: playerId)
        
        player.dispose()
        players.removeValue(forKey: playerId.int)
        print("✅ [VLC API] Successfully disposed player: \(playerId)")
    }
    
    func setStreamUrl(msg: SetMediaMessage) throws {
        let player = try getPlayer(id: msg.playerId)
        
        var isAssetUrl = false
        var mediaUrl = ""
        
        if DataSourceType(rawValue: msg.type.int) == DataSourceType.ASSET {
            var assetPath: String
            if let packageName = msg.packageName {
                assetPath = registrar.lookupKey(forAsset: msg.uri, fromPackage: packageName)
            } else {
                assetPath = registrar.lookupKey(forAsset: msg.uri)
            }
            mediaUrl = assetPath
            isAssetUrl = true
        } else {
            mediaUrl = msg.uri
            isAssetUrl = false
        }
        
        player.setMediaPlayerUrl(
            uri: mediaUrl,
            isAssetUrl: isAssetUrl,
            autoPlay: msg.autoPlay,
            hwAcc: msg.hwAcc?.int ?? HWAccellerationType.HW_ACCELERATION_AUTOMATIC.rawValue,
            options: options
        )
    }
    
    func play(playerId: Int64) throws {
        print("🔧 [VLC API] play() called with playerId: \(playerId)")
        let player = try getPlayer(id: playerId)
        
        player.play()
        print("✅ [VLC API] Successfully called play()")
    }
    
    func pause(playerId: Int64) throws {
        print("🔧 [VLC API] pause() called with playerId: \(playerId)")
        let player = try getPlayer(id: playerId)
        
        player.pause()
        print("✅ [VLC API] Successfully called pause()")
    }
    
    func stop(playerId: Int64) throws {
        print("🔧 [VLC API] stop() called with playerId: \(playerId)")
        let player = try getPlayer(id: playerId)
        
        player.stop()
        print("✅ [VLC API] Successfully called stop()")
    }
    
    func isPlaying(playerId: Int64) throws -> Bool {
        return try getPlayer(id: playerId).isPlaying
    }
    
    func isSeekable(playerId: Int64) throws -> Bool {
        return try getPlayer(id: playerId).isSeekable
    }
    
    func setLooping(playerId: Int64, isLooping: Bool) throws {
        let player = try getPlayer(id: playerId)

        player.setLooping(isLooping: isLooping)
    }
    
    func seekTo(playerId: Int64, position: Int64) throws {
        let player = try getPlayer(id: playerId)

        player.seek(position: position)
    }
    
    func position(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).position.int64
    }
    
    func duration(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).duration.int64
    }
    
    func setVolume(playerId: Int64, volume: Int64) throws {
        let player = try getPlayer(id: playerId)
        player.setVolume(volume: volume)
    }
    
    func getVolume(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).volume.int64
    }
    
    func setPlaybackSpeed(playerId: Int64, speed: Double) throws {
        let player = try getPlayer(id: playerId)

        player.setPlaybackSpeed(speed: speed.float)
    }
    
    func getPlaybackSpeed(playerId: Int64) throws -> Double {
        return try getPlayer(id: playerId).playbackSpeed.double
    }
    
    func takeSnapshot(playerId: Int64) throws -> String? {
        return try getPlayer(id: playerId).takeSnapshot()
    }
    
    // MARK: - Subtitle Tracks
    
    func getSpuTracksCount(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).spuTracksCount.int64
    }
    
    func getSpuTracks(playerId: Int64) throws -> [Int64: String] {
        return try getPlayer(id: playerId).spuTracks.int64Dictionary
    }
    
    func setSpuTrack(playerId: Int64, spuTrackNumber: Int64) throws {
        let player = try getPlayer(id: playerId)

        player.setSpuTrack(spuTrackNumber: spuTrackNumber.int)
    }
    
    func getSpuTrack(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).spuTrack.int64
    }
    
    func setSpuDelay(playerId: Int64, delay: Int64) throws {
        let player = try getPlayer(id: playerId)

        player.setSpuDelay(delay: delay.int)
    }
    
    func getSpuDelay(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).spuDelay.int64
    }
    
    func addSubtitleTrack(msg: AddSubtitleMessage) throws {
        let player = try getPlayer(id: msg.playerId)
        
        player.addSubtitleTrack(uri: msg.uri, isSelected: msg.isSelected)
    }
    
    // MARK: - Audio Tracks
    
    func getAudioTracksCount(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).audioTracksCount.int64
    }
    
    func getAudioTracks(playerId: Int64) throws -> [Int64: String] {
        return try getPlayer(id: playerId).audioTracks.int64Dictionary
    }
    
    func setAudioTrack(playerId: Int64, audioTrackNumber: Int64) throws {
        let player = try getPlayer(id: playerId)
        
        player.setAudioTrack(audioTrackNumber: audioTrackNumber.int32)
    }
    
    func getAudioTrack(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).audioTrack.int64
    }
    
    func getAudioDelay(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).audioDelay.int64
    }
    
    func setAudioDelay(playerId: Int64, delay: Int64) throws {
        let player = try getPlayer(id: playerId)
        
        player.setAudioDelay(delay: delay.int)
    }
    
    func addAudioTrack(msg: AddAudioMessage) throws {
        let player = try getPlayer(id: msg.playerId)
        
        player.addAudioTrack(uri: msg.uri, isSelected: msg.isSelected)
    }
    
    // MARK: - Video Tracks

    func getVideoTracksCount(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).videoTracksCount.int64
    }
    
    func getVideoTracks(playerId: Int64) throws -> [Int64: String] {
        return try getPlayer(id: playerId).videoTracks.int64Dictionary
    }
    
    func setVideoTrack(playerId: Int64, videoTrackNumber: Int64) throws {
        let player = try getPlayer(id: playerId)
        
        player.setVideoTrack(videoTrackNumber: videoTrackNumber.int32)
    }
    
    func getVideoTrack(playerId: Int64) throws -> Int64 {
        return try getPlayer(id: playerId).videoTrack.int64
    }
    
    // MARK: - Video properties
    
    func setVideoScale(playerId: Int64, scale: Double) throws {
        let player = try getPlayer(id: playerId)
        
        player.setVideoScale(scale: scale.float)
    }
    
    func getVideoScale(playerId: Int64) throws -> Double {
        return try getPlayer(id: playerId).videoScale.double
    }
    
    func setVideoAspectRatio(playerId: Int64, aspectRatio: String) throws {
        let player = try getPlayer(id: playerId)
                    
        player.setVideoAspectRatio(aspectRatio: aspectRatio)
    }
    
    func getVideoAspectRatio(playerId: Int64) throws -> String {
        return try getPlayer(id: playerId).videoAspectRatio
    }
    
    func getAvailableRendererServices(playerId: Int64) throws -> [String] {
        return try getPlayer(id: playerId).availableRendererServices
    }
    
    // MARK: - Cast
    
    func startRendererScanning(playerId: Int64, rendererService: String) throws {
        let player = try getPlayer(id: playerId)
        
        player.startRendererScanning()
    }
    
    func stopRendererScanning(playerId: Int64) throws {
        let player = try getPlayer(id: playerId)
        
        player.stopRendererScanning()
    }
    
    func getRendererDevices(playerId: Int64) throws -> [String: String] {
        return try getPlayer(id: playerId).rendererDevices
    }
    
    func castToRenderer(playerId: Int64, rendererId: String) throws {
        let player = try getPlayer(id: playerId)
        
        player.cast(rendererDevice: rendererId)
    }
    
    // MARK: - Recording
    
    func startRecording(playerId: Int64, saveDirectory: String) throws -> Bool {
        let player = try getPlayer(id: playerId)
        
        return player.startRecording(saveDirectory: saveDirectory)
    }
    
    func stopRecording(playerId: Int64) throws -> Bool {
        let player = try getPlayer(id: playerId)
        
        return player.stopRecording()
    }
}

extension Int {
    var int64: Int64 {
        Int64(self)
    }
    
    var int32: Int32 {
        Int32(self)
    }
}

extension Int64 {
    var int: Int {
        Int(self)
    }
    
    var int32: Int32 {
        Int32(truncatingIfNeeded: self)
    }
}

extension Int32 {
    var int: Int {
        Int(self)
    }
    
    var int64: Int64 {
        Int64(truncatingIfNeeded: self)
    }
}

extension Double {
    var float: Float {
        Float(self)
    }
}

extension Float {
    var double: Double {
        Double(self)
    }
}

extension Dictionary where Key == Int {
    var int64Dictionary: [Int64: Value] {
        [Int64: Value](uniqueKeysWithValues:
            map { (Int64($0.key), $0.value) }
        )
    }
}
