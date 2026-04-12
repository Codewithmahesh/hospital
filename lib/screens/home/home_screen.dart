import 'package:flutter/material.dart';
import 'package:hospital/services/dummy_data_services.dart';
import '../hospital/hospital_detail_screen.dart';

// ── Sort options ───────────────────────────────────────────────────────────────
enum SortBy { distance, queue, availability, smart }

extension SortByLabel on SortBy {
  String get label {
    switch (this) {
      case SortBy.distance:
        return 'Distance';
      case SortBy.queue:
        return 'Queue';
      case SortBy.availability:
        return 'Availability';
      case SortBy.smart:
        return 'Smart Sort';
    }
  }

  IconData get icon {
    switch (this) {
      case SortBy.distance:
        return Icons.directions_walk_rounded;
      case SortBy.queue:
        return Icons.people_alt_rounded;
      case SortBy.availability:
        return Icons.bed_rounded;
      case SortBy.smart:
        return Icons.auto_awesome_rounded;
    }
  }
}

class HomeScreen extends StatefulWidget {
  final String selectedCity;

  const HomeScreen({super.key, required this.selectedCity});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SortBy _sortBy = SortBy.smart;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Sorting logic ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _sortHospitals(
    List<Map<String, dynamic>> hospitals,
  ) {
    final list = List<Map<String, dynamic>>.from(hospitals);

    switch (_sortBy) {
      case SortBy.distance:
        list.sort((a, b) =>
            (_distanceKm(a)).compareTo(_distanceKm(b)));

      case SortBy.queue:
        list.sort((a, b) =>
            (_queue(a)).compareTo(_queue(b)));

      case SortBy.availability:
        // Higher total beds = better
        list.sort((a, b) =>
            _totalBeds(b).compareTo(_totalBeds(a)));

      case SortBy.smart:
        // Weighted composite score (lower = better):
        //   distance × 0.4  +  queue × 0.35  +  (1/beds) × 0.25
        list.sort((a, b) {
          final scoreA = _smartScore(a);
          final scoreB = _smartScore(b);
          return scoreA.compareTo(scoreB);
        });
    }
    return list;
  }

  double _smartScore(Map<String, dynamic> h) {
    final dist = _distanceKm(h);
    final q = _queue(h).toDouble();
    final beds = _totalBeds(h);
    // Normalise: lower score = better choice
    final bedsPenalty = beds > 0 ? (20 / beds) : 20;
    return (dist * 0.4) + (q * 0.35) + (bedsPenalty * 0.25);
  }

  double _distanceKm(Map<String, dynamic> h) =>
      (h['distanceKm'] as num?)?.toDouble() ?? 99.0;

  int _queue(Map<String, dynamic> h) => (h['queue'] as int?) ?? 99;

  int _totalBeds(Map<String, dynamic> h) {
    final beds = h['beds'] as Map<String, dynamic>? ?? {};
    return ((beds['general'] as int?) ?? 0) + ((beds['icu'] as int?) ?? 0);
  }

