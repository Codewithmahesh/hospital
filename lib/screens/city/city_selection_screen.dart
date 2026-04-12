import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main/main_shell.dart';
import '../../services/city_data_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';

class CitySelectionScreen extends StatefulWidget {
  /// Called when a city is selected (used when coming from Profile → Change City).
  /// If null, navigates to MainShell after selection (first-time flow).
  final void Function(String city)? onCitySelected;

  const CitySelectionScreen({super.key, this.onCitySelected});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  String query = "";
  bool _isDetecting = false;

  // ── Select a city: save to Firestore then navigate ────────────────────────
  Future<void> _selectCity(String city) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await AuthService.updateCity(uid, city);
    }

    if (!mounted) return;

    if (widget.onCitySelected != null) {
      widget.onCitySelected!(city);
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainShell(selectedCity: city)),
      );
    }
  }

  // ── Auto Detect via GPS ───────────────────────────────────────────────────
  Future<void> _autoDetectCity() async {
    setState(() => _isDetecting = true);

    final result = await LocationService.detectCity();

    if (!mounted) return;
    setState(() => _isDetecting = false);

    if (result.isSuccess && result.city != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Detected: ${result.city}'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) await _selectCity(result.city!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Could not detect city.'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.onCitySelected != null,
        leading: widget.onCitySelected != null
            ? IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new),
              )
            : null,
        title: const Text(
          "Pick a Region",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search for your city",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📍 Auto Detect
            GestureDetector(
              onTap: _isDetecting ? null : _autoDetectCity,
              child: Row(
                children: [
                  if (_isDetecting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red),
                    )
                  else
                    const Icon(Icons.my_location, color: Colors.red),
                  const SizedBox(width: 10),
                  Text(
                    _isDetecting
                        ? "Detecting your location..."
                        : "Auto Detect My Location",
                    style: TextStyle(
                      color: _isDetecting
                          ? Colors.red.withValues(alpha: 0.6)
                          : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔁 City list — streamed from Firestore
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: CityDataService.citiesStream(),
                builder: (context, snapshot) {
                  // While loading, show static list
                  final cities = snapshot.data ?? CityDataService.getStaticCities();

                  final filteredCities = query.isEmpty
                      ? cities
                      : cities
                          .where((c) =>
                              c.toLowerCase().contains(query.toLowerCase()))
                          .toList();

                  if (query.isNotEmpty) {
                    // 🔍 SEARCH LIST
                    return ListView.builder(
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return ListTile(
                          title: Text(city),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _selectCity(city),
                        );
                      },
                    );
                  }

                  // 🏙️ GRID
                  return GridView.builder(
                    itemCount: filteredCities.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final city = filteredCities[index];
                      return GestureDetector(
                        onTap: () => _selectCity(city),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/${city.toLowerCase()}.png",
                                height: 45,
                                width: 45,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.location_city,
                                  size: 45,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                city,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
