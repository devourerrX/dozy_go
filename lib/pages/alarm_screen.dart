import "package:flutter/material.dart";
import "package:latlong2/latlong.dart";

class AlarmScreen extends StatefulWidget {
  final LatLng destination;
  const AlarmScreen({required this.destination, super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  double selectedDistance = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Alarm")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "When should we wake you?",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),

            DropdownButton<double>(
              value: selectedDistance,
              items: const [
                DropdownMenuItem(value: 200, child: Text("200 meters")),
                DropdownMenuItem(value: 500, child: Text("500 meters")),
                DropdownMenuItem(value: 1000, child: Text("1km")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedDistance = value!;
                });
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                print(
                  "Alarm set for $selectedDistance meters before destination",
                );
                Navigator.pop(context , selectedDistance);
              },
              child: Text("Start Journey"),
            ),
          ],
        ),
      ),
    );
  }
}
