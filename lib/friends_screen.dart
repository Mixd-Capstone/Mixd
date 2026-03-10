import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'walkman_player_screen.dart';

// 4. Friends Page
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Friends',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Friends'),
              Tab(text: 'Mixes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FriendsTab(),
            _UserMixesTab(),
          ],
        ),
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading:
              CircleAvatar(backgroundColor: Colors.blueAccent.withAlpha(128)),
          title: Text(
            'Friend Name ${index + 1}',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          subtitle: Text(
            'Last seen: 2 hrs ago',
            style: GoogleFonts.outfit(color: Colors.white38),
          ),
          trailing: const Icon(Icons.chat_bubble_outline,
              color: Colors.blueAccent),
        );
      },
    );
  }
}

class _MixTrack {
  const _MixTrack({
    required this.title,
    required this.artist,
    required this.source,
  });

  final String title;
  final String artist;
  final String source; // local path OR http(s) url
}

class _UserMixesTab extends StatelessWidget {
  const _UserMixesTab();

  static const _tracks = <_MixTrack>[
    _MixTrack(
      title: 'Walkman Demo Mix',
      artist: 'Ácido Pantera',
      source: 'assets/audio/sample.mp3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Your Mixes',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final t in _tracks)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.album_rounded,
                    color: Colors.blueAccent),
              ),
              title: Text(
                t.title,
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              subtitle: Text(
                t.artist,
                style: GoogleFonts.outfit(color: Colors.white54),
              ),
              trailing: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white70),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WalkmanPlayerScreen(
                      filePath: t.source,
                      title: t.title,
                      artist: t.artist,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

