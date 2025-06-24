#include <jni.h>
#include <android/log.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <time.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>
#include <errno.h>
#include <inttypes.h>

#define LOG_TAG "VLCThumbnail"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// Forward declarations for VLC types (to avoid including vlc/vlc.h)
typedef struct libvlc_instance_t libvlc_instance_t;
typedef struct libvlc_media_t libvlc_media_t;
typedef struct libvlc_media_player_t libvlc_media_player_t;

// Function pointers for VLC functions
static void* vlc_handle = NULL;
static libvlc_instance_t* (*vlc_new)(int argc, const char* const* argv) = NULL;
static void (*vlc_release)(libvlc_instance_t* instance) = NULL;
static libvlc_media_t* (*vlc_media_new_location)(libvlc_instance_t* instance, const char* mrl) = NULL;
static libvlc_media_t* (*vlc_media_new_path)(libvlc_instance_t* instance, const char* path) = NULL;
static void (*vlc_media_release)(libvlc_media_t* media) = NULL;
static libvlc_media_player_t* (*vlc_media_player_new_from_media)(libvlc_media_t* media) = NULL;
static void (*vlc_media_player_release)(libvlc_media_player_t* player) = NULL;
static void (*vlc_video_set_callbacks)(libvlc_media_player_t* mp, 
                                       void* (*lock)(void* opaque, void** planes),
                                       void (*unlock)(void* opaque, void* picture, void* const* planes),
                                       void (*display)(void* opaque, void* picture),
                                       void* opaque) = NULL;
static void (*vlc_video_set_format)(libvlc_media_player_t* mp, const char* chroma, 
                                    unsigned width, unsigned height, unsigned pitch) = NULL;
static int (*vlc_media_player_play)(libvlc_media_player_t* player) = NULL;
static void (*vlc_media_player_stop)(libvlc_media_player_t* player) = NULL;
static void (*vlc_media_player_set_position)(libvlc_media_player_t* player, float position) = NULL;
static int (*vlc_media_player_is_playing)(libvlc_media_player_t* player) = NULL;
static int64_t (*vlc_media_player_get_length)(libvlc_media_player_t* player) = NULL;
static void (*vlc_media_player_set_time)(libvlc_media_player_t* player, int64_t time) = NULL;

// Android-specific VLC functions
static void (*vlc_set_app_id)(const char* id, const char* version, const char* icon) = NULL;
static int (*vlc_add_intf)(libvlc_instance_t* p_instance, const char* name) = NULL;

// JVM globals for VLC Android integration
static JavaVM* g_jvm = NULL;
static bool vlc_android_initialized = false;

