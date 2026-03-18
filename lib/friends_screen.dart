import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 4. Friends Page
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Friends',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: const _FriendsTab(),
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

