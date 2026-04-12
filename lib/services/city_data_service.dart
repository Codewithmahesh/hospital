import 'package:cloud_firestore/cloud_firestore.dart';

class CityDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Static list (original 10 seeded cities) ───────────────────────────────
  // Used internally for fuzzy-matching GPS results.
  static List<String> getStaticCities() {
    return [
      "Mumbai",
      "Delhi",
      "Bengaluru",
      "Hyderabad",
      "Chandigarh",
      "Ahmedabad",
      "Pune",
      "Chennai",
      "Kolkata",
      "Kochi",
    ];
  }

  // ── Seed Firestore with initial cities (call once on first app setup) ─────
  static Future<void> seedInitialCities() async {
    final seededCities = {
      "Mumbai":     {"lat": 19.0760, "lng": 72.8777},
      "Delhi":      {"lat": 28.6139, "lng": 77.2090},
      "Bengaluru":  {"lat": 12.9716, "lng": 77.5946},
      "Hyderabad":  {"lat": 17.3850, "lng": 78.4867},
      "Chandigarh": {"lat": 30.7333, "lng": 76.7794},
      "Ahmedabad":  {"lat": 23.0225, "lng": 72.5714},
      "Pune":       {"lat": 18.5204, "lng": 73.8567},
      "Chennai":    {"lat": 13.0827, "lng": 80.2707},
      "Kolkata":    {"lat": 22.5726, "lng": 88.3639},
      "Kochi":      {"lat": 9.9312,  "lng": 76.2673},
    };

    final batch = _db.batch();
    for (final entry in seededCities.entries) {
      final ref = _db.collection('cities').doc(entry.key);
      final snap = await ref.get();
      if (!snap.exists) {
        batch.set(ref, {
          'name': entry.key,
          'lat': entry.value['lat'],
          'lng': entry.value['lng'],
          'isSeeded': true,
          'isUserDetected': false,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  // ── Fetch all cities from Firestore (static + user-detected) ─────────────
  static Future<List<String>> getCitiesFromFirestore() async {
    try {
      final snap = await _db.collection('cities').orderBy('name').get();
      return snap.docs.map((d) => d.data()['name'] as String).toList();
    } catch (_) {
      // Fallback to static list if Firestore unreachable
      return getStaticCities();
    }
  }

  // ── Real-time stream of cities ─────────────────────────────────────────────
  static Stream<List<String>> citiesStream() {
    return _db
        .collection('cities')
        .orderBy('name')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()['name'] as String).toList());
  }
}
