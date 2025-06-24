import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player_platform_interface/flutter_vlc_player_platform_interface.dart';

class AndroidThumbnailTest extends StatefulWidget {
  const AndroidThumbnailTest({Key? key}) : super(key: key);

  @override
  State<AndroidThumbnailTest> createState() => _AndroidThumbnailTestState();
}

class _AndroidThumbnailTestState extends State<AndroidThumbnailTest> {
  Uint8List? _thumbnailData;
  bool _isGenerating = false;
  String? _error;

  final List<String> _testUrls = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
  ];

  Future<void> _generateThumbnail(String url) async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _thumbnailData = null;
    });

    try {
      print('🎯 Testing Android VLC thumbnail generation for: $url');

      final thumbnailData = await VlcPlayerPlatform.instance.generateThumbnail(
        dataSource: url,
        width: 320,
        height: 240,
        position: 0.3, // 30% through the video
      );

      if (thumbnailData != null && thumbnailData.isNotEmpty) {
        setState(() {
          _thumbnailData = thumbnailData;
          _isGenerating = false;
        });
        print(
            '✅ Android VLC thumbnail generated successfully: ${thumbnailData.length} bytes');
      } else {
        throw Exception('Received empty thumbnail data');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
      print('❌ Android VLC thumbnail generation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Android VLC Thumbnail Test'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Android VLC Thumbnail Generation Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tests the native VLC thumbnail generation on Android using dynamic library loading.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // URL Selection
            const Text(
              'Select a test video:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...(_testUrls.map((url) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed:
                        _isGenerating ? null : () => _generateThumbnail(url),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      url.split('/').last.replaceAll('.mp4', ''),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ))).toList(),

            const SizedBox(height: 20),

            // Status and Results
            if (_isGenerating)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Generating thumbnail with VLC...'),
                    ],
                  ),
                ),
              ),

            if (_error != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            if (_thumbnailData != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Thumbnail Generated Successfully',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Size: ${_thumbnailData!.length} bytes',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _thumbnailData!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
