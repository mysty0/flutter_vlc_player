package software.solid.fluttervlcplayer;

import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;

public class FlutterVlcPlayerPlugin implements FlutterPlugin, ActivityAware {

    private static FlutterVlcPlayerFactory flutterVlcPlayerFactory;
    private FlutterPluginBinding flutterPluginBinding;
    private MethodChannel thumbnailChannel;

    private static final String VIEW_TYPE = "flutter_video_plugin/getVideoView";
    private static final String THUMBNAIL_CHANNEL = "flutter_vlc_player/thumbnail";

    public FlutterVlcPlayerPlugin() {
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        flutterPluginBinding = binding;

        //
        if (flutterVlcPlayerFactory == null) {
            final FlutterInjector injector = FlutterInjector.instance();
            //
            flutterVlcPlayerFactory =
                    new FlutterVlcPlayerFactory(
                            flutterPluginBinding.getBinaryMessenger(),
                            flutterPluginBinding.getTextureRegistry(),
                            injector.flutterLoader()::getLookupKeyForAsset,
                            injector.flutterLoader()::getLookupKeyForAsset
                    );
            flutterPluginBinding
                    .getPlatformViewRegistry()
                    .registerViewFactory(
                            VIEW_TYPE,
                            flutterVlcPlayerFactory
                    );
            //
        }
        
        // Setup thumbnail generation method channel
        thumbnailChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), THUMBNAIL_CHANNEL);
        thumbnailChannel.setMethodCallHandler(new ThumbnailMethodChannelHandler(flutterPluginBinding.getApplicationContext()));
        
        startListening();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        stopListening();
        //
        if (thumbnailChannel != null) {
            thumbnailChannel.setMethodCallHandler(null);
            thumbnailChannel = null;
        }

        flutterPluginBinding = null;
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
    }

    // extra methods

    private static void startListening() {
        if (flutterVlcPlayerFactory != null)
            flutterVlcPlayerFactory.startListening();
    }

    private static void stopListening() {
        if (flutterVlcPlayerFactory != null) {
            flutterVlcPlayerFactory.stopListening();
            flutterVlcPlayerFactory = null;
        }
    }
}
