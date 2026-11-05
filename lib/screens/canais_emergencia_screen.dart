import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../navigation/go_profile.dart';

class _Canal {
  const _Canal({required this.numero, required this.nome, this.disque = true});
  final String numero;
  final String nome;
  final bool disque;
}

const _grupos = {
  'Emergência e proteção': [
    _Canal(numero: '192', nome: 'SAMU (Serviço de Atendimento Móvel de Urgência)'),
    _Canal(numero: '190', nome: 'Polícia Militar'),
    _Canal(numero: '197', nome: 'Polícia Civil'),
    _Canal(numero: '193', nome: 'Corpo de Bombeiros'),
  ],
  'Direitos humanos e proteção social': [
    _Canal(numero: '100', nome: 'Direitos Humanos — violações (violência, discriminação, negligência)'),
    _Canal(numero: '180', nome: 'Central de Atendimento à Mulher'),
  ],
  'Saúde mental e apoio psicossocial': [
    _Canal(numero: '188', nome: 'CVV — Centro de Valorização da Vida (escuta emocional 24h, ligação ou chat)', disque: false),
  ],
};

/// Números de emergência nacionais — conteúdo estável, citado do Guia do
/// Estudante (Proen, 3ª ed., fev/2026).
class CanaisEmergenciaScreen extends StatelessWidget {
  const CanaisEmergenciaScreen({super.key});

  Future<void> _ligar(String numero) => launchUrl(Uri(scheme: 'tel', path: numero));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Perfil', onTap: () => Navigator.of(context).pop()),
            Text('Canais de Apoio e Emergência', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Números nacionais — toque para ligar.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 18),
            for (final grupo in _grupos.entries) ...[
              Text(grupo.key.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    for (final c in grupo.value)
                      GestureDetector(
                        onTap: () => _ligar(c.numero),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            border: c != grupo.value.last ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
                                child: Text(c.numero, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.redText)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(c.nome, style: const TextStyle(fontSize: 12.5, height: 1.4))),
                              const Icon(Icons.call_rounded, size: 18, color: AppColors.ink2),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const SourceTag(text: 'Fonte: Guia do Estudante, Proen (3ª ed., fev/2026)', topPadding: 2),
          ],
        ),
      ),
    );
  }
}
