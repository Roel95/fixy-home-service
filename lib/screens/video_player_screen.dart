import 'package:chewie/chewie.dart';
import 'package:fixy_home_service/models/video_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Dispose any previous controllers before creating new ones
      final previousChewie = _chewieController;
      final previousVideo = _videoController;
      _chewieController = null;
      _videoController = null;

      previousChewie?.dispose();
      if (previousVideo != null) {
        await previousVideo.pause();
        await previousVideo.dispose();
      }

      final uri = Uri.tryParse(widget.video.videoUrl);
      if (uri == null || uri.scheme.isEmpty) {
        throw Exception('URL de video no válida');
      }

      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      await controller.setLooping(true);

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        showOptions: false,
        placeholder: widget.video.thumbnailUrl.isNotEmpty
            ? Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Image.network(
                  widget.video.thumbnailUrl,
                  fit: BoxFit.cover,
                ),
              )
            : const ColoredBox(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF667EEA),
          handleColor: const Color(0xFF667EEA),
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          bufferedColor: Colors.white.withValues(alpha: 0.4),
        ),
        errorBuilder: (context, message) => _buildError(message),
      );

      if (!mounted) {
        controller.dispose();
        chewieController.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _chewieController = chewieController;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No pudimos reproducir este video. Intenta nuevamente.';
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.video.videoUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildError(String? message) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            message ?? _errorMessage ?? 'No pudimos reproducir este video.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir en nueva pestaña'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _videoController?.value.aspectRatio ?? (9 / 16);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.video.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    tooltip: 'Abrir en nueva pestaña',
                    onPressed: _openExternally,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF667EEA)),
                          )
                        : (_errorMessage != null || _chewieController == null)
                            ? _buildError(_errorMessage)
                            : Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 700),
                                  child: AspectRatio(
                                    aspectRatio: aspectRatio,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Chewie(
                                          controller: _chewieController!),
                                    ),
                                  ),
                                ),
                              ),
                  ),
                  if (!_isLoading && _errorMessage == null)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.touch_app,
                                    size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Controles disponibles en pantalla',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black,
                border:
                    Border(top: BorderSide(color: Colors.white24, width: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.video.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.video.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage == null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openExternally,
                        icon:
                            const Icon(Icons.open_in_new, color: Colors.white),
                        label: const Text(
                          'Abrir en nueva pestaña',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _initializePlayer,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
