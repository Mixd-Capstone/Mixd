import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

// 5. Profile Page
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final AuthService authService = AuthService();
    final displayName = user?.userMetadata?['full_name'] ?? 'User';
    final photoUrl =
        user?.userMetadata?['avatar_url'] ?? 'https://via.placeholder.com/150';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(photoUrl),
            ),
            const SizedBox(height: 20),
            Text(
              displayName,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user?.email ?? '',
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Mixes', '14'),
                _stat('Followers', '1.2k'),
                _stat('Following', '456'),
              ],
            ),
            const SizedBox(height: 40),
            _btn(Icons.edit_rounded, 'Edit Profile'),
            _btn(Icons.settings_rounded, 'Settings'),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => authService.signOut(),
              child: Text(
                'LOGOUT',
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white38),
        ),
      ],
    );
  }

  Widget _btn(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.blueAccent),
          title: Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }
}

