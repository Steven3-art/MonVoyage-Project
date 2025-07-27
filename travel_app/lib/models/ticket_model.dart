class Ticket {
  final int id;
  final String description;
  final String status;

  Ticket({required this.id, required this.description, required this.status});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      description: json['description'],
      status: json['status'],
    );
  }
}
