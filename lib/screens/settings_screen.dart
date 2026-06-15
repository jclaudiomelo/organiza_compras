import 'package:flutter/material.dart';
import '../controllers/purchase_controller.dart';

class SettingsScreen extends StatelessWidget {
  final PurchaseController controller;

  const SettingsScreen({super.key, required this.controller});

  static const Map<String, String> _states = {
    'AC': 'Acre',
    'AL': 'Alagoas',
    'AP': 'Amapá',
    'AM': 'Amazonas',
    'BA': 'Bahia',
    'CE': 'Ceará',
    'DF': 'Distrito Federal',
    'ES': 'Espírito Santo',
    'GO': 'Goiás',
    'MA': 'Maranhão',
    'MT': 'Mato Grosso',
    'MS': 'Mato Grosso do Sul',
    'MG': 'Minas Gerais',
    'PA': 'Pará',
    'PB': 'Paraíba',
    'PR': 'Paraná',
    'PE': 'Pernambuco',
    'PI': 'Piauí',
    'RJ': 'Rio de Janeiro',
    'RN': 'Rio Grande do Norte',
    'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia',
    'RR': 'Roraima',
    'SC': 'Santa Catarina',
    'SP': 'São Paulo',
    'SE': 'Sergipe',
    'TO': 'Tocantins',
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final defaultState = controller.defaultState;

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
                  'Estado para Consultas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Defina o estado padrão para consultas manuais. Ao digitar chaves de acesso completas, o aplicativo tentará identificar o estado automaticamente.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _states.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final uf = _states.keys.elementAt(index);
                      final name = _states.values.elementAt(index);
                      final isSelected = uf == defaultState;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text(
                          '$name ($uf)',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.deepPurpleAccent.withOpacity(0.12)
                              : Colors.white.withOpacity(0.04),
                          child: Text(
                            uf,
                            style: TextStyle(
                              color: isSelected ? Colors.deepPurpleAccent : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent)
                            : null,
                        onTap: () async {
                          await controller.updateDefaultState(uf);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
