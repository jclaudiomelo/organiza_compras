import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/purchase_controller.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final PurchaseController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F0E17),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sua Conta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16161A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.04),
                      child: const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                    ),
                    title: const Text('Configuração de Perfil', style: TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Em breve: Configuração de Perfil')),
                      );
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.04),
                      child: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                    ),
                    title: const Text('Alterar Senha', style: TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Em breve: Alterar Senha')),
                      );
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.redAccent.withOpacity(0.12),
                      child: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 20),
                    ),
                    title: const Text('Sair do App', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen(controller: controller)),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
