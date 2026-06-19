import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;

  LatLng? currentPosition;
  LatLng? previousPosition;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  List<LatLng> polylineCoordinates = [];

  Timer? timer;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    await Permission.location.request();
    getCurrentLocation();
    startTracking();
  }

  Future<void> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    updateLocation(position);
  }

  void startTracking() {
    timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      updateLocation(position);
    });
  }

  void updateLocation(Position position) {
    previousPosition = currentPosition;

    currentPosition = LatLng(position.latitude, position.longitude);

    polylineCoordinates.add(currentPosition!);

    markers.clear();

    markers.add(
      Marker(
        markerId: const MarkerId("me"),
        position: currentPosition!,
        infoWindow: InfoWindow(
          title: "My current location",
          snippet:
          "Lat: ${position.latitude}, Lng: ${position.longitude}",
        ),
      ),
    );

    polylines.clear();

    polylines.add(
      Polyline(
        polylineId: const PolylineId("track"),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    );

    setState(() {});

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(currentPosition!),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Location Tracker")),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentPosition!,
          zoom: 16,
        ),
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
}