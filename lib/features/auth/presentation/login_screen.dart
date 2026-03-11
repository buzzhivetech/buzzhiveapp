import 'package:flutter/material.dart';

/// Login screen; wire to Supabase sign-in and go_router.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: const Center(child: Text('Login screen – wire to Supabase')),
    );
  }
}
