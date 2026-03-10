// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.textLight.withOpacity(0.2))),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary)),
          onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── PROFILE CARD ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 16)],
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? Text(name[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary)) : null,
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.dmSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(email, style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Wildlife Volunteer', style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
              ])),
            ]),
          ),

          const SizedBox(height: 24),

          // ── PREVIOUS REPORTS ────────────────────────────────────────────────
          Text('Previous Reports', style: GoogleFonts.playfairDisplay(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.currentUser != null
                ? FirebaseFirestore.instance.collection('rescue_cases')
                    .where('reportedBy', isEqualTo: FirebaseService.currentUser!.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                : const Stream.empty(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textLight.withOpacity(0.15))),
                child: Column(children: [
                  Icon(Icons.history, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('No reports submitted yet', style: GoogleFonts.dmSans(
                      color: AppColors.textLight, fontSize: 14)),
                ]),
              );
              return Column(children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final ts = (d['createdAt'] as Timestamp?)?.toDate();
                final timeStr = ts != null ? DateFormat('dd MMM yyyy, HH:mm').format(ts) : '';
                final urgency = d['urgencyLevel'] ?? 'Routine';
                final urgencyColor = _urgencyColor(urgency);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: urgencyColor.withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                  child: Row(children: [
                    // Photo or icon
                    ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: d['photoUrl'] != null
                          ? Image.network(d['photoUrl'], width: 52, height: 52, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _iconBox(urgencyColor))
                          : _iconBox(urgencyColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(d['animalType'] ?? 'Unknown', style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: urgencyColor, borderRadius: BorderRadius.circular(20)),
                            child: Text(urgency, style: GoogleFonts.dmSans(
                                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                      ]),
                      const SizedBox(height: 3),
                      Text(d['locationDescription'] ?? '', style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(timeStr, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textLight)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _statusColor(d['status'] ?? '').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text((d['status'] ?? 'pending').toUpperCase(),
                            style: GoogleFonts.dmSans(
                                color: _statusColor(d['status'] ?? ''),
                                fontWeight: FontWeight.w700, fontSize: 9))),
                  ]),
                );
              }).toList());
            },
          ),

          const SizedBox(height: 24),

          // ── APP INFO ────────────────────────────────────────────────────────
          Text('App Info', style: GoogleFonts.playfairDisplay(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textLight.withOpacity(0.15))),
            child: Column(children: [
              _InfoRow(icon: Icons.info_outline, label: 'Version', value: '2.0.0'),
              Divider(color: AppColors.textLight.withOpacity(0.15), height: 1, indent: 50),
              _InfoRow(icon: Icons.track_changes_rounded, label: 'App', value: 'SILVA Wildlife Tracker'),
            ]),
          ),

          const SizedBox(height: 24),

          // ── LOGOUT ──────────────────────────────────────────────────────────
          SizedBox(height: 54, child: ElevatedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text('Log Out', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          )),

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _iconBox(Color color) => Container(width: 52, height: 52,
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(Icons.pets, color: color, size: 24));

  Color _urgencyColor(String u) {
    switch (u) {
      case 'Code Red': return AppColors.danger;
      case 'Emergency': return const Color(0xFFFF5722);
      case 'Urgent': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return AppColors.warning;
      case 'assigned': return AppColors.info;
      case 'resolved': return AppColors.success;
      default: return AppColors.textLight;
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Log Out', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 20)),
      content: Text('Are you sure you want to log out?',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
        ElevatedButton(
          onPressed: () async {
            await FirebaseService.logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Log Out', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 14),
      Text(label, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]),
  );
}
