import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

// 5. Profile Page
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _profile;
  int _mixCount = 0;
  int _likesReceived = 0;

  User? get _user => _supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _user;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Not signed in.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profileRow = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final mixes = (await _supabase
              .from('mixtapes')
              .select('id, likes')
              .eq('creator_id', user.id))
          .cast<Map<String, dynamic>>();

      var likesSum = 0;
      for (final m in mixes) {
        final likes = m['likes'];
        if (likes is num) likesSum += likes.toInt();
        if (likes is String) likesSum += int.tryParse(likes) ?? 0;
      }

      // If no profile row exists yet, create one with best-effort defaults.
      final effectiveProfile = profileRow ??
          await _supabase
              .from('profiles')
              .upsert({
                'id': user.id,
                'username': _defaultUsernameFor(user),
                'full_name': user.userMetadata?['full_name'],
                'avatar_url': user.userMetadata?['avatar_url'],
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .select()
              .maybeSingle();

      if (!mounted) return;
      setState(() {
        _profile = effectiveProfile;
        _mixCount = mixes.length;
        _likesReceived = likesSum;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load profile.\n$e';
        _loading = false;
      });
    }
  }

  String _defaultUsernameFor(User user) {
    final email = (user.email ?? '').trim();
    if (email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    if (user.id.length >= 8) return user.id.substring(0, 8);
    return 'user';
  }

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  Future<void> _openEditProfile() async {
    final user = _user;
    if (user == null) return;

    final currentUsername = (_profile?['username'] ?? '').toString().trim();
    final currentFullName = (_profile?['full_name'] ?? '').toString().trim();

    final usernameController = TextEditingController(text: currentUsername);
    final fullNameController = TextEditingController(text: currentFullName);
    var saving = false;

    final updatedRow = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121B35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              final username = usernameController.text.trim();
              final fullName = fullNameController.text.trim();
              if (username.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Username can’t be empty.',
                      style: GoogleFonts.outfit(),
                    ),
                  ),
                );
                return;
              }

              setSheetState(() => saving = true);
              try {
                final row = await _supabase.from('profiles').upsert({
                  'id': user.id,
                  'username': username,
                  'full_name': fullName.isEmpty ? null : fullName,
                  // keep avatar_url as-is; allow changing later if you want
                  'avatar_url': _profile?['avatar_url'] ?? user.userMetadata?['avatar_url'],
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                }).select().maybeSingle();

                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(row);
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Could not save.\n$e', style: GoogleFonts.outfit()),
                  ),
                );
              } finally {
                if (ctx.mounted) setSheetState(() => saving = false);
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Text(
                        'Edit profile',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameController,
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: GoogleFonts.outfit(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: fullNameController,
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Full name (optional)',
                          labelStyle: GoogleFonts.outfit(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: saving ? null : save,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF3A7BFF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Save',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (updatedRow != null) {
      setState(() {
        _profile = updatedRow;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated.', style: GoogleFonts.outfit()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final username = (_profile?['username'] ?? '').toString().trim();
    final fullName = (_profile?['full_name'] ?? '').toString().trim();
    final photoUrl = ((_profile?['avatar_url'] ?? user?.userMetadata?['avatar_url']) ?? '')
        .toString()
        .trim();

    final displayName = fullName.isNotEmpty
        ? fullName
        : (username.isNotEmpty ? '@$username' : (user?.email ?? 'User'));

    Widget body;
    if (_loading) {
      body = const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: Text('Retry', style: GoogleFonts.outfit()),
              ),
            ],
          ),
        ),
      );
    } else {
      body = SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 26),
            CircleAvatar(
              radius: 58,
              backgroundColor: Colors.white10,
              backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
              child: photoUrl.isEmpty
                  ? const Icon(Icons.person_rounded, size: 54, color: Colors.white54)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (username.isNotEmpty && fullName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '@$username',
                  style: GoogleFonts.outfit(color: Colors.white54),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                user?.email ?? '',
                style: GoogleFonts.outfit(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Mixes', _fmt(_mixCount)),
                _stat('Likes', _fmt(_likesReceived)),
              ],
            ),
            const SizedBox(height: 26),
            _btn(
              Icons.edit_rounded,
              'Edit Profile',
              onTap: _openEditProfile,
            ),
            _btn(
              Icons.refresh_rounded,
              'Refresh',
              onTap: _load,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => _authService.signOut(),
              child: Text(
                'LOGOUT',
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      );
    }

    return SafeArea(child: body);
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
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white38),
        ),
      ],
    );
  }

  Widget _btn(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: ListTile(
          onTap: onTap,
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

