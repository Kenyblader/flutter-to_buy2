import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MapScreen());
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterMap Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8dea88),
      ),
      home: const SimpleMapPage(),
    );
  }
}

class SimpleMapPage extends StatefulWidget {
  const SimpleMapPage({Key? key}) : super(key: key);

  @override
  State<SimpleMapPage> createState() => _SimpleMapPageState();
}

class _SimpleMapPageState extends State<SimpleMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;

  // Nouveaux états pour suivre zoom et centre
  LatLng _mapCenter = LatLng(4.05, 9.7);
  double _zoomLevel = 6.0;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location services are disabled. Please enable them.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location permissions are permanently denied.')));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapCenter = _currentPosition!;
        _zoomLevel = 15.0;
        _mapController.move(_mapCenter, _zoomLevel);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _currentPosition == null
        ? <Marker>[]
        : [
            Marker(
              point: _currentPosition!,
              width: 80,
              height: 80,
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('FlutterMap avec Zoom')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _zoomLevel,
              minZoom: 3.0,
              maxZoom: 18.0,
              onPositionChanged: (position, _) {
                setState(() {
                  _mapCenter = position.center!;
                  _zoomLevel = position.zoom!;
                });
              },
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _zoomLevel += 1;
                      _mapController.move(_mapCenter, _zoomLevel);
                    });
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _zoomLevel -= 1;
                      _mapController.move(_mapCenter, _zoomLevel);
                    });
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
