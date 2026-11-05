import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../util/abrir_link.dart';
import '../navigation/go_profile.dart';

const _urlPaePermanencia = 'https://www.pae.univasf.edu.br';

/// Auxílios e bolsas de permanência da PROAE, raspados das páginas
/// oficiais. Conteúdo em texto livre na fonte (não tabela) — por isso
/// valor/critério podem vir nulos pra algum item, se a redação da página
/// mudar; a entrada ainda aparece, com o link pra conferir na fonte.
class AuxiliosScreen extends StatelessWidget {
  const AuxiliosScreen({super.key});

  List<ContatoSetor> get _contatosDuvidas => contatosProae
      .where((c) =>
          c.setor.toLowerCase().contains('restaurantes') ||
          c.setor.toLowerCase().contains('serviço social') ||
          c.setor.toLowerCase().contains('pró-reitoria'))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Discente', onTap: () => Navigator.of(context).pop()),
            Text('Auxílios e Bolsas', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Programas de assistência estudantil da PROAE. Seleção por edital anual, inscrição pelo sistema PAE.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 18),
            if (auxiliosProae.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Lista indisponível no momento. Consulte a página da PROAE.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink2),
                ),
              ),
            for (final a in auxiliosProae)
              AppCard(
                onTap: () => abrirLink(context, a.url),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(a.nome, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800))),
                        if (a.valor != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                            child: Text(a.valor!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.greenText)),
                          ),
                        ],
                      ],
                    ),
                    if (a.criterio != null) ...[
                      const SizedBox(height: 6),
                      Text('Critério: ${a.criterio}', style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.45)),
                    ],
                    if (a.campi.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Campi: ${a.campi.join(', ')}', style: const TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.45)),
                    ],
                    if (a.acumulaCom.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('✅ Pode acumular com: ${a.acumulaCom.join('; ')}', style: const TextStyle(fontSize: 11.5, color: AppColors.greenText, height: 1.45)),
                    ],
                    if (a.naoAcumulaCom.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('🚫 Não acumula com: ${a.naoAcumulaCom.join('; ')}', style: const TextStyle(fontSize: 11.5, color: Color(0xFFB3402F), height: 1.45)),
                    ],
                    if (a.duracaoDias != null || a.inscricaoOnline) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (a.duracaoDias != null) 'Processo seletivo: ~${a.duracaoDias} dias',
                          if (a.inscricaoOnline) 'inscrição 100% online (sistema PAE)',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.45),
                      ),
                    ],
                    const SourceTag(text: 'Página oficial da PROAE', topPadding: 8),
                  ],
                ),
              ),
            if (_contatosDuvidas.isNotEmpty) ...[
              const SizedBox(height: 4),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('☎️ Dúvidas sobre pagamento e seleção', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    for (final c in _contatosDuvidas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.setor, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(c.texto ?? c.email ?? '', style: const TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.4)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 Como se inscrever', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'As convocações saem anualmente em edital. Inscrições 100% on-line pelo sistema PAE — não é preciso entregar cópia impressa de documentos.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  PillButton(label: 'Abrir sistema PAE ↗', onPressed: () => abrirLink(context, _urlPaePermanencia)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
