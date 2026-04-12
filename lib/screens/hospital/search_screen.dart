import 'package:flutter/material.dart';
import '../../services/dummy_data_services.dart';
import 'hospital_detail_screen.dart';

enum SearchFilter { all, available, lowQueue }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  SearchFilter _filter = SearchFilter.all;
  String _selectedSpecialty = 'All';

  // Collect all hospitals across all cities
  List<Map<String, dynamic>> get _allHospitals {
    final result = <Map<String, dynamic>>[];
    DummyDataService.getHospitalsByCity().forEach((city, hospitals) {
      for (final h in hospitals) {
        result.add({...h, 'city': city});
      }
    });
    return result;
  }

  List<String> get _allSpecialties {
    final set = <String>{'All'};
    for (final h in _allHospitals) {
      final specs = h['specialties'] as List? ?? [];
      for (final s in specs) {
        set.add(s.toString());
      }
    }
    return set.toList()..sort();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _allHospitals;

    // Text search
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((h) {
        final name = (h['name'] as String? ?? '').toLowerCase();
        final city = (h['city'] as String? ?? '').toLowerCase();
        final specs = (h['specialties'] as List? ?? [])
            .map((s) => s.toString().toLowerCase())
            .join(' ');
        return name.contains(q) || city.contains(q) || specs.contains(q);
      }).toList();
    }

    // Specialty filter
    if (_selectedSpecialty != 'All') {
      list = list.where((h) {
        final specs = h['specialties'] as List? ?? [];
        return specs.any((s) => s.toString() == _selectedSpecialty);
      }).toList();
    }

    // Availability filter
    switch (_filter) {
      case SearchFilter.available:
        list = list.where((h) {
          final beds = h['beds'] as Map<String, dynamic>? ?? {};
          final total = ((beds['general'] as int?) ?? 0) +
              ((beds['icu'] as int?) ?? 0);
          return (h['queue'] as int? ?? 99) < total;
        }).toList();
        break;
      case SearchFilter.lowQueue:
        list = list.where((h) => (h['queue'] as int? ?? 99) < 10).toList();
        break;
      case SearchFilter.all:
        break;
    }

    // Sort by smart score
    list.sort((a, b) {
      final distA = (a['distanceKm'] as num?)?.toDouble() ?? 99;
      final distB = (b['distanceKm'] as num?)?.toDouble() ?? 99;
      final qA = (a['queue'] as int?) ?? 99;
      final qB = (b['queue'] as int?) ?? 99;
      return (distA * 0.5 + qA * 0.5).compareTo(distB * 0.5 + qB * 0.5);
    });

    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final specialties = _allSpecialties;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: false,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search hospitals, cities, specialties…',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 18),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Hospitals',
                        isActive: _filter == SearchFilter.all,
                        onTap: () =>
                            setState(() => _filter = SearchFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '🛏 Beds Available',
                        isActive: _filter == SearchFilter.available,
                        onTap: () => setState(
                            () => _filter = SearchFilter.available),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '⚡ Low Queue',
                        isActive: _filter == SearchFilter.lowQueue,
                        onTap: () => setState(
                            () => _filter = SearchFilter.lowQueue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Specialty filter
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: specialties.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final spec = specialties[i];
                      final isActive = _selectedSpecialty == spec;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedSpecialty = spec),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF1565C0)
                                : const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            spec,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF555555),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Result count ────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Results ─────────────────────────────────────────────────────
          Expanded(
            child: results.isEmpty
                ? _EmptySearch(query: _query)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _SearchResultCard(hospital: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Search Result Card ────────────────────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> hospital;

  const _SearchResultCard({required this.hospital});

  @override
  Widget build(BuildContext context) {
    final beds = hospital['beds'] as Map<String, dynamic>? ?? {};
    final generalBeds = (beds['general'] as int?) ?? 0;
    final icuBeds = (beds['icu'] as int?) ?? 0;
    final totalBeds = generalBeds + icuBeds;
    final queue = (hospital['queue'] as int?) ?? 0;
    final isAvailable = queue < totalBeds;
    final rating = (hospital['rating'] as num?)?.toDouble() ?? 0.0;
    final city = hospital['city'] as String? ?? '';
    final specialties = hospital['specialties'] as List? ?? [];

    // Wait time
    String waitText;
    if (queue < totalBeds) {
      waitText = 'Available Now';
    } else {
      final mins = (queue - totalBeds) * 45;
      waitText = mins < 60 ? '~$mins min wait' : '~${mins ~/ 60}h wait';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HospitalDetailScreen(hospital: hospital, city: city),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital['name'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Color(0xFF888888)),
                            const SizedBox(width: 3),
                            Text(
                              '$city · ${hospital['distance'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF888888)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Specialties
              if (specialties.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: specialties.take(2).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        s.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Beds
                  Icon(Icons.bed_rounded,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '$totalBeds beds',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF555555)),
                  ),
                  const SizedBox(width: 12),
                  // Queue
                  Icon(Icons.people_alt_rounded,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Queue: $queue',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF555555)),
                  ),

                  const Spacer(),

                  // Wait time badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                          : const Color(0xFFF57C00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      waitText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isAvailable
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFF57C00),
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
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1565C0)
              : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF1565C0)
                : const Color(0xFFDDE3F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final String query;

  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'Search hospitals, cities or specialties'
                : 'No results for "$query"',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try a different name, city or specialty',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
            ),
          ]
        ],
      ),
    );
  }
}
