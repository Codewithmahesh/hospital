import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../model/user_model.dart';
import '../city/city_selection_screen.dart';
import '../main/web_dashboard_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF060E1E);
  static const surface = Color(0xFF0D1B2E);
  static const card = Color(0xFF111C30);
  static const primary = Color(0xFF1E88E5);
  static const primaryLight = Color(0xFF42A5F5);
  static const accent = Color(0xFF00BCD4);
  static const accentGreen = Color(0xFF00E5A0);
  static const textPrimary = Color(0xFFEEF2FF);
  static const textSecondary = Color(0xFF8CA0BE);
  static const border = Color(0x1AFFFFFF);
  static const glassWhite = Color(0x0FFFFFFF);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen>
    with TickerProviderStateMixin {
  // ── Scroll & nav ──────────────────────────────────────────────────────────
  final _scrollController = ScrollController();
  bool _scrolled = false;

  // ── Section keys for nav scroll ───────────────────────────────────────────
  final _heroKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _hospitalsKey = GlobalKey();
  final _howKey = GlobalKey();

  // ── Hover states for feature cards ────────────────────────────────────────
  final List<bool> _featureHover = List.filled(6, false);
  final List<bool> _hospitalHover = List.filled(3, false);

  // ── Auth modal state ──────────────────────────────────────────────────────
  bool _showAuthModal = false;
  bool _isLogin = true;
  bool _authLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _authError = '';
  final _authFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _heroAnim;
  late AnimationController _floatAnim;
  late Animation<double> _heroFade;
  late Animation<double> _heroSlide;
  late Animation<double> _floatY;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final s = _scrollController.offset > 40;
      if (s != _scrolled) setState(() => _scrolled = s);
    });

    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _floatAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    _heroFade =
        CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut));
    _floatY = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatAnim, curve: Curves.easeInOut));

    _heroAnim.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAnim.dispose();
    _floatAnim.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _searchCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get _isMobile => MediaQuery.of(context).size.width < 900;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 900 &&
          MediaQuery.of(context).size.width < 1200;

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
  }

  void _openAuth({bool isLogin = true}) {
    setState(() {
      _showAuthModal = true;
      _isLogin = isLogin;
      _authError = '';
    });
  }

  void _closeModal() {
    setState(() {
      _showAuthModal = false;
      _authFormKey.currentState?.reset();
      _authError = '';
      _authLoading = false;
    });
  }

  Future<void> _submitAuth() async {
    if (!(_authFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _authLoading = true;
      _authError = '';
    });
    try {
      if (_isLogin) {
        await AuthService.login(
            email: _emailCtrl.text, password: _passCtrl.text);
      } else {
        await AuthService.signUp(
            name: _nameCtrl.text,
            email: _emailCtrl.text,
            password: _passCtrl.text);
      }
      if (!mounted) return;
      _closeModal();
      // Navigate based on user data
      final uid = AuthService.currentUser!.uid;
      final user = await AuthService.getUserData(uid);
      if (!mounted) return;
      if (user != null && user.city != null && user.city!.isNotEmpty) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => WebDashboardShell(selectedCity: user.city!)));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CitySelectionScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String msg = switch (e.code) {
        'email-already-in-use' => 'Email already registered.',
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'user-not-found' => 'No account with this email.',
        'weak-password' => 'Password must be at least 6 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'network-request-failed' => 'No internet connection.',
        _ => e.message ?? 'Authentication failed.',
      };
      if (mounted) setState(() => _authError = msg);
    } catch (e) {
      if (mounted) setState(() => _authError = e.toString());
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Page content ────────────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SizedBox(height: 70), // space for sticky nav
                _buildHeroSection(),
                _buildSearchSection(),
                _buildFeaturesSection(),
                _buildHowItWorksSection(),
                _buildStatsSection(),
                _buildHospitalsSection(),
                _buildTestimonialsSection(),
                _buildCTASection(),
                _buildFooter(),
              ],
            ),
          ),

          // ── Sticky navbar (always on top) ───────────────────────────────
          Positioned(top: 0, left: 0, right: 0, child: _buildNavbar()),

          // ── Auth modal overlay ──────────────────────────────────────────
          if (_showAuthModal) _buildAuthOverlay(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  NAVBAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNavbar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 70,
      decoration: BoxDecoration(
        color: _scrolled
            ? _C.surface.withValues(alpha: 0.95)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: _scrolled ? _C.border : Colors.transparent,
          ),
        ),
        boxShadow: _scrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                )
              ]
            : [],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: _isMobile ? 20 : 60, vertical: 0),
        child: Row(
          children: [
            _buildLogo(),
            const Spacer(),
            if (!_isMobile) ...[
              _navLink('Features', () => _scrollTo(_featuresKey)),
              _navLink('Hospitals', () => _scrollTo(_hospitalsKey)),
              _navLink('How It Works', () => _scrollTo(_howKey)),
              const SizedBox(width: 24),
            ],
            _buildNavAuthButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_C.primary, _C.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_hospital_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'SmartCare',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.textSecondary)),
      ),
    );
  }

  Widget _buildNavAuthButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isMobile)
          TextButton(
            onPressed: () => _openAuth(isLogin: true),
            child: const Text('Sign In',
                style: TextStyle(
                    color: _C.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        const SizedBox(width: 8),
        _GradientButton(
          label: 'Get Started',
          onTap: () => _openAuth(isLogin: false),
          small: _isMobile,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HERO SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      key: _heroKey,
      width: double.infinity,
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.6),
          radius: 1.4,
          colors: [Color(0xFF102040), _C.bg],
        ),
      ),
      child: Stack(
        children: [
          // Decorative orbs
          Positioned(
              top: 60, right: _isMobile ? -40 : 80,
              child: _Orb(size: 320, color: _C.primary.withValues(alpha: 0.12))),
          Positioned(
              bottom: 40, left: _isMobile ? -60 : 60,
              child: _Orb(size: 240, color: _C.accent.withValues(alpha: 0.08))),

          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: _isMobile ? 24 : 80,
                vertical: _isMobile ? 60 : 90),
            child: _isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _heroContent(true),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _heroContent(false)),
                      ),
                      const SizedBox(width: 60),
                      Expanded(flex: 4, child: _buildHeroCard()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _heroContent(bool isMobile) {
    return [
      FadeTransition(
        opacity: _heroFade,
        child: AnimatedBuilder(
          animation: _heroSlide,
          builder: (_, child) =>
              Transform.translate(offset: Offset(0, _heroSlide.value), child: child),
          child: Column(
            crossAxisAlignment:
                isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.accent.withValues(alpha: 0.15),
                      _C.primary.withValues(alpha: 0.15)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _C.accent.withValues(alpha: 0.35), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: _C.accentGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('India\'s Smartest Hospital Booking',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.accent)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Headline
              Text(
                'Book Appointments\nwith Top Hospitals\nNear You',
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
                style: TextStyle(
                  fontSize: isMobile ? 36 : 52,
                  fontWeight: FontWeight.w900,
                  color: _C.textPrimary,
                  height: 1.18,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),

              // Sub-headline
              Text(
                'Real-time queue status, live bed availability,\nand instant appointment confirmations — all in one place.',
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
                style: const TextStyle(
                    fontSize: 16,
                    color: _C.textSecondary,
                    height: 1.7,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 36),

              // CTAs
              Wrap(
                alignment:
                    isMobile ? WrapAlignment.center : WrapAlignment.start,
                spacing: 16,
                runSpacing: 12,
                children: [
                  _GradientButton(
                    label: 'Book Appointment',
                    onTap: () => _openAuth(isLogin: false),
                    icon: Icons.calendar_today_rounded,
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _scrollTo(_howKey),
                    icon: const Icon(Icons.play_circle_outline_rounded,
                        size: 18, color: _C.textSecondary),
                    label: const Text('How It Works',
                        style: TextStyle(
                            color: _C.textSecondary,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _C.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Trust row
              Wrap(
                spacing: 28,
                runSpacing: 8,
                alignment:
                    isMobile ? WrapAlignment.center : WrapAlignment.start,
                children: [
                  _TrustBadge(
                      icon: Icons.verified_user_rounded,
                      label: '500+ Verified Hospitals'),
                  _TrustBadge(
                      icon: Icons.people_alt_rounded,
                      label: '50,000+ Patients'),
                  _TrustBadge(
                      icon: Icons.star_rounded, label: '4.9 / 5 Rating'),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _floatY,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _floatY.value), child: child),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.18),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: _C.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _C.accentGreen.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: _C.accentGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text('Live Hospital Data',
                      style: TextStyle(
                          color: _C.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Text('Updated 2 min ago',
                      style: TextStyle(
                          color: _C.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hospital rows
            _HospitalRow(
              name: 'City Care Hospital',
              specialty: 'Cardiology',
              queue: 8,
              beds: 24,
              color: _C.primary,
            ),
            const SizedBox(height: 12),
            _HospitalRow(
              name: 'Apollo Medica',
              specialty: 'Orthopedics',
              queue: 3,
              beds: 42,
              color: _C.accentGreen,
            ),
            const SizedBox(height: 12),
            _HospitalRow(
              name: 'Divine Medical',
              specialty: 'Neurology',
              queue: 15,
              beds: 11,
              color: const Color(0xFFFF8A65),
            ),

            const SizedBox(height: 20),
            // Quick book button
            SizedBox(
              width: double.infinity,
              child: _GradientButton(
                  label: 'Find Nearby Hospitals',
                  onTap: () => _openAuth(isLogin: false)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SEARCH SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 24 : 80, vertical: 60),
      color: const Color(0xFF080F1E),
      child: Column(
        children: [
          _SectionLabel(label: 'Search Hospitals'),
          const SizedBox(height: 12),
          const Text(
            'Find the right care, instantly',
            style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
                height: 1.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20))
              ],
            ),
            child: Column(
              children: [
                _isMobile
                    ? Column(children: [
                        _SearchField(
                          controller: _searchCtrl,
                          hint: 'Hospital name or specialty…',
                          icon: Icons.search_rounded,
                        ),
                        const SizedBox(height: 12),
                        _SearchField(
                          controller: _cityCtrl,
                          hint: 'Enter your city',
                          icon: Icons.location_on_rounded,
                        ),
                      ])
                    : Row(children: [
                        Expanded(
                          child: _SearchField(
                            controller: _searchCtrl,
                            hint: 'Hospital name or specialty…',
                            icon: Icons.search_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SearchField(
                            controller: _cityCtrl,
                            hint: 'Enter your city',
                            icon: Icons.location_on_rounded,
                          ),
                        ),
                      ]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _FilterChip(label: 'Available Now', active: true),
                    const SizedBox(width: 10),
                    _FilterChip(label: 'Low Queue'),
                    const SizedBox(width: 10),
                    _FilterChip(label: 'Top Rated'),
                    if (!_isMobile) ...[
                      const Spacer(),
                      _GradientButton(
                          label: 'Search',
                          onTap: () {},
                          icon: Icons.search_rounded),
                    ],
                  ],
                ),
                if (_isMobile) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                      width: double.infinity,
                      child: _GradientButton(
                          label: 'Search Hospitals',
                          onTap: () {},
                          icon: Icons.search_rounded)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FEATURES SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFeaturesSection() {
    final features = [
      _FeatureData(Icons.bolt_rounded, 'Real-Time Updates',
          'Live queue counts, bed availability, and specialist schedules updated every minute.',
          _C.primary, const Color(0xFF1A237E)),
      _FeatureData(Icons.verified_rounded, 'Verified Hospitals',
          'Every listed hospital is NABH accredited and quality verified.',
          _C.accentGreen, const Color(0xFF004D40)),
      _FeatureData(Icons.medical_services_rounded, 'Top Specialists',
          'Browse and book 1000+ doctors across 40+ medical specialties.',
          const Color(0xFFFF8A65), const Color(0xFF4E1F00)),
      _FeatureData(Icons.schedule_rounded, 'Smart Booking',
          'One-tap appointment scheduling with instant e-confirmation.',
          _C.accent, const Color(0xFF004D5A)),
      _FeatureData(Icons.notifications_active_rounded, 'Smart Alerts',
          'Timely reminders so you never miss an appointment again.',
          const Color(0xFFAB47BC), const Color(0xFF1A0027)),
      _FeatureData(Icons.history_edu_rounded, 'Health Records',
          'Maintain a complete digital history of all your medical visits.',
          const Color(0xFF66BB6A), const Color(0xFF002400)),
    ];

    return Container(
      key: _featuresKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 24 : 80, vertical: 80),
      color: _C.bg,
      child: Column(
        children: [
          _SectionLabel(label: 'Why SmartCare'),
          const SizedBox(height: 12),
          const Text(
            'Everything you need for smarter\nhealthcare access',
            style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
                height: 1.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _isMobile ? 1 : (_isTablet ? 2 : 3),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: _isMobile ? 3.5 : 1.05,
            ),
            itemCount: features.length,
            itemBuilder: (_, i) => MouseRegion(
              onEnter: (_) => setState(() => _featureHover[i] = true),
              onExit: (_) => setState(() => _featureHover[i] = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _featureHover[i]
                      ? _C.card.withValues(alpha: 0.95)
                      : _C.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _featureHover[i]
                        ? features[i].color.withValues(alpha: 0.5)
                        : _C.border,
                    width: _featureHover[i] ? 1.5 : 1,
                  ),
                  boxShadow: _featureHover[i]
                      ? [
                          BoxShadow(
                            color: features[i].color.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ]
                      : [],
                ),
                child: _isMobile
                    ? Row(children: [
                        _FeatureIcon(f: features[i]),
                        const SizedBox(width: 20),
                        Expanded(child: _FeatureText(f: features[i]))
                      ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FeatureIcon(f: features[i]),
                          const SizedBox(height: 20),
                          _FeatureText(f: features[i]),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HOW IT WORKS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHowItWorksSection() {
    final steps = [
      ('Search', 'Find hospitals by location, specialty, or queue status.', Icons.search_rounded),
      ('Select', 'Compare hospitals, doctors, reviews and availability.', Icons.compare_arrows_rounded),
      ('Book', 'Pick a date & time slot that suits you and confirm.', Icons.event_available_rounded),
      ('Visit', 'Show your confirmation and get attended without wait.', Icons.check_circle_rounded),
    ];

    return Container(
      key: _howKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 24 : 80, vertical: 80),
      color: const Color(0xFF080F1E),
      child: Column(
        children: [
          _SectionLabel(label: 'How It Works'),
          const SizedBox(height: 12),
          const Text('Four simple steps to better care',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 60),
          _isMobile
              ? Column(
                  children: steps
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _StepCard(
                                number: e.key + 1,
                                title: e.value.$1,
                                desc: e.value.$2,
                                icon: e.value.$3),
                          ))
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.asMap().entries.map((e) {
                    final isLast = e.key == steps.length - 1;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StepCard(
                                number: e.key + 1,
                                title: e.value.$1,
                                desc: e.value.$2,
                                icon: e.value.$3),
                          ),
                          if (!isLast)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 60, top: 32),
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: _C.primary.withValues(alpha: 0.5),
                                  size: 22),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STATS SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 24 : 80, vertical: 70),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2050), Color(0xFF061230)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runSpacing: 36,
        spacing: 40,
        children: const [
          _StatBubble(value: '50K+', label: 'Patients Served', color: _C.primaryLight),
          _StatBubble(value: '500+', label: 'Verified Hospitals', color: _C.accentGreen),
          _StatBubble(value: '1,000+', label: 'Specialist Doctors', color: _C.accent),
          _StatBubble(value: '99.2%', label: 'Satisfaction Rate', color: Color(0xFFFF8A65)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HOSPITALS PREVIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHospitalsSection() {
    final hospitals = [
      _HospitalData('City Care Hospital', 'Mumbai',
          'Cardiology • Oncology • Neurology',
          4.9, 45, 12, '~8 min wait', _C.primary),
      _HospitalData('Apollo Medica Centre', 'Delhi',
          'Orthopedics • ENT • Pediatrics',
          4.8, 32, 5, '~5 min wait', _C.accentGreen),
      _HospitalData('Royal MediShine', 'Bengaluru',
          'Neurology • Urology • Gastro',
          4.7, 58, 20, '~15 min wait', const Color(0xFF8C67EF)),
    ];

    return Container(
      key: _hospitalsKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 24 : 80, vertical: 80),
      color: _C.bg,
      child: Column(
        children: [
          _SectionLabel(label: 'Featured Hospitals'),
          const SizedBox(height: 12),
          const Text('Top-rated hospitals near you',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 50),
          _isMobile || _isTablet
              ? Column(
                  children: hospitals
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _HospitalCard(
                              data: e.value,
                              hovered: _hospitalHover[e.key],
                              onHover: (v) => setState(
                                  () => _hospitalHover[e.key] = v),
                              onTap: () => _openAuth(isLogin: false),
                            ),
                          ))
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: hospitals
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: e.key < hospitals.length - 1 ? 20 : 0),
                              child: _HospitalCard(
                                data: e.value,
                                hovered: _hospitalHover[e.key],
                                onHover: (v) => setState(
                                    () => _hospitalHover[e.key] = v),
                                onTap: () => _openAuth(isLogin: false),
                              ),
                            ),
                          ))
                      .toList(),
                ),
          const SizedBox(height: 36),
          OutlinedButton.icon(
            onPressed: () => _openAuth(isLogin: false),
            icon: const Icon(Icons.local_hospital_rounded, size: 18),
            label: const Text('View All Hospitals'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.primaryLight,
              side: const BorderSide(color: _C.primary, width: 1.5),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TESTIMONIALS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTestimonialsSection() {
    final items = [
      ('SmartCare saved me so much time! I booked an appointment in under 2 minutes and the real-time queue update was spot-on.',
          'Raj Kumar', 'Patient, Mumbai', 'RK'),
      ('The real-time bed availability feature is a game changer. No more calling hospitals and being put on hold.',
          'Priya Sharma', 'Patient, Delhi', 'PS'),
      ('Finally an app that actually works. Clean UI, accurate data, and instant confirmation. Highly recommend!',
          'Amit Patel', 'Patient, Bengaluru', 'AP'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 24 : 80, vertical: 80),
      color: const Color(0xFF080F1E),
      child: Column(
        children: [
          _SectionLabel(label: 'Testimonials'),
          const SizedBox(height: 12),
          const Text('Loved by thousands of patients',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 50),
          _isMobile
              ? Column(
                  children: items
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _TestimonialCard(
                                quote: t.$1, name: t.$2, sub: t.$3, initials: t.$4),
                          ))
                      .toList())
              : Row(
                  children: items.map((t) {
                    final isLast = t == items.last;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 20),
                        child: _TestimonialCard(
                            quote: t.$1, name: t.$2, sub: t.$3, initials: t.$4),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CTA SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCTASection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 32 : 120, vertical: 90),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF0D2A5E), Color(0xFF050C1A)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
              top: 0, left: 0,
              child: _Orb(size: 280, color: _C.primary.withValues(alpha: 0.1))),
          Positioned(
              bottom: 0, right: 0,
              child: _Orb(size: 220, color: _C.accent.withValues(alpha: 0.08))),
          Column(
            children: [
              const Text(
                'Ready to experience smarter\nhealthcare booking?',
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: _C.textPrimary,
                    height: 1.25,
                    letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Join 50,000+ patients who trust SmartCare for their healthcare needs.',
                style: TextStyle(
                    fontSize: 16,
                    color: _C.textSecondary,
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  _GradientButton(
                    label: 'Create Free Account',
                    onTap: () => _openAuth(isLogin: false),
                    icon: Icons.person_add_rounded,
                    large: true,
                  ),
                  OutlinedButton(
                    onPressed: () => _openAuth(isLogin: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.textSecondary,
                      side: const BorderSide(color: _C.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FOOTER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final quickLinks = ['Search Hospitals', 'Book Appointment', 'My Profile', 'How It Works'];
    final legal = ['Privacy Policy', 'Terms of Service', 'Cookie Policy'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 24 : 80, vertical: 56),
      color: const Color(0xFF040912),
      child: Column(
        children: [
          _isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _footerBrand(),
                    const SizedBox(height: 32),
                    _footerColumn('Quick Links', quickLinks),
                    const SizedBox(height: 24),
                    _footerColumn('Legal', legal),
                    const SizedBox(height: 24),
                    _footerContact(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _footerBrand()),
                    Expanded(child: _footerColumn('Quick Links', quickLinks)),
                    Expanded(child: _footerColumn('Legal', legal)),
                    Expanded(child: _footerContact()),
                  ],
                ),
          const SizedBox(height: 40),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('© 2025 SmartCare. All rights reserved.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4))),
              Text('Built with ❤️ in India',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLogo(),
        const SizedBox(height: 16),
        const Text(
          'Your trusted healthcare partner for\nfinding and booking appointments.',
          style: TextStyle(
              fontSize: 13,
              color: _C.textSecondary,
              height: 1.7),
        ),
      ],
    );
  }

  Widget _footerColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary)),
        const SizedBox(height: 14),
        ...items.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(link,
                  style: const TextStyle(
                      fontSize: 13, color: _C.textSecondary)),
            )),
      ],
    );
  }

  Widget _footerContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary)),
        const SizedBox(height: 14),
        _footerContactRow(Icons.email_outlined, 'support@smartcare.in'),
        const SizedBox(height: 10),
        _footerContactRow(Icons.phone_outlined, '+91 1800-SMARTCARE'),
        const SizedBox(height: 10),
        _footerContactRow(Icons.access_time_rounded, 'Available 24 / 7'),
      ],
    );
  }

  Widget _footerContactRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _C.textSecondary),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 13, color: _C.textSecondary)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  AUTH MODAL OVERLAY
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAuthOverlay() {
    return GestureDetector(
      onTap: _closeModal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent tap-through
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: _isMobile
                    ? MediaQuery.of(context).size.width * 0.95
                    : 460,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _C.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 60,
                      offset: const Offset(0, 30),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Close + logo row
                      Row(
                        children: [
                          _buildLogo(),
                          const Spacer(),
                          IconButton(
                            onPressed: _closeModal,
                            icon: const Icon(Icons.close_rounded,
                                color: _C.textSecondary),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        _isLogin ? 'Welcome back 👋' : 'Create your account',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _C.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin
                            ? 'Sign in to manage your appointments'
                            : 'Join SmartCare — it\'s completely free',
                        style: const TextStyle(
                            fontSize: 14, color: _C.textSecondary),
                      ),
                      const SizedBox(height: 28),

                      // Form
                      Form(
                        key: _authFormKey,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              _AuthField(
                                controller: _nameCtrl,
                                label: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter your name'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                            ],
                            _AuthField(
                              controller: _emailCtrl,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your email';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _AuthField(
                              controller: _passCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePass,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: _C.textSecondary,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Minimum 6 characters'
                                  : null,
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 14),
                              _AuthField(
                                controller: _confirmPassCtrl,
                                label: 'Confirm Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscureConfirm,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: _C.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                                validator: (v) =>
                                    v != _passCtrl.text
                                        ? 'Passwords do not match'
                                        : null,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Error message
                      if (_authError.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 16, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_authError,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _authLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_C.primary, _C.accent],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white),
                                  ),
                                ),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_C.primary, _C.accent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: _submitAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Switch mode
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: const TextStyle(
                                  color: _C.textSecondary, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _isLogin = !_isLogin;
                                _authError = '';
                                _authFormKey.currentState?.reset();
                              }),
                              child: Text(
                                _isLogin ? 'Register' : 'Sign In',
                                style: const TextStyle(
                                  color: _C.primaryLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.primary.withValues(alpha: 0.15),
            _C.accent.withValues(alpha: 0.15)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _C.primaryLight,
            letterSpacing: 1.5),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool small;
  final bool large;

  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.small = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_C.primary, _C.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icon != null
            ? Icon(icon, size: small ? 14 : 18)
            : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
              horizontal: small ? 16 : (large ? 32 : 22),
              vertical: small ? 10 : (large ? 16 : 14)),
          textStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: small ? 13 : (large ? 16 : 15),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _C.accentGreen),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: _C.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Hero card sub-widget ───────────────────────────────────────────────────
class _HospitalRow extends StatelessWidget {
  final String name;
  final String specialty;
  final int queue;
  final int beds;
  final Color color;

  const _HospitalRow({
    required this.name,
    required this.specialty,
    required this.queue,
    required this.beds,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary)),
                Text(specialty,
                    style: const TextStyle(
                        fontSize: 11, color: _C.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Queue: $queue',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: queue > 10 ? Colors.orange : _C.accentGreen)),
              Text('Beds: $beds',
                  style: const TextStyle(
                      fontSize: 11, color: _C.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Search field ───────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _C.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: _C.primaryLight, size: 20),
        filled: true,
        fillColor: _C.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────
class _FilterChip extends StatefulWidget {
  final String label;
  final bool active;
  const _FilterChip({required this.label, this.active = false});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  late bool _active;

  @override
  void initState() {
    super.initState();
    _active = widget.active;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _active = !_active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _active
              ? _C.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _active ? _C.primary : _C.border,
            width: 1.5,
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _active ? _C.primaryLight : _C.textSecondary),
        ),
      ),
    );
  }
}

// ── Feature data model ─────────────────────────────────────────────────────
class _FeatureData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final Color bgColor;
  const _FeatureData(this.icon, this.title, this.desc, this.color, this.bgColor);
}

class _FeatureIcon extends StatelessWidget {
  final _FeatureData f;
  const _FeatureIcon({required this.f});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: f.bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: f.color.withValues(alpha: 0.3)),
      ),
      child: Icon(f.icon, size: 26, color: f.color),
    );
  }
}

class _FeatureText extends StatelessWidget {
  final _FeatureData f;
  const _FeatureText({required this.f});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(f.title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary)),
        const SizedBox(height: 6),
        Text(f.desc,
            style: const TextStyle(
                fontSize: 13, color: _C.textSecondary, height: 1.6)),
      ],
    );
  }
}

// ── Step card ──────────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String desc;
  final IconData icon;

  const _StepCard({
    required this.number,
    required this.title,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_C.primary, _C.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                    color: _C.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.primary, width: 1.5)),
                child: Center(
                  child: Text('$number',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _C.primaryLight)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(
                  fontSize: 12, color: _C.textSecondary, height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Stats bubble ───────────────────────────────────────────────────────────
class _StatBubble extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBubble(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1)),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                color: _C.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Hospital data model ────────────────────────────────────────────────────
class _HospitalData {
  final String name;
  final String city;
  final String specialties;
  final double rating;
  final int beds;
  final int queue;
  final String waitTime;
  final Color accentColor;

  const _HospitalData(this.name, this.city, this.specialties, this.rating,
      this.beds, this.queue, this.waitTime, this.accentColor);
}

class _HospitalCard extends StatelessWidget {
  final _HospitalData data;
  final bool hovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  const _HospitalCard({
    required this.data,
    required this.hovered,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hovered
                ? data.accentColor.withValues(alpha: 0.5)
                : _C.border,
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                      color: data.accentColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10))
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color accent top bar
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [data.accentColor, _C.accent]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital icon + name
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: data.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: data.accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.local_hospital_rounded,
                            color: data.accentColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textPrimary)),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 12, color: _C.textSecondary),
                                const SizedBox(width: 3),
                                Text(data.city,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _C.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Rating
                  Row(
                    children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                                i < data.rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: const Color(0xFFFFC107),
                              )),
                      const SizedBox(width: 6),
                      Text('${data.rating}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Specialties
                  Text(data.specialties,
                      style: const TextStyle(
                          fontSize: 12, color: _C.textSecondary)),
                  const SizedBox(height: 16),

                  Divider(color: Colors.white.withValues(alpha: 0.06)),
                  const SizedBox(height: 14),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HospCardStat('Beds', '${data.beds}', Icons.bed_rounded,
                          _C.accentGreen),
                      _HospCardStat(
                          'Queue',
                          '${data.queue}',
                          Icons.people_alt_rounded,
                          data.queue > 10
                              ? Colors.orange
                              : _C.accentGreen),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _C.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _C.accentGreen.withValues(alpha: 0.3)),
                        ),
                        child: Text(data.waitTime,
                            style: const TextStyle(
                                fontSize: 11,
                                color: _C.accentGreen,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hovered
                            ? data.accentColor
                            : data.accentColor.withValues(alpha: 0.15),
                        foregroundColor:
                            hovered ? Colors.white : data.accentColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('Book Appointment',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HospCardStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HospCardStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: _C.textSecondary)),
      ],
    );
  }
}

// ── Testimonial card ───────────────────────────────────────────────────────
class _TestimonialCard extends StatelessWidget {
  final String quote;
  final String name;
  final String sub;
  final String initials;

  const _TestimonialCard({
    required this.quote,
    required this.name,
    required this.sub,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: List.generate(
                5,
                (_) => const Icon(Icons.star_rounded,
                    color: Color(0xFFFFC107), size: 15)),
          ),
          const SizedBox(height: 14),

          // Quote icon
          const Icon(Icons.format_quote_rounded,
              color: _C.primary, size: 28),
          const SizedBox(height: 8),

          // Quote text
          Text(
            quote,
            style: const TextStyle(
                fontSize: 14,
                color: _C.textSecondary,
                height: 1.65,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),

          // Author
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_C.primary, _C.accent]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, color: _C.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Auth form field ────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _C.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _C.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: _C.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: _C.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _C.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.6)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
