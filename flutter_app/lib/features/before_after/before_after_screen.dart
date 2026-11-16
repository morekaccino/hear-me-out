import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
  String _noticeTitle = 'Exported';
  String? _error;
  String _errorTitle = 'Could not export';
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
                  key: const ValueKey('before-after-share'),
                  label: 'SHARE CARD',
                  icon: Icons.ios_share_rounded,
                  height: 52,
                  onPressed: _busy ? null : () => _share(data),
                ),
                const SizedBox(height: DuoSpacing.sm),
                OutlineDuoButton(
                  key: const ValueKey('before-after-export'),
                  label: 'EXPORT CARD',
                  icon: Icons.download_rounded,
                  onPressed: _busy ? null : () => _export(data),
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb
                      ? 'Share downloads the PNG only. This browser has no '
                            'share sheet, so the invitation is not attached. '
                            'Export saves the PNG too. The audio is not '
                            'included, and the card has no score or link.'
                      : 'Share sends the PNG and a short invitation through '
                            'the device share sheet. Export saves the PNG '
                            'only. The audio is not included, and the card '
                            'has no score or link.',
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
                  _messageCard(title: _noticeTitle, body: _notice!),
                ],
                if (_error != null) ...[
                  const SizedBox(height: DuoSpacing.md),
                  _messageCard(title: _errorTitle, body: _error!),
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
      _errorTitle = 'Could not play';
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
      _noticeTitle = 'Exported';
      _errorTitle = 'Could not export';
      _error = null;
    });
    try {
      final result = await _renderAndWriteCard(data);
      if (!mounted) return;
      if (result == null) {
        setState(() => _error = 'The card is not ready to export.');
        return;
      }
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

  Future<void> _share(BeforeAfterCardData data) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
      _errorTitle = 'Could not share';
      _error = null;
    });
    try {
      final result = await _renderAndWriteCard(data);
      if (!mounted) return;
      if (result == null) {
        setState(() => _error = 'The card is not ready to share.');
        return;
      }
      final outcome = await ref
          .read(recordingControllerProvider.notifier)
          .shareBeforeAfterCard(path: result.path, fileName: result.fileName);
      if (!mounted) return;
      setState(() {
        if (outcome.cancelled) {
          _noticeTitle = 'Share cancelled';
        } else {
          _noticeTitle = outcome.shared ? 'Shared' : 'Card saved';
        }
        if (outcome.failed) {
          _error = outcome.message;
        } else {
          _notice = outcome.message;
        }
      });
    } on RecordingExportException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not share the card.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Renders the card and writes the one PNG through the existing export seam.
  ///
  /// A null result means the card was not ready to render; export and share
  /// use the same bytes and the same per-take file name.
  Future<RecordingExportResult?> _renderAndWriteCard(
    BeforeAfterCardData data,
  ) async {
    final renderer = widget.renderer ?? _renderCardPng;
    final bytes = await renderer(_cardKey);
    if (bytes == null || bytes.isEmpty) return null;
    final exporter = await ref.read(recordingExporterProvider.future);
    return exporter.export(
      RecordingExportRequest(
        id: 'before-after-card',
        fileName: 'before-after-${_safeName(data.pieceId)}-${data.last.id}.png',
        bytes: bytes,
        mimeType: 'image/png',
      ),
    );
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
