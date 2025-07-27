
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Importation de geolocator
import 'package:mon_voyage/models/travel_model.dart';
import 'dart:math'; // Pour générer un numéro de réservation aléatoire

class ConfirmationPage extends StatelessWidget {
  final Travel travel;
  final int finalPrice; // Nouveau: prix final
  final String serviceType; // Nouveau: type de service

  const ConfirmationPage({super.key, required this.travel, required this.finalPrice, required this.serviceType});

  @override
  Widget build(BuildContext context) {
    // Génère un faux numéro de réservation
    final random = Random();
    final bookingNumber = '#${random.nextInt(10000).toString().padLeft(4, '0')}';

    // Calcule la distance
    final double distanceInMeters = Geolocator.distanceBetween(
      travel.fromLatitude,
      travel.fromLongitude,
      travel.toLatitude,
      travel.toLongitude,
    );
    final String distanceInKm = (distanceInMeters / 1000).toStringAsFixed(2); // Convertit en km et formate

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de Paiement'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              Text(
                'Paiement Réussi!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Votre billet électronique',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('${travel.from} -> ${travel.to}'),
                      Text(travel.company),
                      const SizedBox(height: 10),
                      Text('Prix: ${finalPrice} FCFA (${serviceType})'),
                      Text('Distance: ${distanceInKm} km'),
                      const SizedBox(height: 20),
                      Text(
                        'Numéro de Réservation: $bookingNumber',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      // Placeholder pour un QR code
                      const Icon(Icons.qr_code_2, size: 120),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Retourne à la page d'accueil
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("Retour à l'accueil"),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
