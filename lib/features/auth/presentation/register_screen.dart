import 'package:flutter/material.dart';

/// Register screen; wire to Supabase sign-up and go_router.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const Center(child: Text('Register screen – wire to Supabase')),
    );
  }
}
