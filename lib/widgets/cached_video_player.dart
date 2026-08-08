import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// Custom GradientTransform to stretch the radial gradient horizontally, 
// creating a horizontal egg/elliptical shape to fit wide creature videos.
class HorizontalEggTransform extends GradientTransform {
  final double scaleX;

  const HorizontalEggTransform(this.scaleX);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double centerX = bounds.left + bounds.width / 2;
    final double centerY = bounds.top + bounds.height / 2;
    
    final translation = Matrix4.translationValues(centerX, centerY, 0.0);
    final scale = Matrix4.diagonal3Values(scaleX, 1.0, 1.0);
    final translationInv = Matrix4.translationValues(-centerX, -centerY, 0.0);
    
    return translation * scale * translationInv;
  }
}

class CachedCreatureVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final Widget placeholder;
  final bool useTightMask; // Use tight mask for highly scaled widgets (like homepage)
  final bool disableMask;
  final BoxFit fit;

  const CachedCreatureVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.placeholder,
    this.useTightMask = false,
    this.disableMask = false,
    this.fit = BoxFit.contain,
  });

  @override
  State<CachedCreatureVideoPlayer> createState() => _CachedCreatureVideoPlayerState();
}

class _CachedCreatureVideoPlayerState extends State<CachedCreatureVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // 1. Fetch file from cache manager with a cache-buster query parameter to force refresh updated files
      final cacheBusterUrl = widget.videoUrl.contains('?')
          ? '${widget.videoUrl}&cb=1.0.4_v1'
          : '${widget.videoUrl}?cb=1.0.4_v1';
      final fileInfo = await DefaultCacheManager().getSingleFile(cacheBusterUrl);
      
      if (!mounted) return;
      
      // 2. Initialize controller from local cached file
      final controller = VideoPlayerController.file(fileInfo);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0); // Mute sound in the list
      await controller.play();
      
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || !_isInitialized || _controller == null) {
      return widget.placeholder;
    }

    if (widget.disableMask) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }

    // Determine stops and stretch factor based on widget scaling mode
    final stops = widget.useTightMask ? const [0.30, 0.58] : const [0.52, 0.90];
    final eggScale = widget.useTightMask ? 1.78 : 1.25;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Soft radial background glow (blurry glow behind the video)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.12),
                    const Color(0xFF00F0FF).withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  radius: 0.5,
                ),
              ),
            ),
          ),
          
          // 2. The video player with an elliptical (horizontal egg) radial mask
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: const [Colors.black, Colors.transparent],
                  stops: stops,
                  transform: HorizontalEggTransform(eggScale),
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