// Dynamic loading of LibVLC
static int load_vlc_library() {
    if (vlc_handle != NULL) {
        return 1; // Already loaded
    }
    
    LOGI("Loading LibVLC library dynamically...");
    
    // Try to load the LibVLC library
    vlc_handle = dlopen("libvlc.so", RTLD_NOW);
    if (vlc_handle == NULL) {
        LOGE("Failed to load libvlc.so: %s", dlerror());
        return 0;
    }
    
    // Load function pointers
    vlc_new = (libvlc_instance_t* (*)(int, const char* const*))dlsym(vlc_handle, "libvlc_new");
    vlc_release = (void (*)(libvlc_instance_t*))dlsym(vlc_handle, "libvlc_release");
    vlc_media_new_location = (libvlc_media_t* (*)(libvlc_instance_t*, const char*))dlsym(vlc_handle, "libvlc_media_new_location");
    vlc_media_new_path = (libvlc_media_t* (*)(libvlc_instance_t*, const char*))dlsym(vlc_handle, "libvlc_media_new_path");
    vlc_media_release = (void (*)(libvlc_media_t*))dlsym(vlc_handle, "libvlc_media_release");
    vlc_media_player_new_from_media = (libvlc_media_player_t* (*)(libvlc_media_t*))dlsym(vlc_handle, "libvlc_media_player_new_from_media");
    vlc_media_player_release = (void (*)(libvlc_media_player_t*))dlsym(vlc_handle, "libvlc_media_player_release");
    vlc_video_set_callbacks = (void (*)(libvlc_media_player_t*, void* (*)(void*, void**), void (*)(void*, void*, void* const*), void (*)(void*, void*), void*))dlsym(vlc_handle, "libvlc_video_set_callbacks");
    vlc_video_set_format = (void (*)(libvlc_media_player_t*, const char*, unsigned, unsigned, unsigned))dlsym(vlc_handle, "libvlc_video_set_format");
    vlc_media_player_play = (int (*)(libvlc_media_player_t*))dlsym(vlc_handle, "libvlc_media_player_play");
    vlc_media_player_stop = (void (*)(libvlc_media_player_t*))dlsym(vlc_handle, "libvlc_media_player_stop");
    vlc_media_player_set_position = (void (*)(libvlc_media_player_t*, float))dlsym(vlc_handle, "libvlc_media_player_set_position");
    vlc_media_player_is_playing = (int (*)(libvlc_media_player_t*))dlsym(vlc_handle, "libvlc_media_player_is_playing");
    vlc_media_player_get_length = (int64_t (*)(libvlc_media_player_t*))dlsym(vlc_handle, "libvlc_media_player_get_length");
    vlc_media_player_set_time = (void (*)(libvlc_media_player_t*, int64_t))dlsym(vlc_handle, "libvlc_media_player_set_time");
    
    // Load Android-specific functions (optional, as they might not be available in all VLC builds)
    vlc_set_app_id = (void (*)(const char*, const char*, const char*))dlsym(vlc_handle, "libvlc_set_app_id");
    vlc_add_intf = (int (*)(libvlc_instance_t*, const char*))dlsym(vlc_handle, "libvlc_add_intf");
    
    // Check if all essential functions were loaded
    if (!vlc_new || !vlc_release || !vlc_media_new_location || !vlc_media_new_path || !vlc_media_release ||
        !vlc_media_player_new_from_media || !vlc_media_player_release || 
        !vlc_video_set_callbacks || !vlc_video_set_format || 
        !vlc_media_player_play || !vlc_media_player_stop || !vlc_media_player_set_position ||
        !vlc_media_player_is_playing || !vlc_media_player_get_length || !vlc_media_player_set_time) {
        LOGE("Failed to load VLC function symbols");
        dlclose(vlc_handle);
        vlc_handle = NULL;
        return 0;
    }
    
    // Note: Android-specific functions are optional
    if (vlc_set_app_id) {
        LOGI("VLC Android-specific functions available");
    } else {
        LOGI("VLC Android-specific functions not available (might be older VLC version)");
    }
    
    LOGI("LibVLC library loaded successfully");
    return 1;
}

// Cleanup VLC library
static void unload_vlc_library() {
    if (vlc_handle != NULL) {
        dlclose(vlc_handle);
        vlc_handle = NULL;
    }
}

// Thumbnail generation context
typedef struct {
    pthread_mutex_t lock;
    pthread_cond_t wait;
    bool completed;
    bool success;
    void* picture_data;
    size_t picture_size;
    int width;
    int height;
} thumbnail_context_t;

// Video callback structure for capturing frames
typedef struct {
    thumbnail_context_t* ctx;
    int target_width;
    int target_height;
    bool frame_captured;
} video_context_t;

// Lock callback for video output
static void* video_lock(void* opaque, void** planes) {
    video_context_t* vctx = (video_context_t*)opaque;
    thumbnail_context_t* ctx = vctx->ctx;
    
    if (ctx->picture_data == NULL) {
        // Allocate buffer for RGBA data
        size_t buffer_size = vctx->target_width * vctx->target_height * 4; // RGBA
        ctx->picture_data = malloc(buffer_size);
        ctx->picture_size = buffer_size;
        ctx->width = vctx->target_width;
        ctx->height = vctx->target_height;
        LOGD("Allocated video buffer: %dx%d, %zu bytes", ctx->width, ctx->height, ctx->picture_size);
    }
    
    planes[0] = ctx->picture_data;
    return NULL;
}

