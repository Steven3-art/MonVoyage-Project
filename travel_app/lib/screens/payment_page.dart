
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mon_voyage/models/travel_model.dart';
import 'package:mon_voyage/screens/confirmation_page.dart';

class PaymentPage extends StatefulWidget {
  final Travel travel;

  const PaymentPage({super.key, required this.travel});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedPaymentMethod;
  String? _selectedServiceType; // Nouvelle variable pour le type de service
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedServiceType = 'Classique'; // Valeur par défaut
  }

  void _processPayment() {
    if (_selectedPaymentMethod == null || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un mode de paiement et entrer un numéro.')),
      );
      return;
    }

    // Déterminer le prix en fonction du type de service sélectionné
    final int finalPrice = _selectedServiceType == 'VIP' ? widget.travel.prixVip : widget.travel.prixClassique;

    // Affiche une boîte de dialogue de confirmation
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la réservation'),
          content: Text(
              'Vous êtes sur le point de réserver le voyage de ${widget.travel.from} à ${widget.travel.to} avec ${widget.travel.company} en service $_selectedServiceType pour ${finalPrice} FCFA, départ prévu à ${widget.travel.heureDepart} le ${DateFormat('EEEE, dd MMMM, yyyy', 'fr_FR').format(widget.travel.date!)}.\n\nVoulez-vous confirmer ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirmer'),
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
                _initiatePayment(finalPrice, _selectedServiceType!); // Lance le paiement
              },
            ),
          ],
        );
      },
    );
  }

  void _initiatePayment(int finalPrice, String serviceType) {
    setState(() {
      _isProcessing = true;
    });

    // Simule une transaction de paiement
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isProcessing = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ConfirmationPage(travel: widget.travel, finalPrice: finalPrice, serviceType: serviceType)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Résumé du Trajet', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text('${widget.travel.from} -> ${widget.travel.to}'),
                    Text('Compagnie: ${widget.travel.company}'),
                    const SizedBox(height: 10),
                    Text('Départ: ${widget.travel.heureDepart}'),
                    Text('Durée: ${widget.travel.dureeEstimee}'),
                    Text('Date: ${DateFormat('EEEE, dd MMMM, yyyy', 'fr_FR').format(widget.travel.date!)}'),
                    const SizedBox(height: 10),
                    Text('Prix VIP: ${widget.travel.prixVip} FCFA', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('Prix Classique: ${widget.travel.prixClassique} FCFA', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedServiceType,
              hint: const Text('Choisir le type de service'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedServiceType = newValue!;
                });
              },
              items: <String>['VIP', 'Classique']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              hint: const Text('Choisir le mode de paiement'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue!;
                });
              },
              items: <String>['Orange Money', 'MTN Mobile Money']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Numéro de téléphone',
                hintText: 'Entrez le numéro pour le paiement',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Payer Maintenant'),
            ),
          ],
        ),
      ),
    );
  }
}
