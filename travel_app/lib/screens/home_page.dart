import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/travel_model.dart';
import 'live_tracking_page.dart';
import 'package:mon_voyage/screens/payment_page.dart';
import 'package:mon_voyage/screens/register_screen.dart';
import 'package:mon_voyage/screens/login_screen.dart';
import 'package:mon_voyage/screens/profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentLocation = 'Obtention de la localisation...';
  final TextEditingController _autocompleteController = TextEditingController();
  
  List<Travel> _allTravels = [];
  List<Travel> _foundTravels = [];
  DateTime _selectedDate = DateTime.now(); // Nouvelle variable pour la date
  List<Agency> _agencies = []; // Nouvelle variable pour les agences proches
  
  bool _isLoading = false;
  bool _isDataLoading = true; // Nouvelle variable d'état pour le chargement des données
  String? _currentTripDisplay;
  List<Prediction> _placePredictions = [];

  late GoogleMapController mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  late GoogleMapsPlaces places;

  final LatLng _center = const LatLng(4.0510, 9.7679);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    places = GoogleMapsPlaces(apiKey: "AIzaSyBDot6_jh4E5dCLV3d1lAdBknFfhepAIXU");
    _determinePosition();
    _loadTravelData();
  }

  Future<void> _loadTravelData() async {
    print('Loading data from API...'); // DEBUG
    setState(() {
      _isDataLoading = true;
    });
    try {
      // On simule une recherche initiale pour remplir la liste, par exemple Yaoundé -> Douala
      final response = await http.get(
        Uri.parse('http://192.168.100.21:8000/trajets/?depart=Yaoundé&destination=Douala'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Travel> loadedTravels = (data.map((json) => Travel.fromJson(json)).toList()).cast<Travel>();
        
        setState(() {
          _allTravels = loadedTravels;
          _isDataLoading = false;
        });
        print('Loaded travels count from API: ${loadedTravels.length}');
      } else {
        final error = json.decode(response.body);
        print('Error loading initial data: ${error['detail']}');
        setState(() {
          _isDataLoading = false;
          _currentTripDisplay = "Erreur de chargement des données initiales.";
        });
      }
    } catch (e) {
      print('Error loading data from API: $e');
      setState(() {
        _isDataLoading = false;
        _currentTripDisplay = 'Erreur de connexion au serveur.';
      });
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

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentLocation = 'Les services de localisation sont désactivés.';
      });
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentLocation = 'Les permissions de localisation sont refusées.';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentLocation = 'Les permissions de localisation sont refusées de manière permanente.';
      });
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = 'Yaoundé';
      });
      _fetchNearbyAgencies(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _currentLocation = "Erreur lors de l'obtention de la localisation: $e";
      });
    }
  }

  Future<void> _fetchNearbyAgencies(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.21:8000/agences/proches?latitude=$latitude&longitude=$longitude'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _agencies = data.map((json) => Agency(
            name: json['nom_agence'],
            address: json['adresse'],
            distance: json['distance_km'],
          )).toList();
        });
      } else {
        // Gérer les erreurs de manière appropriée
        print('Erreur de recherche d\'agences: ${response.body}');
      }
    } catch (e) {
      print('Erreur de connexion au serveur: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'), // Pour avoir les jours en français
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _getPlacePredictions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }
    PlacesAutocompleteResponse response = await places.autocomplete(input, language: 'fr', components: [Component(Component.country, 'cm')]);
    if (mounted) {
      setState(() {
        _placePredictions = response.predictions;
      });
    }
  }

  Future<void> _searchTravel() async {
    final String formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    print('Search initiated for: ${_autocompleteController.text} on $formattedDate'); // DEBUG
    if (_autocompleteController.text.isEmpty) {
      print('Search text is empty.'); // DEBUG
      return;
    }

    setState(() {
      _isLoading = true;
      _foundTravels = [];
      _polylines.clear();
      _markers.clear();
      _currentTripDisplay = null;
      _placePredictions = [];
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.21:8000/trajets/?depart=${_currentLocation}&destination=${_autocompleteController.text}&date=$formattedDate'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _foundTravels = (data.map((json) => Travel(
          from: _currentLocation, // La ville de départ est la position actuelle
          to: json['destination'],
          fromLatitude: 3.866667, // Latitude de Yaoundé
          fromLongitude: 11.516667, // Longitude de Yaoundé
          toLatitude: json['latitude'],
          toLongitude: json['longitude'],
          prixVip: json['prix_vip'],
          prixClassique: json['prix_classique'],
          company: json['agence'],
          heureDepart: json['heureDepart'],
          dureeEstimee: json['dureeEstimee'],
          date: _selectedDate,
        )).toList()).cast<Travel>();

        if (_foundTravels.isNotEmpty) {
          // Logique pour afficher la carte et les marqueurs (peut être simplifiée ou adaptée)
          final routePoints = [
            {'name': _currentLocation, 'coords': const LatLng(3.866667, 11.516667), 'type': 'start'},
            {'name': _autocompleteController.text, 'coords': LatLng(_foundTravels.first.toLatitude, _foundTravels.first.toLongitude), 'type': 'end'},
          ];
          final Set<Marker> newMarkers = {};
          final List<LatLng> polylinePoints = [];
          for (var point in routePoints) {
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
            }
            else {
              hue = BitmapDescriptor.hueAzure;
              title = name;
            }
            newMarkers.add(Marker(
              markerId: MarkerId(name),
              position: latLng,
              infoWindow: InfoWindow(title: title),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            ));
          }
          setState(() {
            _currentTripDisplay = '${_currentLocation} -> ${_autocompleteController.text}';
            _markers = newMarkers;
            _polylines.add(Polyline(
              polylineId: const PolylineId('full_route'),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            ));
            mapController.animateCamera(CameraUpdate.newLatLngBounds(
              _boundsFromLatLngList(polylinePoints),
              70.0,
            ));
          });
        } else {
          setState(() {
            _currentTripDisplay = 'Aucun trajet trouvé pour ce jour.';
          });
        }
      } else {
        final error = json.decode(response.body);
        setState(() {
          _currentTripDisplay = 'Erreur de recherche: ${error['detail']}';
        });
      }
    } catch (e) {
      setState(() {
        _currentTripDisplay = 'Erreur de connexion au serveur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToLiveTrackingPage(Travel travel) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.21:8000/trajets/details?depart=${travel.from}&destination=${travel.to}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> polylineCoords = data['details_google_maps']['polyline_coords'];

        final List<Map<String, dynamic>> routePoints = [];
        // Ajouter le point de départ
        routePoints.add({'name': travel.from, 'coords': LatLng(polylineCoords.first[0], polylineCoords.first[1]), 'type': 'start'});

        // Ajouter les points intermédiaires de la polyligne
        for (int i = 1; i < polylineCoords.length - 1; i++) {
          routePoints.add({'name': 'Point intermédiaire', 'coords': LatLng(polylineCoords[i][0], polylineCoords[i][1]), 'type': 'intermediate'});
        }

        // Ajouter le point d'arrivée
        routePoints.add({'name': travel.to, 'coords': LatLng(polylineCoords.last[0], polylineCoords.last[1]), 'type': 'end'});

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LiveTrackingPage(routePoints: routePoints, travel: travel)),
        );
      } else {
        print('Erreur lors de la récupération des détails de trajet pour le suivi: ${response.body}');
        // Fallback to static route if API call fails
        _navigateToLiveTrackingPageStatic(travel);
      }
    } catch (e) {
      print('Erreur de connexion au serveur pour le suivi: $e');
      // Fallback to static route if API call fails
      _navigateToLiveTrackingPageStatic(travel);
    }
  }

  // Fallback function for static route
  void _navigateToLiveTrackingPageStatic(Travel travel) {
    final routePoints = [
      {'name': 'Yaoundé', 'coords': const LatLng(3.866667, 11.516667), 'type': 'start'},
      {'name': 'Boumnyébel', 'coords': const LatLng(3.88, 10.85), 'type': 'intermediate'},
      {'name': 'Eséka', 'coords': const LatLng(3.65, 10.7667), 'type': 'intermediate'},
      {'name': 'Pouma', 'coords': const LatLng(3.85, 10.5167), 'type': 'intermediate'},
      {'name': 'Edéa', 'coords': const LatLng(3.8, 10.1333), 'type': 'intermediate'},
      {'name': travel.to, 'coords': const LatLng(4.0510, 9.7679), 'type': 'end'},
    ];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LiveTrackingPage(routePoints: routePoints, travel: travel)),
    );
  }

  Future<void> _showIntermediateLocalities(String from, String to) async {
    final List<String> intermediateLocalities = ['Boumnyébel', 'Eséka', 'Pouma', 'Edéa'];
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Localités entre $from et $to'),
          content: SingleChildScrollView(
            child: ListBody(
              children: intermediateLocalities.map((locality) => Text(locality)).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return;
  }

  // Nouvelle fonction pour obtenir les informations de distance
  Future<Map<String, String>?> _getDistanceInfo(String origin, String destination) async {
    if (!mounted) return null; // Vérifie si le widget est toujours monté
    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.21:8000/trajets/details?depart=$origin&destination=$destination'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Vérifiez si 'details_google_maps' et 'distance' existent avant d'y accéder
        if (data['details_google_maps'] != null && data['details_google_maps']['distance'] != null) {
          return {
            'distance': data['details_google_maps']['distance'],
            'duration': data['details_google_maps']['duree'],
          };
        } else {
          print('Données de distance manquantes ou nulles dans la réponse: ${response.body}');
          return null;
        }
      } else {
        print('Erreur lors de la récupération des détails de trajet: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur de connexion au serveur pour les détails de trajet: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher un Voyage'),
        actions: [
          IconButton(
            icon: Icon(Icons.login),
            tooltip: 'Se connecter',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            tooltip: "S'inscrire",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            tooltip: 'Mon Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
            body: _isDataLoading
          ? const Center(child: CircularProgressIndicator()) // Affiche un indicateur de chargement
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Votre position actuelle:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _currentLocation,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          title: Text("Date du voyage: ${DateFormat('EEEE, dd MMMM, yyyy', 'fr_FR').format(_selectedDate)}"),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _autocompleteController,
                          onChanged: _getPlacePredictions,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Destination',
                            hintText: 'Entrez votre ville de destination',
                          ),
                        ),
                        _placePredictions.isNotEmpty
                            ? SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _placePredictions.length,
                                  itemBuilder: (context, index) {
                                    final prediction = _placePredictions[index];
                                    return ListTile(
                                      title: Text(prediction.description ?? ''),
                                      onTap: () {
                                        _autocompleteController.text = prediction.description ?? '';
                                        setState(() {
                                          _placePredictions = [];
                                        });
                                        _searchTravel();
                                      },
                                    );
                                  },
                                ),
                              )
                            : SizedBox.shrink(),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _searchTravel,
                          child: const Text('Rechercher un Trajet'),
                        ),
                        const SizedBox(height: 20),
                        _currentTripDisplay != null
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  _currentTripDisplay!,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 6.0,
                      ),
                      polylines: _polylines,
                      markers: _markers,
                    ),
                  ),
                ),
                _isLoading
                    ? SliverToBoxAdapter(
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final travel = _foundTravels[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${travel.from} -> ${travel.to}',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Compagnie: ${travel.company}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Prix VIP: ${travel.prixVip} FCFA',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    Text(
                                      'Prix Classique: ${travel.prixClassique} FCFA',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Date: ${DateFormat('EEEE, dd MMMM, yyyy', 'fr_FR').format(travel.date!)}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule, size: 18, color: Colors.grey[700]),
                                        const SizedBox(width: 8),
                                        Text('Départ: ${travel.heureDepart}'),
                                        const SizedBox(width: 24),
                                        Icon(Icons.timer_outlined, size: 18, color: Colors.grey[700]),
                                        const SizedBox(width: 8),
                                        Text('Durée: ${travel.dureeEstimee}'),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Affichage de la distance
                                    FutureBuilder<Map<String, String>?>( // Utilisation de FutureBuilder
                                      future: _getDistanceInfo(travel.from, travel.to), // Appel de la fonction pour obtenir la distance
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const CircularProgressIndicator(); // Indicateur de chargement
                                        } else if (snapshot.hasError) {
                                          return Text('Erreur de distance: ${snapshot.error}');
                                        } else if (snapshot.hasData && snapshot.data != null) {
                                          return Text('Distance: ${snapshot.data!['distance']}');
                                        } else {
                                          return const Text('Distance non disponible');
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    FittedBox(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => _showIntermediateLocalities(travel.from, travel.to),
                                            child: const Text('Localités sur le trajet'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(travel: travel))),
                                            child: const Text('Réserver'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _navigateToLiveTrackingPage(travel),
                                            child: const Text('Suivre le trajet'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _foundTravels.length,
                        ),
                      ),
                SliverToBoxAdapter(
                  child: AgenciesNearYou(agencies: _agencies),
                ),
              ],
            ),
    );
  }
}

class AgenciesNearYou extends StatefulWidget {
  final List<Agency> agencies;

  const AgenciesNearYou({Key? key, required this.agencies}) : super(key: key);

  @override
  State<AgenciesNearYou> createState() => _AgenciesNearYouState();
}

class _AgenciesNearYouState extends State<AgenciesNearYou> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: _animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Agences de voyages proches de vous',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.agencies.length,
          itemBuilder: (context, index) {
            final agency = widget.agencies[index];
            return Card(
              child: ListTile(
                title: Text(agency.name),
                subtitle: Text(agency.address),
                trailing: Text('${agency.distance.toStringAsFixed(2)} km'),
              ),
            );
          },
        ),
      ],
    );
  }
}
