
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mon_voyage/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  String? _lastUsername;

  @override
  void initState() {
    super.initState();
    _loadLastUsername();
  }

  Future<void> _loadLastUsername() async {
    _lastUsername = await _storage.read(key: 'last_username');
    if (_lastUsername != null) {
      _usernameController.text = _lastUsername!;
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // L'endpoint /token attend des données de formulaire, pas du JSON.
        final response = await http.post(
          Uri.parse('http://192.168.100.21:8000/token'), 
          headers: <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'username': _usernameController.text,
            'password': _passwordController.text,
          },
        );

        if (response.statusCode == 200) {
          // Succès
          final data = jsonDecode(response.body);
          final token = data['access_token'];
          
          await _authService.saveToken(token);
          await _storage.write(key: 'last_username', value: _usernameController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connexion réussie!')),
          );
          // Indiquer que la connexion a réussi en retournant `true`
          Navigator.pop(context, true);
        } else {
          // Erreur
          final error = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${error['detail']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion au serveur.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Se connecter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: "Nom d'utilisateur"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer votre nom d'utilisateur";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre mot de passe';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text('Connexion'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
