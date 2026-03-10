// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import 'animal_detail_screen.dart';
import 'rescue_cases_screen.dart';
import 'fence_manager_screen.dart';

// Sample data shown when Firestore is empty
final _sampleAnimals = [
  {'id': 's1', 'name': 'Amber', 'species': 'Bengal Tiger', 'lat': 22.28, 'lng': 80.72, 'distress': false},
  {'id': 's2', 'name': 'Bruno', 'species': 'Indian Elephant', 'lat': 29.35, 'lng': 78.85, 'distress': true},
  {'id': 's3', 'name': 'Luna', 'species': 'Snow Leopard', 'lat': 33.97, 'lng': 77.50, 'distress': false},
  {'id': 's4', 'name': 'Rex', 'species': 'Red Fox', 'lat': 28.60, 'lng': 77.20, 'distress': false},
  {'id': 's5', 'name': 'Nala', 'species': 'Indian Leopard', 'lat': 19.10, 'lng': 74.30, 'distress': false},
  {'id': 's6', 'name': 'Simba', 'species': 'Asiatic Lion', 'lat': 21.17, 'lng': 70.58, 'distress': true},
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _showFences = true;
  bool _distressOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        StreamBuilder<QuerySnapshot>(
          stream: _distressOnly
              ? FirebaseService.distressAnimalsStream()
              : FirebaseService.animalsStream(),
          builder: (_, animalSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.fencesStream(),
              builder: (_, fenceSnap) {
                final firestoreAnimals = animalSnap.data?.docs ?? [];
                final fences = fenceSnap.data?.docs ?? [];
                // Use sample data if Firestore is empty
                final useSample = firestoreAnimals.isEmpty;

                return FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                      initialCenter: LatLng(22, 78), initialZoom: 4.5),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.silva',
                    ),

                    // Fence polygons
                    if (_showFences)
                      PolygonLayer(
                        polygons: fences.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final isBreached = d['isBreached'] == true;
                          final rawPts = d['polygon'] as List<dynamic>? ?? [];
                          final pts = rawPts.map((p) => LatLng(
                              (p['lat'] as num).toDouble(),
                              (p['lng'] as num).toDouble())).toList();
                          if (pts.isEmpty) return null;
                          return Polygon(
                            points: pts,
                            color: isBreached
                                ? AppColors.fenceBreach.withOpacity(0.15)
                                : AppColors.fenceColor.withOpacity(0.12),
                            borderColor: isBreached ? AppColors.fenceBreach : AppColors.fenceColor,
                            borderStrokeWidth: isBreached ? 2.5 : 1.8,
                            isDotted: !isBreached,
                          );
                        }).whereType<Polygon>().toList(),
                      ),

                    // Breach markers
                    if (_showFences)
                      MarkerLayer(
                        markers: fences.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return d['isBreached'] == true && d['breachLat'] != null;
                        }).map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return Marker(
                            point: LatLng((d['breachLat'] as num).toDouble(),
                                (d['breachLng'] as num).toDouble()),
                            width: 160, height: 64,
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(color: AppColors.fenceBreach,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: AppColors.fenceBreach.withOpacity(0.4), blurRadius: 8)]),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.fence_rounded, color: Colors.white, size: 13),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(d['breachedByAnimalName'] ?? 'Unknown',
                                      style: GoogleFonts.dmSans(color: Colors.white,
                                          fontWeight: FontWeight.w700, fontSize: 11),
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                              ),
                              Container(width: 2, height: 10, color: AppColors.fenceBreach),
                              Container(width: 10, height: 10,
                                  decoration: BoxDecoration(color: AppColors.fenceBreach, shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2))),
                            ]),
                          );
                        }).toList(),
                      ),

                    // Animal markers — Firestore or sample
                    MarkerLayer(
                      markers: useSample
                          ? _sampleAnimals
                              .where((a) => !_distressOnly || a['distress'] == true)
                              .map((a) => _buildSampleMarker(context, a)).toList()
                          : firestoreAnimals.where((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              return d['lastKnownLocation']?['latitude'] != null;
                            }).map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              final loc = d['lastKnownLocation'];
                              final isDistress = d['distressTriggered'] == true;
                              return Marker(
                                point: LatLng((loc['latitude'] as num).toDouble(),
                                    (loc['longitude'] as num).toDouble()),
                                width: 56, height: 64,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => AnimalDetailScreen(animalId: doc.id))),
                                  child: _animalPin(d['name'] ?? '', isDistress),
                                ),
                              );
                            }).toList(),
                    ),
                  ],
                );
              },
            );
          },
        ),

        // Top bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16, right: 16,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16)]),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/silva_logo.png', width: 26, height: 26, fit: BoxFit.cover)),
                const SizedBox(width: 8),
                Text('Live Map', style: GoogleFonts.playfairDisplay(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
            ),
            const Spacer(),
            _MapToggleBtn(icon: Icons.fence_rounded, label: 'Fences',
                active: _showFences, color: AppColors.fenceColor,
                onTap: () => setState(() => _showFences = !_showFences)),
            const SizedBox(width: 8),
            _MapToggleBtn(icon: Icons.warning_rounded, label: 'Distress',
                active: _distressOnly, color: AppColors.danger,
                onTap: () => setState(() => _distressOnly = !_distressOnly)),
          ]),
        ),

        // Legend
        Positioned(
          bottom: 130, left: 16,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _LegendItem(color: AppColors.primary, label: 'Tracked Animal'),
              const SizedBox(height: 5),
              _LegendItem(color: AppColors.danger, label: 'Distress Signal'),
              const SizedBox(height: 5),
              _LegendItem(color: AppColors.fenceColor, label: 'Fence Zone'),
              const SizedBox(height: 5),
              _LegendItem(color: AppColors.fenceBreach, label: 'Fence Breached'),
            ]),
          ),
        ),

        // FABs
        Positioned(
          bottom: 80, right: 16,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FloatingActionButton.small(
              heroTag: 'fence_mgr',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FenceManagerScreen())),
              backgroundColor: AppColors.fenceColor,
              child: const Icon(Icons.fence_rounded, color: Colors.white),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'rescue_cases',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RescueCasesScreen())),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.medical_services_rounded),
              label: Text('Rescue Cases', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ]),
    );
  }

  Marker _buildSampleMarker(BuildContext context, Map<String, dynamic> a) {
    final isDistress = a['distress'] == true;
    return Marker(
      point: LatLng((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble()),
      width: 56, height: 64,
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: isDistress ? AppColors.danger.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.pets, color: isDistress ? AppColors.danger : AppColors.primary)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['name'] as String, style: GoogleFonts.playfairDisplay(
                      fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(a['species'] as String, style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ]),
                const Spacer(),
                if (isDistress) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(20)),
                    child: Text('DISTRESS', style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
              ]),
              const SizedBox(height: 12),
              Text('Sample tracking data — add real animals via Firestore',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textLight)),
            ]),
          ),
        ),
        child: _animalPin(a['name'] as String, isDistress),
      ),
    );
  }

  Widget _animalPin(String name, bool isDistress) {
    return Column(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: isDistress ? AppColors.danger : AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(
            color: (isDistress ? AppColors.danger : AppColors.primary).withOpacity(0.4),
            blurRadius: 10, spreadRadius: isDistress ? 3 : 0,
          )],
        ),
        child: Icon(isDistress ? Icons.warning_rounded : Icons.pets, color: Colors.white, size: 22),
      ),
      Container(width: 8, height: 8,
          decoration: BoxDecoration(
              color: isDistress ? AppColors.danger : AppColors.primary,
              shape: BoxShape.circle)),
    ]);
  }
}

class _MapToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _MapToggleBtn({required this.icon, required this.label, required this.active,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: active ? color : Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)]),
        child: Row(children: [
          Icon(icon, size: 14, color: active ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
  ]);
}
