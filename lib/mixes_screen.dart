import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'walkman_player_screen.dart';

class MixesScreen extends StatefulWidget {
  const MixesScreen({super.key});

  @override
  State<MixesScreen> createState() => _MixesScreenState();
}

class _MixesScreenState extends State<MixesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _myMixes = const [];
  List<Map<String, dynamic>> _sharedMixes = const [];

  @override
  void initState() {
    super.initState();
    _loadMixes();
  }

  Future<void> _loadMixes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sign in to view your mixes.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final myMixesFuture = _supabase
          .from('mixtapes')
          .select()
          .eq('creator_id', user.id)
          .order('created_at', ascending: false);

      final sharedMixesFuture = _supabase
          .from('mixtapes')
          .select()
          .contains('shared_users', [user.id]).neq('creator_id', user.id)
          .order('created_at', ascending: false);

      final results = await Future.wait([myMixesFuture, sharedMixesFuture]);
      final myMixes = (results[0] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final sharedMixes = (results[1] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _myMixes = myMixes;
        _sharedMixes = sharedMixes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load mixes right now.';
        _isLoading = false;
      });
    }
  }

  int _trackCountForMix(Map<String, dynamic> mix) {
    final tracksPayload = mix['tracks'];
    if (tracksPayload is Map<String, dynamic>) {
      final tracks = tracksPayload['tracks'];
      if (tracks is List) return tracks.length;
    }
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  List<WalkmanMixTrack> _extractPlayableTracks(Map<String, dynamic> mix) {
    final tracksPayload = mix['tracks'];
    if (tracksPayload is! Map<String, dynamic>) return const [];

    final rawTracks = tracksPayload['tracks'];
    if (rawTracks is! List) return const [];

    final playableTracks = <WalkmanMixTrack>[];
    for (final raw in rawTracks) {
      if (raw is! Map<String, dynamic>) continue;
      final fileKey = (raw['file_key'] ?? raw['fileKey'])?.toString() ?? '';
      if (fileKey.isEmpty) continue;

      final start = _asDouble(raw['start_seconds']);
      final end = _asDouble(raw['end_seconds']);
      if (end <= start) continue;

      playableTracks.add(
        WalkmanMixTrack(
          fileKey: fileKey,
          startSeconds: start,
          endSeconds: end,
          title: (raw['title'] ?? '').toString(),
          artist: (raw['artist'] ?? '').toString(),
          coverArtUrl: (raw['album_art_url'] ?? raw['albumArtUrl'])?.toString(),
        ),
      );
    }

    return playableTracks;
  }

  Widget _buildMixCard(Map<String, dynamic> mix) {
    final title = (mix['title'] as String?)?.trim();
    final description = (mix['description'] as String?)?.trim();
    final isPublic = mix['is_public'] == true;
    final coverArtUrl = mix['cover_art_url'] as String?;
    final trackCount = _trackCountForMix(mix);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: coverArtUrl != null && coverArtUrl.isNotEmpty
                ? Image.network(coverArtUrl, fit: BoxFit.cover)
                : Container(
                    color: Colors.blueAccent.withAlpha(45),
                    child: const Icon(Icons.queue_music_rounded, color: Colors.white70),
                  ),
          ),
        ),
        title: Text(
          title == null || title.isEmpty ? 'Untitled Mix' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              description == null || description.isEmpty
                  ? '$trackCount tracks'
                  : '$description · $trackCount tracks',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPublic
                    ? Colors.greenAccent.withAlpha(30)
                    : Colors.white12,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isPublic ? 'Public' : 'Private',
                style: GoogleFonts.outfit(
                  color: isPublic ? Colors.greenAccent : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        onTap: () {
          final playableTracks = _extractPlayableTracks(mix);
          if (playableTracks.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'This mix has no playable tracks yet.',
                  style: GoogleFonts.outfit(),
                ),
              ),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WalkmanPlayerScreen(
                title: title == null || title.isEmpty ? 'Untitled Mix' : title,
                artist: description == null || description.isEmpty
                    ? '${playableTracks.length} track mix'
                    : description,
                mixTracks: playableTracks,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> mixes,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (mixes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              emptyMessage,
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          )
        else
          ...mixes.map(_buildMixCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    } else if (_errorMessage != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: GoogleFonts.outfit(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadMixes,
              child: Text(
                'Retry',
                style: GoogleFonts.outfit(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadMixes,
        color: Colors.blueAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Mixes',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            _buildSection(
              title: 'My mixes',
              mixes: _myMixes,
              emptyMessage: 'No mixes yet. Create and save your first mix.',
            ),
            const SizedBox(height: 22),
            _buildSection(
              title: 'Shared with you',
              mixes: _sharedMixes,
              emptyMessage: 'No shared mixes yet.',
            ),
          ],
        ),
      );
    }

    return SafeArea(child: body);
  }
}
