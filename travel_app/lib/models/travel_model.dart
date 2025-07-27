class Travel {
  final String from;
  final String to;
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;
  final int prixVip;
  final int prixClassique;
  final String company;
  final String heureDepart;
  final String dureeEstimee;
  final DateTime? date;

  Travel({
    required this.from,
    required this.to,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    required this.prixVip,
    required this.prixClassique,
    required this.company,
    required this.heureDepart,
    required this.dureeEstimee,
    this.date,
  });

  factory Travel.fromJson(Map<String, dynamic> json) {
    return Travel(
      from: json['agence'], // ou une autre clé selon votre JSON de l'API
      to: json['destination'],
      fromLatitude: json['latitude'] ?? 0.0, // A adapter selon votre API
      fromLongitude: json['longitude'] ?? 0.0, // A adapter selon votre API
      toLatitude: json['latitude'] ?? 0.0,
      toLongitude: json['longitude'] ?? 0.0,
      prixVip: json['prix_vip'],
      prixClassique: json['prix_classique'],
      company: json['agence'],
      heureDepart: json['heureDepart'],
      dureeEstimee: json['dureeEstimee'],
      date: json.containsKey('date') && json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }
}

class Agency {
  final String name;
  final String address;
  final double distance;

  Agency({
    required this.name,
    required this.address,
    required this.distance,
  });
}