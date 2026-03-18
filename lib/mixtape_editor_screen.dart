import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MixtapeEditorScreen extends StatefulWidget {
  const MixtapeEditorScreen({
    super.key,
    required this.songs,
    this.onSaved,
  });

  /// Payload passed from Create screen.
  /// Each map should contain: id, title, artist, albumArtUrl, fileKey, durationSeconds.
  final List<Map<String, dynamic>> songs;
  final VoidCallback? onSaved;

  @override
  State<MixtapeEditorScreen> createState() => _MixtapeEditorScreenState();
}

class _MixtapeEditorScreenState extends State<MixtapeEditorScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayer _player = AudioPlayer();

  late List<_MixtapeClip> _clips;
  int _selectedIndex = -1;

  // Zoom into timeline while dragging start/end for precision
  int _zoomedClipIndex = -1;
  double _zoomMin = 0;
  double _zoomMax = 300;

  // Playback state
  bool _isPlaying = false;
  bool _isMixMode = true;
  double _mixPositionSeconds = 0;
  int _currentIndexPlaying = 0;
  int? _singleSongIndex;
  bool _isSavingMixtape = false;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<int?>? _indexSub;

  double get _totalTrimmedDuration =>
      _clips.fold(0, (sum, c) => sum + c.trimmedDuration);

  @override
  void initState() {
    super.initState();
    _clips = widget.songs.map(_MixtapeClip.fromMap).toList();

    _indexSub = _player.currentIndexStream.listen((idx) {
      if (idx == null) return;
      _currentIndexPlaying = idx;
    });

    _positionSub = _player.positionStream.listen((pos) {
      if (!_isPlaying || _clips.isEmpty) return;
      final localSeconds = pos.inMilliseconds / 1000.0;

      if (_isMixMode) {
        final offsetBefore = _offsetUntil(_currentIndexPlaying);
        final currentClip = _clips[_currentIndexPlaying];
        final effectiveLocal =
            localSeconds.clamp(0.0, currentClip.trimmedDuration);
        final mixPos = (offsetBefore + effectiveLocal)
            .clamp(0.0, _totalTrimmedDuration);

        if (mounted) {
          setState(() {
            _mixPositionSeconds = mixPos;
          });
        }
      } else if (_singleSongIndex != null) {
        final idx = _singleSongIndex!;
        final clip = _clips[idx];
        final offsetBefore = _offsetUntil(idx);
        final effectiveLocal =
            localSeconds.clamp(0.0, clip.trimmedDuration);
        final mixPos = (offsetBefore + effectiveLocal)
            .clamp(0.0, _totalTrimmedDuration);

        if (mounted) {
          setState(() {
            _mixPositionSeconds = mixPos;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _indexSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  double _offsetUntil(int clipIndex) {
    double sum = 0;
    for (int i = 0; i < clipIndex && i < _clips.length; i++) {
      sum += _clips[i].trimmedDuration;
    }
    return sum;
  }

  Future<String?> _buildSongUrl(_MixtapeClip clip) async {
    if (clip.fileKey == null || clip.fileKey!.isEmpty) return null;
    final objectPath =
        clip.fileKey!.endsWith('.mp3') ? clip.fileKey! : '${clip.fileKey!}.mp3';
    try {
      final signedUrl = await _supabase.storage
          .from('song-files')
          .createSignedUrl(objectPath, const Duration(minutes: 5).inSeconds);
      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  AudioSource _buildClipSource(_MixtapeClip clip) {
    final uri = Uri.parse(clip.url!);
    return ClippingAudioSource(
      start: Duration(milliseconds: (clip.startSeconds * 1000).round()),
      end: Duration(milliseconds: (clip.endSeconds * 1000).round()),
      child: AudioSource.uri(uri),
    );
  }

  /// Fetches fresh signed URLs for all clips. Signed URLs expire after 5 minutes,
  /// so we always refetch before playing to avoid playback failing "after a while".
  Future<void> _ensureUrls() async {
    for (final clip in _clips) {
      final url = await _buildSongUrl(clip);
      clip.url = url;
    }
  }

  Future<void> _playMix() async {
    if (_clips.isEmpty) return;

    await _ensureUrls();
    final sources = _clips.where((c) => c.url != null).map(_buildClipSource).toList();
    if (sources.isEmpty) return;

    try {
      await _player.stop();
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
      );
      setState(() {
        _isPlaying = true;
        _isMixMode = true;
        _currentIndexPlaying = 0;
        _singleSongIndex = null;
      });
      _player.play();
    } catch (_) {
      _stopPlayback();
    }
  }

  Future<void> _playSingle(int index) async {
    if (_clips.isEmpty) return;
    await _ensureUrls();

    final clip = _clips[index];
    if (clip.url == null) return;

    try {
      await _player.stop();
      await _player.setAudioSource(_buildClipSource(clip));
      setState(() {
        _isPlaying = true;
        _isMixMode = false;
        _currentIndexPlaying = 0;
        _singleSongIndex = index;
        _mixPositionSeconds = _offsetUntil(index);
      });
      _player.play();
    } catch (_) {
      _stopPlayback();
    }
  }

  Future<void> _seekInMix(double seconds) async {
    if (_clips.isEmpty) return;
    final target = seconds.clamp(0.0, _totalTrimmedDuration);

    double acc = 0;
    int idx = 0;
    for (; idx < _clips.length; idx++) {
      final len = _clips[idx].trimmedDuration;
      if (target < acc + len) break;
      acc += len;
    }
    if (idx >= _clips.length) {
      idx = _clips.length - 1;
      acc -= _clips[idx].trimmedDuration;
    }
    final local = target - acc;

    if (_isMixMode) {
      await _player.seek(
        Duration(milliseconds: (local * 1000).round()),
        index: idx,
      );
    } else {
      await _playSingle(idx);
      await _player.seek(
        Duration(milliseconds: (local * 1000).round()),
      );
    }

    if (mounted) {
      setState(() {
        _mixPositionSeconds = target;
        _currentIndexPlaying = idx;
      });
    }
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _singleSongIndex = null;
      });
    }
  }

  void _enterZoomForClip(int index) {
    if (index < 0 || index >= _clips.length) return;
    final clip = _clips[index];
    final fullMax = clip.originalDurationSeconds
        .toDouble()
        .clamp(1, 600);
    final center = (clip.startSeconds + clip.endSeconds) / 2;
    const zoomPadding = 25.0;
    final halfWidth = (clip.trimmedDuration / 2)
        .clamp(zoomPadding, 60.0);
    setState(() {
      _zoomedClipIndex = index;
      _zoomMin = (center - halfWidth)
          .clamp(0.0, fullMax - 10)
          .toDouble();
      _zoomMax = (center + halfWidth)
          .clamp(10.0, fullMax)
          .toDouble();
      if (_zoomMax - _zoomMin < 10) {
        _zoomMin = (_zoomMax - 10)
            .clamp(0.0, fullMax)
            .toDouble();
      }
    });
  }

  void _exitZoom() {
    setState(() {
      _zoomedClipIndex = -1;
    });
  }

  String _defaultMixtapeTitle() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return 'Mix $month/$day';
  }

  Map<String, dynamic> _buildTracksPayload() {
    final tracks = <Map<String, dynamic>>[];
    for (int i = 0; i < _clips.length; i++) {
      final clip = _clips[i];
      tracks.add({
        'position': i,
        'song_id': clip.id,
        'title': clip.title,
        'artist': clip.artist,
        'album_art_url': clip.albumArtUrl,
        'file_key': clip.fileKey,
        'start_seconds': clip.startSeconds,
        'end_seconds': clip.endSeconds,
        'original_duration_seconds': clip.originalDurationSeconds,
        'trimmed_duration_seconds': clip.trimmedDuration,
      });
    }
    return {'tracks': tracks};
  }

  Future<void> _saveMixtape({
    required String title,
    required String description,
    required bool isPublic,
  }) async {
    if (_clips.isEmpty || _isSavingMixtape) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in again to save this mixtape.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSavingMixtape = true;
    });

    try {
      final trimmedTitle = title.trim();
      final trimmedDescription = description.trim();
      await _supabase.from('mixtapes').insert({
        'creator_id': user.id,
        'title': trimmedTitle.isEmpty ? _defaultMixtapeTitle() : trimmedTitle,
        'description': trimmedDescription.isEmpty ? null : trimmedDescription,
        'cover_art_url': _clips.first.albumArtUrl,
        'tracks': _buildTracksPayload(),
        'is_public': isPublic,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mixtape saved.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
      widget.onSaved?.call();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save mixtape. Please try again.',
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMixtape = false;
        });
      }
    }
  }

  Future<void> _promptAndSaveMixtape() async {
    if (_clips.isEmpty || _isSavingMixtape) return;

    final titleController = TextEditingController(text: _defaultMixtapeTitle());
    final descriptionController = TextEditingController();
    bool isPublic = false;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              title: Text(
                'Save Mixtape',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Switch(
                        value: isPublic,
                        onChanged: (value) {
                          setDialogState(() {
                            isPublic = value;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Make mix public',
                          style: GoogleFonts.outfit(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: Colors.white70),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave == true) {
      await _saveMixtape(
        title: titleController.text,
        description: descriptionController.text,
        isPublic: isPublic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalTrimmedDuration > 0 ? _totalTrimmedDuration : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mixtape Editor',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF16213E),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _isSavingMixtape ? null : _promptAndSaveMixtape,
              icon: _isSavingMixtape
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_alt_rounded),
              tooltip: 'Save mixtape',
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Drag to reorder songs. Use the range sliders to snip each song. The playhead shows time across the whole mix.',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _clips.isEmpty
                ? Center(
                    child: Text(
                      'No songs selected',
                      style: GoogleFonts.outfit(color: Colors.white54),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _clips.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _clips.removeAt(oldIndex);
                        _clips.insert(newIndex, item);
                        if (_selectedIndex == oldIndex) {
                          _selectedIndex = newIndex;
                        }
                      });
                    },
                    itemBuilder: (context, index) {
                      final clip = _clips[index];
                      final isSelected = index == _selectedIndex;
                      final itemTotalOffset = _offsetUntil(index);
                      final isRowPlaying = _isPlaying &&
                          !_isMixMode &&
                          _singleSongIndex == index;

                      return Container(
                        key: ValueKey(clip.id),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.white10,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              _selectedIndex =
                                  isSelected ? -1 : index;
                            });
                          },
                          minVerticalPadding: isSelected ? 12 : 4,
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(
                                  Icons.drag_handle_rounded,
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: clip.albumArtUrl != null &&
                                          clip.albumArtUrl!.isNotEmpty
                                      ? Image.network(
                                          clip.albumArtUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.blueAccent.withAlpha(60),
                                          child: const Icon(
                                            Icons.music_note_rounded,
                                            color: Colors.white70,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            clip.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clip.artist,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Clip: ${_formatTime(clip.startSeconds)} - ${_formatTime(clip.endSeconds)} '
                                '(len ${_formatTime(clip.trimmedDuration)})',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (_zoomedClipIndex != index)
                                      TextButton.icon(
                                        onPressed: () => _enterZoomForClip(index),
                                        icon: const Icon(
                                          Icons.zoom_in_rounded,
                                          size: 18,
                                          color: Colors.blueAccent,
                                        ),
                                        label: Text(
                                          'Zoom in',
                                          style: GoogleFonts.outfit(
                                            color: Colors.blueAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    if (_zoomedClipIndex == index)
                                      FilledButton.icon(
                                        onPressed: _exitZoom,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),
                                        icon: const Icon(Icons.check_rounded, size: 16),
                                        label: Text(
                                          'Finish',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 8,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 9,
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final sliderMin = _zoomedClipIndex == index
                                          ? _zoomMin
                                          : 0.0;
                                      final sliderMax = _zoomedClipIndex == index
                                          ? _zoomMax
                                          : (clip.originalDurationSeconds
                                                  .toDouble()
                                                  .clamp(1, 600))
                                              .toDouble();
                                      final startC = clip.startSeconds
                                          .clamp(sliderMin, sliderMax)
                                          .toDouble();
                                      final endC = clip.endSeconds
                                          .clamp(sliderMin, sliderMax)
                                          .toDouble();
                                      return RangeSlider(
                                        values: RangeValues(
                                          startC,
                                          endC < startC ? startC : endC,
                                        ),
                                        min: sliderMin,
                                        max: sliderMax,
                                        labels: RangeLabels(
                                          _formatTime(clip.startSeconds),
                                          _formatTime(clip.endSeconds),
                                        ),
                                        onChanged: (values) {
                                          setState(() {
                                            clip.startSeconds = values.start;
                                            clip.endSeconds = values.end;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                                if (_zoomedClipIndex == index)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Zoomed in · Press Finish to see full song',
                                      style: GoogleFonts.outfit(
                                        color: Colors.blueAccent,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 2),
                              const SizedBox(height: 2),
                              Text(
                                'Mix position: starts at ${_formatTime(itemTotalOffset)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isRowPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (isRowPlaying) {
                                _stopPlayback();
                              } else {
                                _playSingle(index);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Full mixtape timeline
          if (_clips.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                border: Border(
                  top: BorderSide(color: Colors.white10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        iconSize: 30,
                        color: Colors.white,
                        icon: Icon(
                          _isPlaying && _isMixMode
                              ? Icons.stop_circle_rounded
                              : Icons.queue_music_rounded,
                        ),
                        onPressed: () {
                          if (_isPlaying && _isMixMode) {
                            _stopPlayback();
                          } else {
                            _playMix();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Full mixtape',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatTime(_mixPositionSeconds)} / ${_formatTime(total)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: _mixPositionSeconds.clamp(0.0, total),
                      min: 0,
                      max: total,
                      onChanged: (value) {
                        _seekInMix(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MixtapeClip {
  _MixtapeClip({
    required this.id,
    required this.title,
    required this.artist,
    required this.originalDurationSeconds,
    this.albumArtUrl,
    this.fileKey,
    this.url,
    double? startSeconds,
    double? endSeconds,
  })  : startSeconds = startSeconds ?? 0,
        endSeconds = endSeconds ?? originalDurationSeconds.toDouble();

  final String id;
  final String title;
  final String artist;
  final String? albumArtUrl;
  final String? fileKey;
  String? url;
  final int originalDurationSeconds;

  double startSeconds;
  double endSeconds;

  double get trimmedDuration =>
      (endSeconds - startSeconds).clamp(1.0, originalDurationSeconds.toDouble());

  factory _MixtapeClip.fromMap(Map<String, dynamic> map) {
    final duration =
        (map['durationSeconds'] as int?) ?? (map['duration_seconds'] as int?) ?? 30;
    return _MixtapeClip(
      id: '${map['id']}',
      title: map['title'] as String? ?? 'Untitled',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      albumArtUrl:
          map['albumArtUrl'] as String? ?? map['album_art_url'] as String?,
      fileKey: map['fileKey'] as String? ?? map['file_key'] as String?,
      originalDurationSeconds: duration,
    );
  }
}

String _formatTime(double seconds) {
  final total = seconds.round().clamp(0, 359999);
  final minutes = total ~/ 60;
  final secs = total % 60;
  return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
}