// Display callback for video output
static void video_display(void* opaque, void* picture) {
    video_context_t* vctx = (video_context_t*)opaque;
    thumbnail_context_t* ctx = vctx->ctx;
    
    if (!vctx->frame_captured && ctx->picture_data != NULL) {
        LOGD("Frame captured successfully");
        vctx->frame_captured = true;
        
        pthread_mutex_lock(&ctx->lock);
        ctx->success = true;
        ctx->completed = true;
        pthread_cond_signal(&ctx->wait);
        pthread_mutex_unlock(&ctx->lock);
    }
}

// Unlock callback (not used)
static void video_unlock(void* opaque, void* picture, void* const* planes) {
    // Nothing to do
}

// Convert RGBA to JPEG using Android's Bitmap API
static jbyteArray rgba_to_jpeg(JNIEnv* env, void* rgba_data, int width, int height) {
    LOGD("Converting RGBA to JPEG: %dx%d", width, height);
    
    // Create int array for bitmap pixels
    jintArray pixelArray = (*env)->NewIntArray(env, width * height);
    if (pixelArray == NULL) {
        LOGE("Failed to create pixel array");
        return NULL;
    }
    
    // Convert RGBA to ARGB int array
    jint* pixels = (*env)->GetIntArrayElements(env, pixelArray, NULL);
    unsigned char* rgba = (unsigned char*)rgba_data;
    
    for (int i = 0; i < width * height; i++) {
        unsigned char r = rgba[i * 4 + 0];
        unsigned char g = rgba[i * 4 + 1]; 
        unsigned char b = rgba[i * 4 + 2];
        unsigned char a = rgba[i * 4 + 3];
        
        // Convert to ARGB format
        pixels[i] = (a << 24) | (r << 16) | (g << 8) | b;
    }
    
    (*env)->ReleaseIntArrayElements(env, pixelArray, pixels, 0);
    
    // Get Bitmap class and create bitmap
    jclass bitmapClass = (*env)->FindClass(env, "android/graphics/Bitmap");
    jclass bitmapConfigClass = (*env)->FindClass(env, "android/graphics/Bitmap$Config");
    
    if (bitmapClass == NULL || bitmapConfigClass == NULL) {
        LOGE("Failed to find Bitmap classes");
        (*env)->DeleteLocalRef(env, pixelArray);
        return NULL;
    }
    
    // Get ARGB_8888 config
    jfieldID argb8888FieldId = (*env)->GetStaticFieldID(env, bitmapConfigClass, "ARGB_8888", "Landroid/graphics/Bitmap$Config;");
    jobject argb8888Config = (*env)->GetStaticObjectField(env, bitmapConfigClass, argb8888FieldId);
    
    // Create bitmap from pixel array
    jmethodID createBitmapId = (*env)->GetStaticMethodID(env, bitmapClass, "createBitmap", "([IIILandroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;");
    jobject bitmap = (*env)->CallStaticObjectMethod(env, bitmapClass, createBitmapId, pixelArray, width, height, argb8888Config);
    
    (*env)->DeleteLocalRef(env, pixelArray);
    
    if (bitmap == NULL || (*env)->ExceptionCheck(env)) {
        LOGE("Failed to create bitmap");
        if ((*env)->ExceptionCheck(env)) {
            (*env)->ExceptionDescribe(env);
            (*env)->ExceptionClear(env);
        }
        return NULL;
    }
    
    LOGD("Bitmap created successfully");
    
    // Compress to JPEG
    jclass compressFormatClass = (*env)->FindClass(env, "android/graphics/Bitmap$CompressFormat");
    jclass byteArrayOutputStreamClass = (*env)->FindClass(env, "java/io/ByteArrayOutputStream");
    
    jfieldID jpegFieldId = (*env)->GetStaticFieldID(env, compressFormatClass, "JPEG", "Landroid/graphics/Bitmap$CompressFormat;");
    jobject jpegFormat = (*env)->GetStaticObjectField(env, compressFormatClass, jpegFieldId);
    
    jmethodID streamConstructorId = (*env)->GetMethodID(env, byteArrayOutputStreamClass, "<init>", "()V");
    jobject outputStream = (*env)->NewObject(env, byteArrayOutputStreamClass, streamConstructorId);
    
    jmethodID compressId = (*env)->GetMethodID(env, bitmapClass, "compress", "(Landroid/graphics/Bitmap$CompressFormat;ILjava/io/OutputStream;)Z");
    jboolean compressed = (*env)->CallBooleanMethod(env, bitmap, compressId, jpegFormat, 85, outputStream);
    
    if (!compressed || (*env)->ExceptionCheck(env)) {
        LOGE("Failed to compress bitmap");
        if ((*env)->ExceptionCheck(env)) {
            (*env)->ExceptionDescribe(env);
            (*env)->ExceptionClear(env);
        }
        (*env)->DeleteLocalRef(env, bitmap);
        (*env)->DeleteLocalRef(env, outputStream);
        return NULL;
    }
    
    // Get byte array
    jmethodID toByteArrayId = (*env)->GetMethodID(env, byteArrayOutputStreamClass, "toByteArray", "()[B");
    jbyteArray jpegBytes = (jbyteArray)(*env)->CallObjectMethod(env, outputStream, toByteArrayId);
    
    (*env)->DeleteLocalRef(env, bitmap);
    (*env)->DeleteLocalRef(env, outputStream);
    
    if (jpegBytes != NULL) {
        jsize jpegSize = (*env)->GetArrayLength(env, jpegBytes);
        LOGD("JPEG created successfully: %d bytes", jpegSize);
    }
    
    return jpegBytes;
}

