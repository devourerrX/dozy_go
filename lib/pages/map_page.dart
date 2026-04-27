import "dart:async";
import "package:audioplayers/audioplayers.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:flutter_map_location_marker/flutter_map_location_marker.dart";
import "package:location/location.dart";
import "package:http/http.dart" as http;
import "dart:convert";
import "package:flutter_polyline_points/flutter_polyline_points.dart";
import "alarm_screen.dart";

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MapController _mapController = MapController();
  final Location _location = Location();
  final Distance _distance = Distance();
  final TextEditingController _locationController = TextEditingController();

  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];

  bool _alarmTriggered = false;
  double? _selectedDistance;

  Timer? _distanceTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();

    // 🔥 Distance check every 2 sec
    _distanceTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkDistanceAndTrigger(),
    );
  }

  void errorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ✅ LOCATION SETUP (FIXED)
  Future<void> _initializeLocation() async {
    try {
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 2000,
        distanceFilter: 5,
      );

      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          errorMessage("Turn on location services");
          return;
        }
      }

      PermissionStatus permission = await _location.hasPermission();

      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }

      if (permission != PermissionStatus.granted) {
        errorMessage("Location permission denied");
        return;
      }

      LocationData locationData = await _location.getLocation();

      if (locationData.latitude == null ||
          locationData.longitude == null) {
        errorMessage("Unable to fetch location");
        return;
      }

      final initialLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      setState(() {
        _currentLocation = initialLocation;
      });

      // 🔥 Move map to real location (IMPORTANT FIX)
      _mapController.move(initialLocation, 15);

      // 🔥 Live updates
      _location.onLocationChanged.listen((LocationData locationData) {
        if (locationData.latitude != null &&
            locationData.longitude != null) {

          final newLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );

          setState(() {
            _currentLocation = newLocation;
          });

          // 🔥 Always update route (FIX)
          if (_destination != null) {
            fetchRoute();
          }
        }
      });
    } catch (e) {
      errorMessage("Failed to get location");
    }
  }

  // ✅ DISTANCE CHECK
  void _checkDistanceAndTrigger() {
    if (_currentLocation != null &&
        _destination != null &&
        _selectedDistance != null &&
        !_alarmTriggered) {

      double distanceInMeters = _distance.as(
        LengthUnit.Meter,
        _currentLocation!,
        _destination!,
      );

      print("Distance: $distanceInMeters");

      if (distanceInMeters <= _selectedDistance!) {
        _triggerAlarm();
        _alarmTriggered = true;
      }
    }
  }

  // ✅ ALARM
  void _triggerAlarm() async {
    await _audioPlayer.play(AssetSource("sound/children.mp3"));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Wake up! You are near your destination"),
      ),
    );
  }

  void _stopAlarm() async {
    await _audioPlayer.stop();
  }

  // ✅ SEARCH LOCATION
  Future<void> _fetchCoordinatesPoints(String location) async {
    try {
      if (_currentLocation == null) {
        errorMessage("Wait for current location...");
        return;
      }

      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(location)}&format=json&limit=1",
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'dozy_go_app'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);

          final dest = LatLng(lat, lon);

          setState(() {
            _destination = dest;
            _route.clear(); // 🔥 Clear old route
          });

          final selectedDistance = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AlarmScreen(destination: dest),
            ),
          );

          if (selectedDistance != null) {
            setState(() {
              _selectedDistance = selectedDistance;
              _alarmTriggered = false;
            });
          }

          _mapController.move(dest, 13);

          await fetchRoute();
        } else {
          errorMessage("Location not found");
        }
      }
    } catch (e) {
      errorMessage("Error occurred");
    }
  }

  // ✅ ROUTE FETCH (HTTPS FIX)
  Future<void> fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;

    final url = Uri.parse(
      "https://router.project-osrm.org/route/v1/driving/"
      "${_currentLocation!.longitude},${_currentLocation!.latitude};"
      "${_destination!.longitude},${_destination!.latitude}"
      "?overview=full&geometries=polyline",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry'];
      _decodePolyline(geometry);
    }
  }

  void _decodePolyline(String encodedPolyline) {
    List<PointLatLng> decodedPoints =
        PolylinePoints.decodePolyline(encodedPolyline);

    setState(() {
      _route = decodedPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    });
  }

  void _userCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16);
    } else {
      errorMessage("Location not ready");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DoziGo Map"),
        backgroundColor: Colors.blue,
      ),

      // 🔥 IMPORTANT FIX (NO DELHI FALLBACK)
      body: (_currentLocation == null)
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation!, // FIXED
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tanmay.dozy_go',
                    ),
                    CurrentLocationLayer(),

                    if (_destination != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _destination!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),

                    if (_route.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _route,
                            strokeWidth: 5,
                            color: Colors.red,
                          ),
                        ],
                      ),
                  ],
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: "Search location",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final text =
                              _locationController.text.trim();
                          if (text.isNotEmpty) {
                            _fetchCoordinatesPoints(text);
                          }
                        },
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
              ],
            ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _userCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _stopAlarm,
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _distanceTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
