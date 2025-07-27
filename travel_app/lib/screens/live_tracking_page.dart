import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:mon_voyage/models/travel_model.dart'; // Importation du modèle Travel

class LiveTrackingPage extends StatefulWidget {
  final List<Map<String, dynamic>> routePoints;
  final Travel travel; // Ajout du paramètre Travel

  const LiveTrackingPage({super.key, required this.routePoints, required this.travel});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  late GoogleMapController mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  late WebSocketChannel _channel;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setupInitialRoute();
    _startLiveTracking();
    _connectWebSocket();
  }

  @override
  void dispose() {
    // Arrête le suivi GPS lorsque la page est fermée pour économiser la batterie
    _positionStreamSubscription?.cancel();
    _channel.sink.close(); // Ferme la connexion WebSocket
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Centre la carte sur l'ensemble du trajet une fois la carte créée
    mapController.animateCamera(CameraUpdate.newLatLngBounds(
      _boundsFromLatLngList(widget.routePoints.map((p) => p['coords'] as LatLng).toList()),
      100.0,
    ));
  }

  void _setupInitialRoute() {
    final List<LatLng> polylinePoints = [];
    for (var point in widget.routePoints) {
      final latLng = point['coords'] as LatLng;
      final name = point['name'] as String;
      final type = point['type'] as String;

      polylinePoints.add(latLng);

      double hue;
      String title;
      if (type == 'start') {
        hue = BitmapDescriptor.hueGreen;
        title = 'Départ: $name';
      } else if (type == 'end') {
        hue = BitmapDescriptor.hueRed;
        title = 'Arrivée: $name';
      } else {
        hue = BitmapDescriptor.hueAzure;
        title = name;
      }

      _markers.add(Marker(
        markerId: MarkerId(name),
        position: latLng,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ));
    }

    _polylines.add(Polyline(
      polylineId: const PolylineId('full_route'),
      points: polylinePoints,
      color: Colors.blue,
      width: 5,
    ));
  }

  void _startLiveTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour tous les 10 mètres
      ),
    ).listen((Position position) {
      final myLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        // Supprime l'ancien marqueur de position actuelle s'il existe
        _markers.removeWhere((marker) => marker.markerId.value == 'current_position');

        // Ajoute le nouveau marqueur
        _markers.add(Marker(
          markerId: const MarkerId('current_position'),
          position: myLocation,
          infoWindow: const InfoWindow(title: 'Ma Position'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ));
      });

      // Centre la caméra sur la nouvelle position
      mapController.animateCamera(CameraUpdate.newLatLng(myLocation));
    });
  }

  void _connectWebSocket() {
    // Connecte au WebSocket uniquement pour le trajet Yaoundé-Douala
    if ((widget.travel.from == 'Yaoundé' && widget.travel.to == 'Douala') ||
        (widget.travel.from == 'Douala' && widget.travel.to == 'Yaoundé')) {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.100.21:8000/ws/track/test_vehicle_1'), // ID de véhicule de test
      );

      _channel.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['vehicle_id'] == 'test_vehicle_1') {
          final newPosition = LatLng(data['latitude'], data['longitude']);
          setState(() {
            _markers.removeWhere((marker) => marker.markerId.value == 'tracked_vehicle');
            _markers.add(Marker(
              markerId: const MarkerId('tracked_vehicle'),
              position: newPosition,
              infoWindow: const InfoWindow(title: 'Véhicule Suivi'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            ));
          });
          mapController.animateCamera(CameraUpdate.newLatLng(newPosition));
        }
      }, onError: (error) {
        print('Erreur WebSocket: $error');
      }, onDone: () {
        print('WebSocket déconnecté.');
      });
    } else {
      print('Suivi en temps réel non disponible pour ce trajet.');
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi en Temps Réel'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: widget.routePoints.first['coords'] as LatLng,
          zoom: 14.0,
        ),
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}