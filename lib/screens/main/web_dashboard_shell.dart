import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dummy_data_services.dart';
import '../hospital/hospital_detail_screen.dart';
import '../appointments/appointments_screen.dart';
import '../city/city_selection_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens (mirrors web_home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF060E1E);
  static const surface = Color(0xFF0D1B2E);
  static const card = Color(0xFF111C30);
  static const sidebarW = 240.0;
  static const primary = Color(0xFF1E88E5);
  static const primaryLight = Color(0xFF42A5F5);
  static const accent = Color(0xFF00BCD4);
  static const accentGreen = Color(0xFF00E5A0);
  static const textPrimary = Color(0xFFEEF2FF);
  static const textSecondary = Color(0xFF8CA0BE);
  static const border = Color(0x1AFFFFFF);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Nav item model
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = [
  _NavItem(Icons.dashboard_rounded, 'Dashboard'),
  _NavItem(Icons.local_hospital_rounded, 'Hospitals'),
  _NavItem(Icons.calendar_month_rounded, 'Appointments'),
  _NavItem(Icons.person_rounded, 'Profile'),
];

// ─────────────────────────────────────────────────────────────────────────────
//  WebDashboardShell
// ─────────────────────────────────────────────────────────────────────────────
class WebDashboardShell extends StatefulWidget {
  final String selectedCity;
  const WebDashboardShell({super.key, required this.selectedCity});

  @override
  State<WebDashboardShell> createState() => _WebDashboardShellState();
}

