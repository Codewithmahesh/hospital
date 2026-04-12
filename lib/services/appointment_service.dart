import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/appointment_model.dart';

class AppointmentService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'appointments';

  /// Book a new appointment — returns the new document ID.
  static Future<String> bookAppointment(AppointmentModel appt) async {
    final ref = await _db.collection(_col).add(appt.toMap());
    return ref.id;
  }

  /// Real-time stream of all appointments for a user, sorted newest first.
  static Stream<List<AppointmentModel>> watchUserAppointments(String uid) {
    return _db
        .collection(_col)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppointmentModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Cancel an appointment by ID.
  static Future<void> cancelAppointment(String id) async {
    await _db.collection(_col).doc(id).update({'status': 'cancelled'});
  }

  /// Mark an appointment as completed.
  static Future<void> completeAppointment(String id) async {
    await _db.collection(_col).doc(id).update({'status': 'completed'});
  }
}
