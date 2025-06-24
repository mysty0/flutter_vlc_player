cmake_minimum_required(VERSION 3.22.1)

project("fluttervlcplayer_thumbnail")

# Add the JNI thumbnail library
add_library(fluttervlcplayer_thumbnail
            SHARED
            thumbnail_jni.c)

# Find required libraries
find_library(log-lib log)
find_library(android-lib android)

# Link with required Android libraries
# Note: LibVLC is provided by the AAR dependency and loaded dynamically at runtime
target_link_libraries(fluttervlcplayer_thumbnail
                     ${log-lib}
                     ${android-lib})

# Add compile definitions
target_compile_definitions(fluttervlcplayer_thumbnail PRIVATE
    -DVLC_THUMBNAIL_ENABLED=1) 