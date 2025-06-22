import 'package:flutter/material.dart';
import 'package:flutter_vlc_player_example/multiple_tab.dart';
import 'package:flutter_vlc_player_example/single_tab.dart';
import 'package:flutter_vlc_player_example/thumbnail_example.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  static const _tabCount = 3;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabCount,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('VLC Player Example'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.play_circle_outline),
                text: 'Single',
              ),
              Tab(
                icon: Icon(Icons.video_library),
                text: 'Multiple',
              ),
              Tab(
                icon: Icon(Icons.image),
                text: 'Thumbnails',
              ),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SingleTab(),
            MultipleTab(),
            ThumbnailExample(),
          ],
        ),
      ),
    );
  }
}
