import 'package:flutter/material.dart';

class CitySearchWidget extends StatefulWidget {
  final List<String> cities;

  const CitySearchWidget({super.key, required this.cities});

  @override
  State<CitySearchWidget> createState() => _CitySearchWidgetState();
}

class _CitySearchWidgetState extends State<CitySearchWidget> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔍 Custom Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 90, 11, 11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                query = value;
              });
            },
            decoration: const InputDecoration(
              icon: Icon(Icons.search),
              hintText: "Search for your city",
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 📍 Auto Detect Location
        GestureDetector(
          onTap: () {
            // future: location logic
            debugPrint("Detecting location...");
          },
          child: Row(
            children: const [
              Icon(Icons.my_location, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Auto Detect My Location",
                style: TextStyle(
                  color: Color.fromARGB(255, 253, 80, 68),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