class _WebDashboardShellState extends State<WebDashboardShell> {
  int _navIndex = 0;
  late String _currentCity;
  UserModel? _user;
  bool _userLoading = true;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _currentCity = widget.selectedCity;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await AuthService.getUserData(uid);
    if (mounted) setState(() { _user = user; _userLoading = false; });
  }

  void _onCityChanged(String city) =>
      setState(() { _currentCity = city; _navIndex = 0; });

  Widget get _content {
    switch (_navIndex) {
      case 0:
        return _WebHospitalDashboard(city: _currentCity);
      case 1:
        return _WebHospitalSearch(city: _currentCity);
      case 2:
        return const _WebAppointmentsWrapper();
      case 3:
        return _WebProfile(
          user: _user,
          loading: _userLoading,
          city: _currentCity,
          onCityChanged: _onCityChanged,
        );
      default:
        return _WebHospitalDashboard(city: _currentCity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 900;

    return Scaffold(
      backgroundColor: _C.bg,
      // Mobile-compact: use drawer instead of sidebar
      drawer: compact ? _buildSidebarContent(isDrawer: true) : null,
      body: Row(
        children: [
          // ── Sidebar (desktop only) ─────────────────────────────────────────
          if (!compact)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _sidebarCollapsed ? 68 : _C.sidebarW,
              child: _buildSidebarContent(isDrawer: false),
            ),

          // ── Main area ──────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top header
                _buildTopHeader(compact),
                // Content
                Expanded(child: _content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar ──────────────────────────────────────────────────────────────
  Widget _buildSidebarContent({required bool isDrawer}) {
    return Container(
      height: double.infinity,
      color: _C.surface,
      child: Column(
        children: [
          // Logo
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(
                horizontal: _sidebarCollapsed && !isDrawer ? 16 : 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.primary, _C.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 18),
                ),
                if (!_sidebarCollapsed || isDrawer) ...[
                  const SizedBox(width: 10),
                  const Text('SmartCare',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _C.textPrimary,
                          letterSpacing: 0.2)),
                ],
                if (!isDrawer) const Spacer(),
                if (!isDrawer)
                  IconButton(
                    onPressed: () =>
                        setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                    icon: Icon(
                      _sidebarCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      color: _C.textSecondary,
                      size: 20,
                    ),
                    tooltip:
                        _sidebarCollapsed ? 'Expand' : 'Collapse',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: _navItems.asMap().entries.map((e) {
                final isActive = _navIndex == e.key;
                return _SidebarNavItem(
                  item: e.value,
                  isActive: isActive,
                  collapsed: _sidebarCollapsed && !isDrawer,
                  onTap: () {
                    setState(() => _navIndex = e.key);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),

          // Logout at bottom
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _C.border))),
            child: _SidebarNavItem(
              item: const _NavItem(Icons.logout_rounded, 'Sign Out'),
              isActive: false,
              collapsed: _sidebarCollapsed && !isDrawer,
              isLogout: true,
              onTap: () async {
                if (isDrawer) Navigator.of(context).pop();
                await AuthService.logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top header ───────────────────────────────────────────────────────────
  Widget _buildTopHeader(bool compact) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          // Hamburger on compact
          if (compact) ...[
            Builder(
              builder: (ctx) => IconButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: _C.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            // Logo text on compact
            const Text('SmartCare',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrimary)),
          ],

          // Page title
          if (!compact)
            Text(
              _navItems[_navIndex].label,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary),
            ),

          const Spacer(),

          // City selector chip
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CitySelectionScreen(
                      onCitySelected: _onCityChanged),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: _C.primaryLight),
                  const SizedBox(width: 5),
                  Text(_currentCity,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: _C.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
          if (!_userLoading)
            _UserAvatar(user: _user, onTap: () => setState(() => _navIndex = 3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sidebar nav item
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final bool collapsed;
  final bool isLogout;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isLogout ? Colors.redAccent : _C.primaryLight;
    final bg = widget.isActive
        ? _C.primary.withValues(alpha: 0.15)
        : _hovered
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.collapsed ? widget.item.label : '',
          preferBelow: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            padding: EdgeInsets.symmetric(
                horizontal: widget.collapsed ? 0 : 12, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: widget.isActive
                  ? Border.all(
                      color: _C.primary.withValues(alpha: 0.35), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // Active indicator bar
                if (!widget.collapsed && widget.isActive)
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _C.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Icon(widget.item.icon,
                    size: 20,
                    color: widget.isActive || _hovered
                        ? activeColor
                        : _C.textSecondary),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    widget.item.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: widget.isActive || _hovered
                            ? activeColor
                            : _C.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  User avatar button
// ─────────────────────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onTap;
  const _UserAvatar({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : '?';
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: user?.name ?? 'Profile',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_C.primary, _C.accent]),
            shape: BoxShape.circle,
            border: Border.all(
                color: _C.primary.withValues(alpha: 0.4), width: 2),
          ),
          child: Center(
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tab 0 — Hospital Dashboard
// ─────────────────────────────────────────────────────────────────────────────
class _WebHospitalDashboard extends StatefulWidget {
  final String city;
  const _WebHospitalDashboard({required this.city});

  @override
  State<_WebHospitalDashboard> createState() => _WebHospitalDashboardState();
}

class _WebHospitalDashboardState extends State<_WebHospitalDashboard> {
  String _search = '';
  String _sortBy = 'smart'; // smart | distance | queue | beds
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _hospitals {
    final all = DummyDataService.getHospitalsByCity()[widget.city] ?? [];
    var list = _search.isEmpty
        ? all
        : all.where((h) {
            final n = (h['name'] as String).toLowerCase();
            final s = (h['specialties'] as List)
                .join(' ')
                .toLowerCase();
            return n.contains(_search) || s.contains(_search);
          }).toList();

    switch (_sortBy) {
      case 'distance':
        list.sort((a, b) =>
            (a['distanceKm'] as num).compareTo(b['distanceKm'] as num));
      case 'queue':
        list.sort((a, b) =>
            (a['queue'] as int).compareTo(b['queue'] as int));
      case 'beds':
        list.sort((a, b) {
          final bA = _beds(a);
          final bB = _beds(b);
          return bB.compareTo(bA); // more beds first
        });
      default: // smart
        list.sort((a, b) => _smartScore(a).compareTo(_smartScore(b)));
    }
    return list;
  }

  int _beds(Map h) {
    final b = h['beds'] as Map? ?? {};
    return ((b['general'] as int?) ?? 0) + ((b['icu'] as int?) ?? 0);
  }

  double _smartScore(Map h) {
    final d = (h['distanceKm'] as num).toDouble();
    final q = (h['queue'] as int).toDouble();
    final b = _beds(h);
    return d * 0.4 + q * 0.35 + (b > 0 ? 20 / b : 20) * 0.25;
  }

  @override
  Widget build(BuildContext context) {
    final hospitals = _hospitals;
    final w = MediaQuery.of(context).size.width;
    final cols = w > 1400 ? 3 : w > 1000 ? 2 : 1;

    return Container(
      color: _C.bg,
      child: Column(
        children: [
          // ── Stats strip ──────────────────────────────────────────────────
          _buildStatsStrip(hospitals),

          // ── Toolbar ──────────────────────────────────────────────────────
          _buildToolbar(),

          // ── Grid ─────────────────────────────────────────────────────────
          Expanded(
            child: hospitals.isEmpty
                ? _emptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: 1.55,
                    ),
                    itemCount: hospitals.length,
                    itemBuilder: (_, i) => _WebHospCard(
                      hospital: hospitals[i],
                      rank: i,
                      city: widget.city,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(List<Map<String, dynamic>> hospitals) {
    final totalBeds = hospitals.fold<int>(
        0, (s, h) => s + _beds(h));
    final avgQueue = hospitals.isEmpty
        ? 0
        : (hospitals.fold<int>(0, (s, h) => s + (h['queue'] as int)) /
                hospitals.length)
            .round();
    final avgRating = hospitals.isEmpty
        ? 0.0
        : hospitals.fold<double>(
                0, (s, h) => s + (h['rating'] as num).toDouble()) /
            hospitals.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          _DashStat(
              label: 'Hospitals in ${widget.city}',
              value: '${hospitals.length}',
              icon: Icons.local_hospital_rounded,
              color: _C.primaryLight),
          const SizedBox(width: 14),
          _DashStat(
              label: 'Total Available Beds',
              value: '$totalBeds',
              icon: Icons.bed_rounded,
              color: _C.accentGreen),
          const SizedBox(width: 14),
          _DashStat(
              label: 'Avg. Queue',
              value: '$avgQueue patients',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFFFF8A65)),
          const SizedBox(width: 14),
          _DashStat(
              label: 'Avg. Rating',
              value: avgRating.toStringAsFixed(1),
              icon: Icons.star_rounded,
              color: const Color(0xFFFFC107)),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final sorts = {
      'smart': ('Auto Sort', Icons.auto_awesome_rounded),
      'distance': ('Distance', Icons.directions_walk_rounded),
      'queue': ('Queue', Icons.people_alt_rounded),
      'beds': ('Availability', Icons.bed_rounded),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(
                    color: _C.textPrimary, fontSize: 14),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search hospital or specialty…',
                  hintStyle: const TextStyle(
                      color: _C.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _C.textSecondary, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              size: 16, color: _C.textSecondary),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Sort chips
          ...sorts.entries.map((e) {
            final active = _sortBy == e.key;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _SortChip(
                label: e.value.$1,
                icon: e.value.$2,
                active: active,
                onTap: () => setState(() => _sortBy = e.key),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: _C.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('No hospitals found',
              style: TextStyle(
                  fontSize: 18,
                  color: _C.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Try changing your search query',
              style:
                  TextStyle(fontSize: 13, color: _C.textSecondary)),
        ],
      ),
    );
  }
}

// ── Dashboard stat card ────────────────────────────────────────────────────
class _DashStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _DashStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: color.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _C.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sort chip ──────────────────────────────────────────────────────────────
class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? _C.primary.withValues(alpha: 0.2)
              : _C.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? _C.primary : _C.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? _C.primaryLight : _C.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? _C.primaryLight
                        : _C.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hospital grid card (web-optimised wide card)
// ─────────────────────────────────────────────────────────────────────────────
class _WebHospCard extends StatefulWidget {
  final Map<String, dynamic> hospital;
  final int rank;
  final String city;
  const _WebHospCard(
      {required this.hospital, required this.rank, required this.city});

  @override
  State<_WebHospCard> createState() => _WebHospCardState();
}

class _WebHospCardState extends State<_WebHospCard> {
  bool _hovered = false;

  Color get _accentColor {
    final colors = [
      _C.primary,
      _C.accentGreen,
      const Color(0xFF8C67EF),
      const Color(0xFFFF8A65),
      _C.accent,
    ];
    return colors[widget.rank % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hospital;
    final beds = h['beds'] as Map? ?? {};
    final general = (beds['general'] as int?) ?? 0;
    final icu = (beds['icu'] as int?) ?? 0;
    final queue = (h['queue'] as int?) ?? 0;
    final rating = (h['rating'] as num?)?.toDouble() ?? 0.0;
    final specs = h['specialties'] as List? ?? [];
    final ac = _accentColor;

    final queueColor = queue < 10
        ? _C.accentGreen
        : queue < 20
            ? const Color(0xFFFF8A65)
            : Colors.redAccent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HospitalDetailScreen(hospital: h, city: widget.city),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? ac.withValues(alpha: 0.6)
                  : _C.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: ac.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 8))
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [ac, _C.accent]),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Row 1: icon + name + rating ─────────────────────
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: ac.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color:
                                      ac.withValues(alpha: 0.35)),
                            ),
                            child: Icon(Icons.local_hospital_rounded,
                                color: ac, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(h['name'] as String? ?? '',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _C.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        size: 11,
                                        color: _C.textSecondary),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        (h['address'] as String? ?? ''),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: _C.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                              color: const Color(0xFFFFC107)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 12,
                                    color: Color(0xFFFFC107)),
                                const SizedBox(width: 3),
                                Text(rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFFC107))),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Specialties ──────────────────────────────────────
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: specs.take(3).map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: _C.border),
                            ),
                            child: Text(s.toString(),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _C.textSecondary,
                                    fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                      ),

                      const Spacer(),
                      Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 14),

                      // ── Stats ────────────────────────────────────────────
                      Row(
                        children: [
                          _MiniStat(
                            icon: Icons.people_alt_rounded,
                            value: '$queue',
                            label: 'Queue',
                            color: queueColor,
                          ),
                          const SizedBox(width: 8),
                          _MiniStat(
                            icon: Icons.bed_rounded,
                            value: '$general',
                            label: 'General',
                            color: _C.primaryLight,
                          ),
                          const SizedBox(width: 8),
                          _MiniStat(
                            icon: Icons.monitor_heart_rounded,
                            value: '$icu',
                            label: 'ICU',
                            color: const Color(0xFF8C67EF),
                          ),
                          const SizedBox(width: 8),
                          _MiniStat(
                            icon: Icons.directions_walk_rounded,
                            value: h['distance'] as String? ?? '',
                            label: 'Away',
                            color: _C.textSecondary,
                          ),
                          const Spacer(),
                          // Book button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: _hovered
                                  ? LinearGradient(
                                      colors: [ac, _C.accent])
                                  : LinearGradient(colors: [
                                      ac.withValues(alpha: 0.15),
                                      ac.withValues(alpha: 0.15),
                                    ]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HospitalDetailScreen(
                                      hospital: h,
                                      city: widget.city),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: Text(
                                'Book',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _hovered
                                        ? Colors.white
                                        : ac),
                              ),
                            ),
                          ),
                        ],
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

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tab 1 — Search (reuses hospital search with a wider layout note)
// ─────────────────────────────────────────────────────────────────────────────
class _WebHospitalSearch extends StatefulWidget {
  final String city;
  const _WebHospitalSearch({required this.city});

  @override
  State<_WebHospitalSearch> createState() => _WebHospitalSearchState();
}

class _WebHospitalSearchState extends State<_WebHospitalSearch> {
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final allCities = DummyDataService.getHospitalsByCity();
    final allHospitals = _search.isEmpty
        ? <Map<String, dynamic>>[]
        : allCities.values.expand((list) => list).where((h) {
            final n = (h['name'] as String).toLowerCase();
            final s =
                (h['specialties'] as List).join(' ').toLowerCase();
            return n.contains(_search) || s.contains(_search);
          }).toList();

    return Container(
      color: _C.bg,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: const TextStyle(
                        color: _C.textPrimary, fontSize: 15),
                    onChanged: (v) =>
                        setState(() => _search = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText:
                          'Search hospitals across all cities…',
                      hintStyle: const TextStyle(
                          color: _C.textSecondary, fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _C.primaryLight, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 16,
                                  color: _C.textSecondary),
                              onPressed: () {
                                _ctrl.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_search.isEmpty)
            Expanded(child: _searchPlaceholder())
          else if (allHospitals.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 56,
                        color: _C.textSecondary
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text('No results found',
                        style: TextStyle(
                            fontSize: 18, color: _C.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: allHospitals.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final h = allHospitals[i];
                  return _SearchResultRow(hospital: h);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchPlaceholder() {
    final cats = [
      ('Cardiology', Icons.favorite_rounded, _C.primary),
      ('Orthopedics', Icons.accessibility_new_rounded, _C.accentGreen),
      ('Neurology', Icons.psychology_rounded, const Color(0xFF8C67EF)),
      ('Oncology', Icons.science_rounded, const Color(0xFFFF8A65)),
      ('Pediatrics', Icons.child_care_rounded, _C.accent),
      ('Emergency', Icons.emergency_rounded, Colors.redAccent),
    ];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Browse by Specialty',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: cats.map((c) {
              return GestureDetector(
                onTap: () {
                  _ctrl.text = c.$1.toLowerCase();
                  setState(() => _search = c.$1.toLowerCase());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.$3.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: c.$3.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.$2, size: 18, color: c.$3),
                      const SizedBox(width: 8),
                      Text(c.$1,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.$3)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatefulWidget {
  final Map<String, dynamic> hospital;
  const _SearchResultRow({required this.hospital});

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hospital;
    final beds = h['beds'] as Map? ?? {};
    final total =
        ((beds['general'] as int?) ?? 0) + ((beds['icu'] as int?) ?? 0);
    final queue = (h['queue'] as int?) ?? 0;
    final rating = (h['rating'] as num?)?.toDouble() ?? 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HospitalDetailScreen(
                hospital: h, city: h['address'] ?? ''),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hovered ? _C.card : _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  _hovered ? _C.primary.withValues(alpha: 0.4) : _C.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: _C.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h['name'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary)),
                    Text(h['address'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: _C.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              _MiniStat(
                  icon: Icons.star_rounded,
                  value: rating.toStringAsFixed(1),
                  label: 'Rating',
                  color: const Color(0xFFFFC107)),
              const SizedBox(width: 20),
              _MiniStat(
                  icon: Icons.bed_rounded,
                  value: '$total',
                  label: 'Beds',
                  color: _C.accentGreen),
              const SizedBox(width: 20),
              _MiniStat(
                  icon: Icons.people_alt_rounded,
                  value: '$queue',
                  label: 'Queue',
                  color: queue < 10
                      ? _C.accentGreen
                      : const Color(0xFFFF8A65)),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_C.primary, _C.accent]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('View Details',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tab 2 — Appointments (wrap existing screen with dark theme scaffold)
// ─────────────────────────────────────────────────────────────────────────────
class _WebAppointmentsWrapper extends StatelessWidget {
  const _WebAppointmentsWrapper();

  @override
  Widget build(BuildContext context) {
    // AppointmentsScreen uses its own Scaffold; embed it directly
    return const AppointmentsScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tab 3 — Profile (web layout)
// ─────────────────────────────────────────────────────────────────────────────
class _WebProfile extends StatelessWidget {
  final UserModel? user;
  final bool loading;
  final String city;
  final void Function(String) onCityChanged;

  const _WebProfile({
    required this.user,
    required this.loading,
    required this.city,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + name card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2050), Color(0xFF061630)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.border),
                ),
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: _C.primaryLight, strokeWidth: 2))
                    : Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_C.primary, _C.accent]),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _C.primary.withValues(alpha: 0.4),
                                  width: 3),
                            ),
                            child: Center(
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.name ?? 'User',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: _C.textPrimary)),
                                const SizedBox(height: 4),
                                Text(user?.email ?? '',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: _C.textSecondary)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _C.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color:
                                            _C.primary.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    (user?.role ?? 'patient').toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _C.primaryLight,
                                        letterSpacing: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // City card
              _ProfileCard(
                icon: Icons.location_on_rounded,
                label: 'Current City',
                value: city.isEmpty ? 'Not selected' : city,
                iconColor: _C.accentGreen,
                trailing: TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CitySelectionScreen(
                            onCitySelected: onCityChanged),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded,
                      size: 14, color: _C.primaryLight),
                  label: const Text('Change',
                      style: TextStyle(
                          color: _C.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _ProfileCard(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: user?.email ?? '—',
                iconColor: _C.primaryLight,
              ),

              const Spacer(),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: _C.card,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Sign Out',
                            style: TextStyle(
                                color: _C.textPrimary,
                                fontWeight: FontWeight.w700)),
                        content: const Text(
                            'Are you sure you want to sign out?',
                            style: TextStyle(color: _C.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, false),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: _C.textSecondary)),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) await AuthService.logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(
                        color: Colors.redAccent, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Widget? trailing;

  const _ProfileCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: iconColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: _C.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
