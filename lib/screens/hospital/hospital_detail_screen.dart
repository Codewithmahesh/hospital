import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/appointment_model.dart';
import '../../services/appointment_service.dart';

class HospitalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final String city;

  const HospitalDetailScreen({
    super.key,
    required this.hospital,
    required this.city,
  });

  // ── Bed availability estimate ─────────────────────────────────────────────
  static String _bedWaitTime(Map<String, dynamic> hospital) {
    final beds = hospital['beds'] as Map<String, dynamic>? ?? {};
    final totalBeds =
        ((beds['general'] as int?) ?? 0) + ((beds['icu'] as int?) ?? 0);
    final queue = (hospital['queue'] as int?) ?? 0;

    if (queue < totalBeds) return 'Available Now';
    final waitMins = (queue - totalBeds) * 45;
    if (waitMins < 60) return '~$waitMins min wait';
    final h = waitMins ~/ 60;
    final m = waitMins % 60;
    return m == 0 ? '~${h}h wait' : '~${h}h ${m}m wait';
  }

  static Color _waitColor(Map<String, dynamic> hospital) {
    final beds = hospital['beds'] as Map<String, dynamic>? ?? {};
    final totalBeds =
        ((beds['general'] as int?) ?? 0) + ((beds['icu'] as int?) ?? 0);
    final queue = (hospital['queue'] as int?) ?? 0;
    if (queue < totalBeds) return const Color(0xFF2E7D32);
    if ((queue - totalBeds) * 45 < 60) return const Color(0xFFF57C00);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final beds = hospital['beds'] as Map<String, dynamic>? ?? {};
    final generalBeds = (beds['general'] as int?) ?? 0;
    final icuBeds = (beds['icu'] as int?) ?? 0;
    final queue = (hospital['queue'] as int?) ?? 0;
    final rating = (hospital['rating'] as num?)?.toDouble() ?? 0.0;
    final specialties = hospital['specialties'] as List? ?? [];
    final waitText = _bedWaitTime(hospital);
    final waitColor = _waitColor(hospital);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0A1628),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1628), Color(0xFF0D2B4E), Color(0xFF0B4F6C)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          hospital['name'] as String? ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Color(0xFF64B5F6), size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${hospital['address'] ?? ''}, $city',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFC107), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$rating',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.directions_walk_rounded,
                                color: Color(0xFF64B5F6), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              hospital['distance'] as String? ?? '',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Bed Availability Card ────────────────────────────────────
                _SectionCard(
                  title: 'Bed Availability',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _BedStat(
                            label: 'General Beds',
                            count: generalBeds,
                            icon: Icons.bed_rounded,
                            color: const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 12),
                          _BedStat(
                            label: 'ICU Beds',
                            count: icuBeds,
                            icon: Icons.monitor_heart_rounded,
                            color: const Color(0xFF6A1B9A),
                          ),
                          const SizedBox(width: 12),
                          _BedStat(
                            label: 'In Queue',
                            count: queue,
                            icon: Icons.people_alt_rounded,
                            color: queue < 10
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFF57C00),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: waitColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: waitColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              waitText == 'Available Now'
                                  ? Icons.check_circle_rounded
                                  : Icons.access_time_rounded,
                              color: waitColor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next bed available:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: waitColor.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  waitText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: waitColor,
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

                const SizedBox(height: 12),

                // ── Specialties ──────────────────────────────────────────────
                _SectionCard(
                  title: 'Specialties',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Contact ──────────────────────────────────────────────────
                _SectionCard(
                  title: 'Contact',
                  child: Row(
                    children: [
                      const Icon(Icons.phone_rounded,
                          color: Color(0xFF1565C0), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        hospital['phone'] as String? ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Book Appointment Button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _showBookingSheet(context),
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: const Text(
                      'Book Appointment',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking Bottom Sheet ───────────────────────────────────────────────────
  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(hospital: hospital, city: city),
    );
  }
}

// ── Booking Sheet ─────────────────────────────────────────────────────────────

class _BookingSheet extends StatefulWidget {
  final Map<String, dynamic> hospital;
  final String city;

  const _BookingSheet({required this.hospital, required this.city});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _visitType = 'Consultation';
  String _specialty = '';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _time = '10:00 AM';
  bool _isLoading = false;

  final _times = [
    '09:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '02:00 PM', '03:00 PM',
    '04:00 PM', '05:00 PM',
  ];

  final _visitTypes = ['Consultation', 'Emergency', 'Follow-Up', 'Check-Up'];

  @override
  void initState() {
    super.initState();
    final specialties = widget.hospital['specialties'] as List? ?? [];
    _specialty = specialties.isNotEmpty ? specialties.first.toString() : '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirmBooking() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final appt = AppointmentModel(
        id: '',
        uid: uid,
        hospitalName: widget.hospital['name'] as String? ?? '',
        city: widget.city,
        specialty: _specialty,
        visitType: _visitType,
        scheduledDate: _date,
        scheduledTime: _time,
        patientName: _nameCtrl.text.trim(),
        patientPhone: _phoneCtrl.text.trim(),
        status: 'upcoming',
        createdAt: Timestamp.now(),
      );

      await AppointmentService.bookAppointment(appt);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Appointment booked at ${widget.hospital['name']}!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Booking failed: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final specialties = widget.hospital['specialties'] as List? ?? [];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Book Appointment',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E)),
            ),
            Text(
              widget.hospital['name'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 20),

            // Patient name
            _SheetField(
                controller: _nameCtrl,
                label: 'Patient Name',
                icon: Icons.person_outline),
            const SizedBox(height: 12),

            // Phone
            _SheetField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            // Visit Type
            _DropdownRow(
              label: 'Visit Type',
              value: _visitType,
              items: _visitTypes,
              onChanged: (v) => setState(() => _visitType = v!),
            ),
            const SizedBox(height: 12),

            // Specialty
            if (specialties.isNotEmpty)
              _DropdownRow(
                label: 'Specialty',
                value: _specialty,
                items: specialties.map((s) => s.toString()).toList(),
                onChanged: (v) => setState(() => _specialty = v!),
              ),
            if (specialties.isNotEmpty) const SizedBox(height: 12),

            // Date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  border: Border.all(color: const Color(0xFFE8ECF4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: Color(0xFF1565C0)),
                    const SizedBox(width: 12),
                    Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_outlined,
                        size: 16, color: Color(0xFF888888)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time slots
            const Text('Select Time',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _times.map((t) {
                final isSelected = _time == t;
                return GestureDetector(
                  onTap: () => setState(() => _time = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : const Color(0xFFDDE3F0),
                      ),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF555555),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Confirm Booking',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BedStat extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _BedStat(
      {required this.label,
      required this.count,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const _SheetField(
      {required this.controller,
      required this.label,
      required this.icon,
      this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF888888)),
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?)? onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF888888)),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
