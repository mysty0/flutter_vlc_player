import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

/// Example demonstrating thumbnail generation from video files
class ThumbnailExample extends StatefulWidget {
  const ThumbnailExample({super.key});

  @override
  State<ThumbnailExample> createState() => _ThumbnailExampleState();
}

class _ThumbnailExampleState extends State<ThumbnailExample> {
  Uint8List? _thumbnailData;
  bool _isLoading = false;
  String _status = '';

  // Example video URLs - replace with your own video URLs
  final List<String> _sampleVideos = [
    'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VLC Thumbnail Generator'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VLC Thumbnail Generation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate thumbnails from video files without needing to play them. '
                      'This feature works independently of any video player instance.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Sample videos section
            const Text(
              'Sample Videos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...List.generate(_sampleVideos.length, (index) {
              final url = _sampleVideos[index];
              final fileName = url.split('/').last;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.movie, color: Colors.deepPurple),
                  title: Text(fileName),
                  subtitle: Text(url),
                  trailing: ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _generateThumbnail(url),
                    child: const Text('Generate'),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Custom URL input
            const Text(
              'Custom Video URL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        hintText: 'Enter video URL (http/https/file path)',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _isLoading ? null : _generateThumbnail,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    // Get URL from text field
                                    // For demo, we'll use the first sample video
                                    _generateThumbnail(_sampleVideos.first);
                                  },
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.image),
                            label: Text(_isLoading
                                ? 'Generating...'
                                : 'Generate Thumbnail'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status
            if (_status.isNotEmpty)
              Card(
                color: _status.contains('Error')
                    ? Colors.red[50]
                    : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _status.contains('Error')
                          ? Colors.red[700]
                          : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Thumbnail display
            if (_thumbnailData != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _thumbnailData!,
                    fit: BoxFit.contain,
                    height: 300,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _generateThumbnail(String videoUrl) async {
    if (videoUrl.trim().isEmpty) {
      setState(() {
        _status = 'Error: Please enter a valid video URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Generating thumbnail...';
      _thumbnailData = null;
    });

    try {
      // Generate thumbnail using the new static method
      final thumbnailData = await VlcPlayerController.generateThumbnail(
        dataSource: videoUrl,
        width: 320, // Optional: specify thumbnail width
        height: 180, // Optional: specify thumbnail height
        position: 0.3, // Optional: position in video (30% from start)
      );

      setState(() {
        if (thumbnailData != null) {
          _thumbnailData = thumbnailData;
          _status = 'Thumbnail generated successfully! '
              'Size: ${thumbnailData.length} bytes';
        } else {
          _status = 'Error: Failed to generate thumbnail (null result)';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}

/// Usage example in your app:
/// 
/// ```dart
/// // Generate thumbnail from video file
/// final thumbnailData = await VlcPlayerController.generateThumbnail(
///   dataSource: 'https://example.com/video.mp4',
///   width: 300,        // Optional: desired width
///   height: 200,       // Optional: desired height  
///   position: 0.5,     // Optional: position in video (0.0 to 1.0)
/// );
/// 
/// if (thumbnailData != null) {
///   // Use the thumbnail data (Uint8List) 
///   // Can be displayed with Image.memory(thumbnailData)
///   // Or saved to file, etc.
/// }
/// ``` 