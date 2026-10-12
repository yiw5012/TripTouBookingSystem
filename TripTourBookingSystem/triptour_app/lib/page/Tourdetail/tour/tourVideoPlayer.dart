import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TourVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const TourVideoPlayer({super.key, required this.videoUrl});

  @override
  State<TourVideoPlayer> createState() => _TourVideoPlayerState();
}

class _TourVideoPlayerState extends State<TourVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          // กำลังโหลดวิดีโอ
          if (snapshot.connectionState != ConnectionState.done &&
              !snapshot.hasError) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          // โหลดไม่สำเร็จ
          if (snapshot.hasError || !_controller.value.isInitialized) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off, color: Colors.white, size: 42),
                  SizedBox(height: 8),
                  Text(
                    'ไม่สามารถโหลดวิดีโอได้',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          final double ratio = _controller.value.aspectRatio > 0
              ? _controller.value.aspectRatio
              : 16 / 9;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ตัววิดีโอ
              Center(
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: VideoPlayer(_controller),
                ),
              ),

              // ปุ่มเล่นและหยุด
              Center(
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 58,
                        color: Colors.white,
                        onPressed: _togglePlayback,
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // แถบเลื่อนตำแหน่งวิดีโอ
              Positioned(
                left: 8,
                right: 8,
                bottom: 6,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.orange,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
