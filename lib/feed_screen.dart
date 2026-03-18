import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'walkman_player_screen.dart';

// 1. Reel style scrollable page
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo data for now – you can wire this to Supabase later.
    final demoItems = List.generate(
      10,
      (i) => (
        title: 'Mixtape #${i + 1}',
        artist: '@creator_name',
        // Replace with a real URL or asset path when you hook up the backend.
        source: 'assets/audio/sample.mp3',
      ),
    );

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: demoItems.length,
      itemBuilder: (context, index) {
        final item = demoItems[index];

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient to keep the TikTok-style feel.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF000000),
                    Color(0xFF0A0A1A),
                    Color(0xFF1A1A2E),
                  ],
                ),
              ),
            ),

            // Centered cassette-style card similar to the Walkman screen.
            Center(
              child: _FeedCassetteCard(
                title: item.title,
                artist: item.artist,
                onTapPlay: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WalkmanPlayerScreen(
                        filePath: item.source,
                        title: item.title,
                        artist: item.artist,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Right Sidebar actions
            Positioned(
              right: 20,
              bottom: 100,
              child: Column(
                children: [
                  _actionButton(Icons.favorite_rounded, '12k'),
                  _actionButton(Icons.comment_rounded, '456'),
                  _actionButton(Icons.share_rounded, 'Share'),
                ],
              ),
            ),

            // Bottom Info
            Positioned(
              left: 20,
              bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@creator_name',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check out this custom mix... #music #mixd',
                    style: GoogleFonts.outfit(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Icon(icon, size: 35, color: Colors.white70),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cassette-style card for the feed, visually aligned with the Walkman screen.
class _FeedCassetteCard extends StatelessWidget {
  const _FeedCassetteCard({
    required this.title,
    required this.artist,
    required this.onTapPlay,
  });

  final String title;
  final String artist;
  final VoidCallback onTapPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      widthFactor: 0.9,
      heightFactor: 0.55,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E2B4A),
              Color(0xFF18223D),
              Color(0xFF121A31),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Column(
            children: [
              // Top label area (title + artist)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                      color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 13,
                      color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Accent stripe
              SizedBox(
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0.35),
                        Colors.blueAccent.withValues(alpha: 0.12),
                        Colors.blueAccent.withValues(alpha: 0.35),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 14),
                      Expanded(
                        child: Divider(color: Colors.white24, thickness: 0.8),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Divider(color: Colors.white24, thickness: 0.8),
                      ),
                      SizedBox(width: 14),
                    ],
                  ),
                ),
              ),

              // Middle area with reels + play button (static reels)
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Center(child: _StaticReel()),
                      ),
                      GestureDetector(
                        onTap: onTapPlay,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3A7BFF),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3A7BFF).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(child: _StaticReel()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticReel extends StatelessWidget {
  const _StaticReel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0F172A),
        border: Border.all(color: Colors.white54, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 4; i++)
            Transform.rotate(
              angle: i * (3.1415926535 / 2),
              child: Container(
                width: 32,
                height: 3,
                color: Colors.white30,
              ),
            ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

