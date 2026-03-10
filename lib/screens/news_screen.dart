// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';

const _sampleNews = [
  {
    'title': 'Bengal Tiger Population Rises to 3,682 in India',
    'summary': 'India\'s latest tiger census shows a 6% increase in Bengal tiger population, driven by conservation efforts in Madhya Pradesh and Karnataka reserves. SILVA tracking systems contributed real-time movement data.',
    'category': 'conservation',
    'date': 'March 8, 2026',
    'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Bengal_tiger_%28Panthera_tigris_tigris%29_female_3_crop.jpg/640px-Bengal_tiger_%28Panthera_tigris_tigris%29_female_3_crop.jpg',
  },
  {
    'title': 'Injured Snow Leopard Rescued in Ladakh, Successfully Rehabilitated',
    'summary': 'A female snow leopard found with a snare injury in the Hemis National Park has been successfully treated and released. Wildlife teams used GPS collar data to monitor her recovery journey.',
    'category': 'rescue',
    'date': 'March 5, 2026',
    'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Endangered_Snow_Leopard.jpg/640px-Endangered_Snow_Leopard.jpg',
  },
  {
    'title': 'New AI-Powered Distress Detection Deployed Across 12 Reserves',
    'summary': 'Forest departments across India have adopted AI-based animal monitoring that detects unusual movement patterns and automatically triggers alerts within minutes of an animal entering distress.',
    'category': 'research',
    'date': 'February 28, 2026',
    'imageUrl': null,
  },
  {
    'title': 'Asiatic Elephant Corridor Expanded in Western Ghats',
    'summary': 'A new 120km wildlife corridor connecting fragmented forest patches in Kerala and Tamil Nadu will allow elephant herds to migrate safely, reducing human-wildlife conflict significantly.',
    'category': 'conservation',
    'date': 'February 20, 2026',
    'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Above_Gotcha.jpg/640px-Above_Gotcha.jpg',
  },
  {
    'title': 'Geo-Fencing Technology Prevents 47 Fence Breaches This Season',
    'summary': 'Virtual geo-fence alerts deployed across the Kaziranga National Park perimeter successfully flagged 47 cases of animals moving near the highway, allowing rangers to intervene and prevent road casualties.',
    'category': 'research',
    'date': 'February 15, 2026',
    'imageUrl': null,
  },
  {
    'title': 'Red Fox Family Rescued After Forest Fire in Uttarakhand',
    'summary': 'A family of four red foxes was rescued by the Wildlife SOS team after a forest fire destroyed their habitat. All four were treated for smoke inhalation and minor burns before being released.',
    'category': 'rescue',
    'date': 'February 10, 2026',
    'imageUrl': null,
  },
];

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  Color _catColor(String cat) {
    switch (cat) {
      case 'conservation': return AppColors.success;
      case 'rescue':       return AppColors.danger;
      case 'research':     return AppColors.info;
      default:             return AppColors.primary;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'conservation': return Icons.park_rounded;
      case 'rescue':       return Icons.medical_services_rounded;
      case 'research':     return Icons.science_rounded;
      default:             return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                alignment: Alignment.bottomLeft,
                padding: EdgeInsets.only(
                    left: 20, bottom: 12,
                    top: MediaQuery.of(context).padding.top + 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('Wildlife News', style: GoogleFonts.playfairDisplay(
                      fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Latest from the field', style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.newsStream(),
              builder: (_, snap) {
                // Use Firestore data if available, else sample
                final docs = snap.data?.docs ?? [];
                final useFirestore = docs.isNotEmpty;

                if (useFirestore) {
                  return _buildFirestoreList(docs);
                } else {
                  return _buildSampleList();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(child: Text('Sample news — add real articles in Firestore → news collection',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.primary))),
          ]),
        ),
        ..._sampleNews.map((n) => _NewsCard(
          title: n['title']!,
          summary: n['summary']!,
          category: n['category']!,
          dateStr: n['date']!,
          imageUrl: n['imageUrl'],
          catColor: _catColor(n['category']!),
          catIcon: _catIcon(n['category']!),
        )).toList(),
      ]),
    );
  }

  Widget _buildFirestoreList(List<QueryDocumentSnapshot> docs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      child: Column(children: docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final cat = d['category'] ?? 'general';
        final ts = (d['publishedAt'] as Timestamp?)?.toDate();
        final timeStr = ts != null ? DateFormat('dd MMM yyyy').format(ts) : '';
        return _NewsCard(
          title: d['title'] ?? '',
          summary: d['summary'] ?? d['content'] ?? '',
          category: cat,
          dateStr: timeStr,
          imageUrl: d['imageUrl'],
          catColor: _catColor(cat),
          catIcon: _catIcon(cat),
        );
      }).toList()),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final String title, summary, category, dateStr;
  final String? imageUrl;
  final Color catColor;
  final IconData catIcon;
  const _NewsCard({required this.title, required this.summary, required this.category,
      required this.dateStr, required this.catColor, required this.catIcon, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textLight.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (imageUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(imageUrl!, height: 180, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: catColor.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(catIcon, size: 12, color: catColor),
                const SizedBox(width: 4),
                Text(category.toUpperCase(), style: GoogleFonts.dmSans(
                    fontSize: 10, color: catColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ]),
            ),
            const Spacer(),
            Text(dateStr, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textLight)),
          ]),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.playfairDisplay(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3)),
          const SizedBox(height: 8),
          Text(summary, style: GoogleFonts.dmSans(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              maxLines: 3, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}
