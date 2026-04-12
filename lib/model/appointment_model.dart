import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String uid;
  final String hospitalName;
  final String city;
  final String specialty;
  final String visitType; // 'Consultation', 'Emergency', 'Follow-Up'
  final DateTime scheduledDate;
  final String scheduledTime;
  final String patientName;
  final String patientPhone;
  final String status; // 'upcoming', 'completed', 'cancelled'
  final Timestamp createdAt;

  const AppointmentModel({
    required this.id,
    required this.uid,
    required this.hospitalName,
    required this.city,
    required this.specialty,
    required this.visitType,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.patientName,
    required this.patientPhone,
    required this.status,
    required this.createdAt,
  });

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentModel(
      id: id,
      uid: map['uid'] as String? ?? '',
      hospitalName: map['hospitalName'] as String? ?? '',
      city: map['city'] as String? ?? '',
      specialty: map['specialty'] as String? ?? '',
      visitType: map['visitType'] as String? ?? 'Consultation',
      scheduledDate:
          (map['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledTime: map['scheduledTime'] as String? ?? '',
      patientName: map['patientName'] as String? ?? '',
      patientPhone: map['patientPhone'] as String? ?? '',
      status: map['status'] as String? ?? 'upcoming',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'hospitalName': hospitalName,
      'city': city,
      'specialty': specialty,
      'visitType': visitType,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTime': scheduledTime,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
