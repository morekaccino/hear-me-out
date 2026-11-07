import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/pieces/launch_pieces.dart';
import '../../core/media/before_after.dart';
import '../../core/media/recording_exporter.dart';
import '../../shared/audio/take_player.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/providers.dart';
import '../../state/recording_controller.dart';
import 'before_after_card.dart';

/// Renders the card to PNG bytes. Injectable so widget tests do not need the
/// image encoder; production uses [RenderRepaintBoundary.toImage].
typedef BeforeAfterCardRenderer = Future<Uint8List?> Function(GlobalKey key);

/// The private before/after card.
///
/// The card is rendered from real takes and exported only when the learner taps
/// the explicit action. Nothing is uploaded, shared, or ranked.
class BeforeAfterScreen extends ConsumerStatefulWidget {
  const BeforeAfterScreen({super.key, this.renderer});

  final BeforeAfterCardRenderer? renderer;

  @override
  ConsumerState<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends ConsumerState<BeforeAfterScreen> {
  final GlobalKey _cardKey = GlobalKey();
  late final TakePlayer _player;
  String? _notice;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _player = ref.read(takePlayerProvider);
  }

  @override
  void dispose() {
    unawaited(_player.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recordingControllerProvider);
    final state = async.asData?.value;
    final canPop = Navigator.of(context).canPop();
    final data = state == null
        ? null
        : buildBeforeAfterCard(
            takes: state.takes,
            pieceTitles: <String, String>{
              for (final launch in launchPieces)
                launch.piece.id: launch.piece.title,
            },
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageFrame(
          maxWidth: 600,
          child: ListView(
            key: const ValueKey('before-after-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _header(canPop),
              const SizedBox(height: DuoSpacing.md),
              if (async.isLoading && state == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(DuoSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state == null)
                _messageCard(
                  title: 'Takes are unavailable',
                  body: 'The local recording index could not be read.',
                )
              else if (data == null)
                _messageCard(
                  title: 'No before/after yet',
                  body:
                      'Record two takes for the same piece. The first and '
                      'latest take become the before/after card.',
                )
              else ...[
                RepaintBoundary(
                  key: _cardKey,
                  child: BeforeAfterCard(
                    data: data,
                    onPlayLatest: _busy ? null : () => _playLatest(data),
                  ),
                ),
                const SizedBox(height: DuoSpacing.md),
                DuoButton(
                  key: const ValueKey('before-after-export'),
                  label: 'EXPORT CARD',
                  icon: Icons.ios_share_rounded,
                  height: 52,
                  onPressed: _busy ? null : () => _export(data),
                ),
                const SizedBox(height: 8),
                Text(
                  'Export writes a PNG with the piece, phrase, dates, and the '
                  'one metric. The audio is not included. You choose whether '
                  'to send it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.textLight,
                  ),
                ),
                if (_notice != null) ...[
                  const SizedBox(height: DuoSpacing.md),
                  _messageCard(title: 'Exported', body: _notice!),
                ],
                if (_error != null) ...[
                  const SizedBox(height: DuoSpacing.md),
                  _messageCard(title: 'Could not export', body: _error!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool canPop) {
    return Row(
      children: [
        if (canPop)
          IconButton(
            key: const ValueKey('before-after-back'),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            color: AppColors.ink,
          ),
        Expanded(
          child: Text(
            'Progress card',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
        const Icon(Icons.lock_outline_rounded, color: AppColors.greenDark),
      ],
    );
  }

  Future<void> _playLatest(BeforeAfterCardData data) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
      _error = null;
    });
    try {
      final bytes = await ref
          .read(recordingControllerProvider.notifier)
          .readTake(data.last.id);
      if (bytes == null) {
        if (mounted) setState(() => _error = 'The latest take is missing.');
        return;
      }
      await _player.playWav(bytes);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not play the latest take.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(BeforeAfterCardData data) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
      _error = null;
    });
    try {
      final renderer = widget.renderer ?? _renderCardPng;
      final bytes = await renderer(_cardKey);
      if (bytes == null || bytes.isEmpty) {
        setState(() => _error = 'The card is not ready to export.');
        return;
      }
      final exporter = await ref.read(recordingExporterProvider.future);
      final result = await exporter.export(
        RecordingExportRequest(
          id: 'before-after-card',
          fileName:
              'before-after-${_safeName(data.pieceId)}-${data.last.id}.png',
          bytes: bytes,
          mimeType: 'image/png',
        ),
      );
      if (!mounted) return;
      setState(() {
        _notice = result.path == null
            ? 'Downloaded ${result.fileName}.'
            : 'Exported to ${result.path}';
      });
    } on RecordingExportException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not export the card.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List?> _renderCardPng(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }

  Widget _messageCard({required String title, required String body}) {
    return SectionCard(
      color: AppColors.surface,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

String _safeName(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
  return cleaned.isEmpty ? 'piece' : cleaned;
}
