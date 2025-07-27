import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mon_voyage/models/ticket_model.dart';
import 'package:mon_voyage/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String? _username;
  String? _email;
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserTickets();
  }

  Future<void> _loadUserProfile() async {
    setState(() { _isLoading = true; });

    String? token = await _authService.getToken();
    if (token == null) {
      setState(() { _isLoading = false; });
      // L'utilisateur n'est pas connecté
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.21:8000/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _username = data['username'];
          _email = data['email'];
          _isLoading = false;
        });
      } else {
        // Gérer les erreurs, par exemple un token expiré
        setState(() { _isLoading = false; });
        await _authService.deleteToken(); // Supprimer le token invalide
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      // Gérer les erreurs de connexion
    }
  }

  Future<void> _loadUserTickets() async {
    String? token = await _authService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.21:8000/users/me/tickets'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _tickets = data.map((json) => Ticket.fromJson(json)).toList();
        });
      } else {
        // Gérer les erreurs
      }
    } catch (e) {
      // Gérer les erreurs de connexion
    }
  }

  Future<void> _cancelTicket(int ticketId) async {
    String? token = await _authService.getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.21:8000/billet/annuler/$ticketId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _loadUserTickets(); // Recharger la liste des billets
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Billet annulé avec succès.")),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'annulation: ${error['detail']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion au serveur.")),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.deleteToken();
    setState(() {
      _username = null;
      _email = null;
      _tickets = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Vous avez été déconnecté.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Profil'),
        actions: [
          if (_username != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Se déconnecter',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _username != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Nom d'utilisateur:", style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 8),
                      Text(_username!, style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 24),
                      Text('Email:', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 8),
                      Text(_email ?? 'Non fourni', style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 24),
                      Text('Mes Billets:', style: Theme.of(context).textTheme.titleMedium),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _tickets[index];
                            return Card(
                              child: ListTile(
                                title: Text(ticket.description),
                                subtitle: Text('Statut: ${ticket.status}'),
                                trailing: ticket.status == 'completed'
                                    ? ElevatedButton(
                                        onPressed: () => _cancelTicket(ticket.id),
                                        child: Text('Annuler'),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Veuillez vous connecter pour voir votre profil.'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Naviguer vers l'écran de connexion
                          // Note: une meilleure approche utiliserait un gestionnaire d'état
                          Navigator.pushNamed(context, '/login').then((result) {
                            if (result == true) {
                              _loadUserProfile(); // Recharger le profil si la connexion a réussi
                              _loadUserTickets();
                            }
                          });
                        },
                        child: Text('Se connecter'),
                      ),
                    ],
                  ),
                ),
    );
  }
}