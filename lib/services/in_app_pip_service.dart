import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Keeps only the player alive after its detail route has been popped.
/// Returning to the detail page opens it afresh at the current position.
class InAppPipService {
  InAppPipService._();

  static OverlayEntry? _entry;
  static PlPlayerController? _player;
  static Map<String, dynamic>? _arguments;

  static bool get isShowing => _entry != null;

  static void show(
    BuildContext context, {
    required PlPlayerController player,
    required Map<String, dynamic> arguments,
  }) {
    close();
    _player = player;
    _arguments = arguments;
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (_) => _MiniPlayer(
        player: player,
        onClose: close,
        onExpand: expand,
      ),
    );
    overlay.insert(_entry!);
  }

  static void expand() {
    final arguments = _arguments;
    final player = _player;
    if (arguments == null || player == null) return;
    arguments['progress'] = player.positionInMilliseconds;
    close();
    Get.toNamed('/videoV', arguments: arguments);
  }

  static void close() {
    final entry = _entry;
    _entry = null;
    entry?.remove();
    entry?.dispose();
    final player = _player;
    final arguments = _arguments;
    _player = null;
    _arguments = null;
    if (player != null) {
      if (arguments?['heroTag'] case final String tag) {
        videoPlayerServiceHandler?.onVideoDetailDispose(tag);
      }
      player.dispose();
    }
  }
}

class _MiniPlayer extends StatefulWidget {
  const _MiniPlayer({
    required this.player,
    required this.onClose,
    required this.onExpand,
  });

  final PlPlayerController player;
  final VoidCallback onClose;
  final VoidCallback onExpand;

  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer> {
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width < 300 ? screen.width * .55 : 220.0;
    final height = width * 9 / 16;
    final start = Offset(
      (screen.width - width - 16).clamp(0.0, double.infinity).toDouble(),
      (screen.height - height - 100).clamp(0.0, double.infinity).toDouble(),
    );
    final position = _position ?? start;
    final left = position.dx.clamp(
      0.0,
      (screen.width - width).clamp(0.0, double.infinity),
    ).toDouble();
    final top = position.dy.clamp(
      0.0,
      (screen.height - height).clamp(0.0, double.infinity),
    ).toDouble();

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => setState(() {
          _position = Offset(left + details.delta.dx, top + details.delta.dy);
        }),
        child: Material(
          color: Colors.black,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Obx(() {
                  final controller = widget.player.videoController;
                  final fit = widget.player.videoFit.value;
                  if (controller == null) return const SizedBox.shrink();
                  return AbsorbPointer(
                    child: Transform.flip(
                      flipX: widget.player.flipX.value,
                      flipY: widget.player.flipY.value,
                      child: FittedBox(
                        fit: fit.boxFit,
                        clipBehavior: Clip.hardEdge,
                        child: SimpleVideo(
                          controller: controller,
                          aspectRatio: fit.aspectRatio,
                        ),
                      ),
                    ),
                  );
                }),
                Obx(
                  () => widget.player.isBuffering.value
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const SizedBox.shrink(),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '返回视频页',
                        icon: const Icon(
                          Icons.open_in_full,
                          color: Colors.white,
                          size: 19,
                        ),
                        onPressed: widget.onExpand,
                      ),
                      IconButton(
                        tooltip: '关闭小窗',
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 19,
                        ),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: StreamBuilder<bool>(
                    stream: widget.player.videoPlayerController?.stream.playing,
                    initialData: widget.player.playerStatus.isPlaying,
                    builder: (_, snapshot) => IconButton(
                      tooltip: snapshot.data == true ? '暂停' : '播放',
                      icon: Icon(
                        snapshot.data == true ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () => snapshot.data == true
                          ? widget.player.pause()
                          : widget.player.play(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