  // ── Filter by search ───────────────────────────────────────────────────────

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> hospitals) {
    if (_searchQuery.isEmpty) return hospitals;
    final q = _searchQuery.toLowerCase();
    return hospitals.where((h) {
      final name = (h['name'] as String? ?? '').toLowerCase();
      final specs = (h['specialties'] as List?)
              ?.map((s) => s.toString().toLowerCase())
              .join(' ') ??
          '';
      return name.contains(q) || specs.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allData = DummyDataService.getHospitalsByCity();
    final raw = allData[widget.selectedCity] ?? [];
    final filtered = _filter(raw);
    final hospitals = _sortHospitals(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0A1628),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A1628),
                      Color(0xFF0D2B4E),
                      Color(0xFF0B4F6C),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // City row
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Color(0xFF64B5F6), size: 15),
                            const SizedBox(width: 4),
                            Text(
                              widget.selectedCity.isEmpty
                                  ? 'Select a city'
                                  : widget.selectedCity,
                              style: const TextStyle(
                                color: Color(0xFF64B5F6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Find Hospitals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Search bar inside app bar
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search hospital or symptom…',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear,
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Sort bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${hospitals.length} hospital${hospitals.length == 1 ? '' : 's'} found',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.sort_rounded,
                          size: 16, color: Color(0xFF888888)),
                      const SizedBox(width: 4),
                      const Text(
                        'Sort:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Sort chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: SortBy.values.map((sort) {
                        final isActive = _sortBy == sort;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _sortBy = sort),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    sort.icon,
                                    size: 13,
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFF555555),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    sort.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF555555),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Hospital list ─────────────────────────────────────────────────
          hospitals.isEmpty
              ? SliverFillRemaining(
                  child: _EmptyState(
                    city: widget.selectedCity,
                    hasSearch: _searchQuery.isNotEmpty,
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _HospitalCard(
                        hospital: hospitals[index],
                        rank: index,
                        sortBy: _sortBy,
                        selectedCity: widget.selectedCity,
                      ),
                      childCount: hospitals.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Hospital Card ──────────────────────────────────────────────────────────────

class _HospitalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final int rank;
  final SortBy sortBy;
  final String selectedCity;

  const _HospitalCard({
    required this.hospital,
    required this.rank,
    required this.sortBy,
    required this.selectedCity,
  });

  @override
  Widget build(BuildContext context) {
    final beds = hospital['beds'] as Map<String, dynamic>? ?? {};
    final generalBeds = (beds['general'] as int?) ?? 0;
    final icuBeds = (beds['icu'] as int?) ?? 0;
    final queue = (hospital['queue'] as int?) ?? 0;
    final rating = (hospital['rating'] as num?)?.toDouble() ?? 0.0;
    final specialties = hospital['specialties'] as List? ?? [];

    final queueColor = queue < 10
        ? const Color(0xFF2E7D32)
        : queue < 20
            ? const Color(0xFFF57C00)
            : const Color(0xFFC62828);

    final bedsTotal = generalBeds + icuBeds;
    final bedsColor = bedsTotal > 10
        ? const Color(0xFF2E7D32)
        : bedsTotal > 5
            ? const Color(0xFFF57C00)
            : const Color(0xFFC62828);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HospitalDetailScreen(
            hospital: hospital,
            city: selectedCity,
          ),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank + icon
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2B4E).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Color(0xFF0D2B4E),
                        size: 24,
                      ),
                    ),
                    if (rank == 0)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC107),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded,
                            size: 11, color: Colors.white),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hospital['name'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          // Rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 4),
                      // Address
                      Text(
                        hospital['address'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888888)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Distance
                      Row(
                        children: [
                          const Icon(Icons.directions_walk_rounded,
                              size: 13, color: Color(0xFF1565C0)),
                          const SizedBox(width: 3),
                          Text(
                            hospital['distance'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.phone_rounded,
                              size: 13, color: Color(0xFF888888)),
                          const SizedBox(width: 3),
                          Text(
                            hospital['phone'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Specialties ───────────────────────────────────────────────────
          if (specialties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: specialties.take(3).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2B4E).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0D2B4E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Stats row ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border(
                top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1), width: 1),
              ),
            ),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.people_alt_rounded,
                  label: 'Queue',
                  value: '$queue',
                  color: queueColor,
                  highlight: sortBy == SortBy.queue,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.bed_rounded,
                  label: 'General',
                  value: '$generalBeds beds',
                  color: bedsColor,
                  highlight: sortBy == SortBy.availability,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.monitor_heart_rounded,
                  label: 'ICU',
                  value: '$icuBeds beds',
                  color: const Color(0xFF6A1B9A),
                  highlight: sortBy == SortBy.availability,
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool highlight;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: highlight
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: highlight
              ? Border.all(color: color.withValues(alpha: 0.4), width: 1.2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String city;
  final bool hasSearch;

  const _EmptyState({required this.city, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_rounded
                : Icons.local_hospital_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No hospitals match your search'
                : city.isEmpty
                    ? 'No city selected'
                    : 'No hospital data for $city yet',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try searching by name or specialty'
                : 'Hospital data will be added soon',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