/**
 * VLC-based thumbnail generation using LibVLC C API
 * This provides the best codec support including H.265/x265, AV1, VP9, etc.
 */
JNIEXPORT jbyteArray JNICALL
Java_software_solid_fluttervlcplayer_ThumbnailMethodChannelHandler_generateThumbnailJNI(JNIEnv *env, jobject thiz, jstring media_path, jint width, jint height, jfloat position) {
    
    const char *path = (*env)->GetStringUTFChars(env, media_path, NULL);
    if (path == NULL) {
        LOGE("Failed to get media path string");
        return NULL;
    }
    
    // Load VLC library dynamically
    if (!load_vlc_library()) {
        LOGE("Failed to load VLC library");
        (*env)->ReleaseStringUTFChars(env, media_path, path);
        return NULL;
    }
    
    LOGI("=== VLC Native thumbnail generation started ===");
    LOGI("Media path: %s", path);
    LOGI("Requested size: %dx%d", width, height);
    LOGI("Position: %.2f", position);
    
    jbyteArray result = NULL;
    libvlc_instance_t* vlc = NULL;
    libvlc_media_t* media = NULL;
    libvlc_media_player_t* player = NULL;
    
    // Initialize context
    thumbnail_context_t ctx;
    video_context_t vctx;
    
    pthread_mutex_init(&ctx.lock, NULL);
    pthread_cond_init(&ctx.wait, NULL);
    ctx.completed = false;
    ctx.success = false;
    ctx.picture_data = NULL;
    ctx.picture_size = 0;
    ctx.width = 0;
    ctx.height = 0;
    
    vctx.ctx = &ctx;
    vctx.target_width = width > 0 ? width : 320;
    vctx.target_height = height > 0 ? height : 240;
    vctx.frame_captured = false;
    
    // Create VLC instance with minimal config for thumbnailing
    const char* vlc_args[] = {
        "--intf", "dummy",
        "--vout", "dummy", 
        "--no-audio",
        "--no-video-title-show",
        "--no-stats", 
        "--no-sub-autodetect-file",
        "--no-snapshot-preview",
        "--no-osd",
        "--quiet"
    };
    
    vlc = vlc_new(sizeof(vlc_args) / sizeof(*vlc_args), vlc_args);
    if (vlc == NULL) {
        LOGE("Failed to create LibVLC instance");
        goto cleanup;
    }
    
    LOGD("LibVLC instance created");
    
    // Create media from path
    media = vlc_media_new_path(vlc, path);
    if (media == NULL) {
        LOGE("Failed to create media from path: %s", path);
        goto cleanup;
    }
    
    LOGD("Media created from path");
    
    // Create media player
    player = vlc_media_player_new_from_media(media);
    if (player == NULL) {
        LOGE("Failed to create media player");
        goto cleanup;
    }
    
    LOGD("Media player created");
    
    // Set video format and callbacks for frame capture
    vlc_video_set_format(player, "RGBA", vctx.target_width, vctx.target_height, vctx.target_width * 4);
    vlc_video_set_callbacks(player, video_lock, video_unlock, video_display, &vctx);
    
    LOGD("Video callbacks set");
    
    // Start playback
    int play_result = vlc_media_player_play(player);
    if (play_result == -1) {
        LOGE("Failed to start playback");
        goto cleanup;
    }
    
    LOGD("Playback started");
    
    // Wait for media to be parsed and playing
    int timeout = 0;
    while (!vlc_media_player_is_playing(player) && timeout < 100) {
        usleep(50000); // 50ms
        timeout++;
    }
    
    if (!vlc_media_player_is_playing(player)) {
        LOGE("Media not playing after timeout");
        goto cleanup;
    }
    
    LOGD("Media is playing");
    
    // Get duration and seek to position
    int64_t duration = vlc_media_player_get_length(player);
    if (duration > 0) {
        int64_t seek_time = (int64_t)(duration * position);
        LOGD("Seeking to %" PRId64 " ms (%.1f%% of %" PRId64 " ms)", seek_time, position * 100, duration);
        
        vlc_media_player_set_time(player, seek_time);
        
        // Wait for seek to complete
        timeout = 0;
        while (timeout < 50) {
            usleep(100000); // 100ms
            timeout++;
        }
    } else {
        LOGD("Duration unknown, seeking to 5 seconds");
        vlc_media_player_set_time(player, 5000);
        usleep(500000); // 500ms
    }
    
    // Wait for frame capture or timeout
    pthread_mutex_lock(&ctx.lock);
    
    struct timespec timeout_spec;
    clock_gettime(CLOCK_REALTIME, &timeout_spec);
    timeout_spec.tv_sec += 10; // 10 second timeout
    
    while (!ctx.completed) {
        int wait_result = pthread_cond_timedwait(&ctx.wait, &ctx.lock, &timeout_spec);
        if (wait_result == ETIMEDOUT) {
            LOGE("Thumbnail generation timed out after 10 seconds");
            break;
        }
    }
    
    pthread_mutex_unlock(&ctx.lock);
    
    // Convert captured frame to JPEG
    if (ctx.success && ctx.picture_data != NULL) {
        LOGI("Frame captured successfully, converting to JPEG");
        result = rgba_to_jpeg(env, ctx.picture_data, ctx.width, ctx.height);
        
        if (result != NULL) {
            jsize resultSize = (*env)->GetArrayLength(env, result);
            LOGI("✅ VLC thumbnail generation successful - %d bytes", resultSize);
        } else {
            LOGE("Failed to convert frame to JPEG");
        }
    } else {
        LOGE("No frame was captured");
    }
    
cleanup:
    // Stop playback
    if (player != NULL) {
        vlc_media_player_stop(player);
        vlc_media_player_release(player);
    }
    
    if (media != NULL) {
        vlc_media_release(media);
    }
    
    if (vlc != NULL) {
        vlc_release(vlc);
    }
    
    // Clean up context
    if (ctx.picture_data != NULL) {
        free(ctx.picture_data);
    }
    
    pthread_cond_destroy(&ctx.wait);
    pthread_mutex_destroy(&ctx.lock);
    
    // Release path string
    (*env)->ReleaseStringUTFChars(env, media_path, path);
    
    LOGI("=== VLC thumbnail generation completed ===");
    return result;
} 