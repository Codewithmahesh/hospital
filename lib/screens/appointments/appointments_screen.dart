import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../model/appointment_model.dart';
import '../../services/appointment_service.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        automaticallyImplyLeading: false,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: AppointmentService.watchUserAppointments(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return _EmptyAppointments();
          }

          // Split into upcoming and past
          final upcoming = appointments
              .where((a) =>
                  a.status == 'upcoming' &&
                  a.scheduledDate.isAfter(DateTime.now()))
              .toList();
          final past = appointments
              .where((a) =>
                  a.status != 'upcoming' ||
                  a.scheduledDate.isBefore(DateTime.now()))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Upcoming',
                  count: upcoming.length,
                  color: const Color(0xFF1565C0),
                ),
                const SizedBox(height: 10),
                ...upcoming.map((a) => _AppointmentCard(
                      appointment: a,
                      onCancel: () =>
                          _confirmCancel(context, a.id),
                    )),
                const SizedBox(height: 20),
              ],
              if (past.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Past',
                  count: past.length,
                  color: const Color(0xFF888888),
                ),
                const SizedBox(height: 10),
                ...past.map((a) => _AppointmentCard(
                      appointment: a,
                      onCancel: null,
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AppointmentService.cancelAppointment(id);
    }
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onCancel;

  const _AppointmentCard({required this.appointment, required this.onCancel});

  Color get _statusColor {
    switch (appointment.status) {
      case 'upcoming':
        return const Color(0xFF1565C0);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF888888);
    }
  }

  IconData get _statusIcon {
    switch (appointment.status) {
      case 'upcoming':
        return Icons.schedule_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, dd MMM yyyy').format(appointment.scheduledDate);
    final isCancelled = appointment.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCancelled
            ? Colors.grey.shade50
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCancelled
            ? Border.all(color: Colors.grey.shade200)
            : null,
        boxShadow: isCancelled
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon, color: _statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.hospitalName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCancelled
                              ? Colors.grey.shade400
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appointment.city} · ${appointment.specialty}',
                        style: TextStyle(
                            fontSize: 12,
                            color: isCancelled
                                ? Colors.grey.shade400
                                : const Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    appointment.status[0].toUpperCase() +
                        appointment.status.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            Row(
              children: [
                _MetaChip(
                    icon: Icons.calendar_today_rounded,
                    label: dateStr,
                    muted: isCancelled),
                const SizedBox(width: 12),
                _MetaChip(
                    icon: Icons.access_time_rounded,
                    label: appointment.scheduledTime,
                    muted: isCancelled),
                const SizedBox(width: 12),
                _MetaChip(
                    icon: Icons.medical_services_outlined,
                    label: appointment.visitType,
                    muted: isCancelled),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                Text(
                  appointment.patientName,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.phone_outlined,
                    size: 14, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                Text(
                  appointment.patientPhone,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF555555)),
                ),
              ],
            ),

            // Cancel button (only for upcoming)
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined,
                      size: 16, color: Color(0xFFE53935)),
                  label: const Text(
                    'Cancel Appointment',
                    style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    backgroundColor:
                        const Color(0xFFE53935).withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;

  const _MetaChip(
      {required this.icon, required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color: muted ? Colors.grey.shade300 : const Color(0xFF888888)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: muted ? Colors.grey.shade300 : const Color(0xFF555555),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 72, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text(
            'No appointments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Book your first appointment\nfrom a hospital\'s detail page',
            style: TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
