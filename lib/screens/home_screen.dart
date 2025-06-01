import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  void _logout(BuildContext context) {
    // Implement Firebase sign-out logic here
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to the Home Screen!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

