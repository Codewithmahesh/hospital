import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hospital/firebase_options.dart';
import 'package:hospital/app.dart';
import 'package:hospital/services/city_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());

  CityDataService.seedInitialCities().catchError((error) {
    debugPrint('City seeding failed: $error');
  });
}
