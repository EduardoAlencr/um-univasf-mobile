import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import '../util/abrir_link.dart';
import '../navigation/go_profile.dart';

const _urlTiposSolicitacaoGraduacao = 'https://portais.univasf.edu.br/srca/solicitacoes-gerais-da-graduacao';
const _urlTiposSolicitacaoPos = 'https://portais.univasf.edu.br/srca/solicitacoes-gerais-pos-graduacao';

/// Área de Solicitações Gerais de Serviços Acadêmicos — conteúdo e contatos
/// espelham a página oficial da SRCA; os tipos de requerimento específicos
/// (com formulário pra baixar) ficam só no site, aberto por um link, em vez
/// de duplicados aqui.
class SolicitacoesScreen extends StatelessWidget {
  const SolicitacoesScreen({super.key});

  Future<void> _enviarEmail(BuildContext context, SicContact contato) => _enviarEmailPara(context, contato.email);

  Future<void> _enviarEmailPara(BuildContext context, String? email) async {
    if (email == null) return;
    final uri = Uri(scheme: 'mailto', path: email);
    final aberto = await launchUrl(uri);
    if (!aberto && context.mounted) {
      showUmToast(context, 'Não foi possível abrir o app de e-mail. Copie: $email');
    }
  }

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
            Text('Solicitações da SRCA', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Serviços e requerimentos acadêmicos usados ao longo da graduação e pós-graduação.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📌 Como solicitar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const _PassoSolicitacao(
                    numero: '1',
                    titulo: 'Por e-mail',
                    texto:
                        'Use seu e-mail institucional da Univasf. Envie para o SIC do campus do seu curso, anexando todos os documentos exigidos para o serviço solicitado.',
                  ),
                  const SizedBox(height: 10),
                  const _PassoSolicitacao(
                    numero: '2',
                    titulo: 'Presencialmente no SIC do campus',
                    texto:
                        'Compareça no horário de atendimento presencial do SIC do seu campus (veja abaixo), portando os documentos originais exigidos.',
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 30),
                    child: Text(
                      'Não pode comparecer? É possível nomear um procurador: com procuração simples e firma reconhecida em cartório, ou apresentando o documento de identificação original do outorgante (assinatura idêntica à da procuração) + documento próprio do procurador.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('ENDEREÇOS E CONTATOS DOS SICs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  for (final c in sicContacts)
                    GestureDetector(
                      onTap: () => _enviarEmail(context, c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          border: c != sicContacts.last ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.campus, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                  if (c.endereco != null) ...[
                                    const SizedBox(height: 2),
                                    Text(c.endereco!, style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4)),
                                  ],
                                  const SizedBox(height: 3),
                                  Text(c.email, style: const TextStyle(fontSize: 11.5, color: AppColors.blueDark)),
                                  if (c.horarioPresencial != null) ...[
                                    const SizedBox(height: 3),
                                    Text('🕘 ${c.horarioPresencial}', style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4)),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.blueDark),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (srcaAtendimentoInterno.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('OUTROS SETORES DA SRCA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
              const SizedBox(height: 4),
              const Text(
                'Diretoria, coordenações de registro acadêmico e demais setores internos.',
                style: TextStyle(fontSize: 11.5, color: AppColors.ink2),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    for (final c in srcaAtendimentoInterno)
                      GestureDetector(
                        onTap: () => _enviarEmailPara(context, c.email),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            border: c != srcaAtendimentoInterno.last ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.setor, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                    if (c.email != null) ...[
                                      const SizedBox(height: 3),
                                      Text(c.email!, style: const TextStyle(fontSize: 11.5, color: AppColors.blueDark)),
                                    ],
                                    if (c.horario != null) ...[
                                      const SizedBox(height: 3),
                                      Text('🕘 ${c.horario}', style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4)),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (c.email != null) const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.blueDark),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📄 Tipos de solicitação', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Declaração de matrícula, 2ª via de documento, histórico escolar, trancamento e outros — lista completa, com os formulários, no site da SRCA.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  PillButton(label: 'Ver tipos — Graduação ↗', onPressed: () => abrirLink(context, _urlTiposSolicitacaoGraduacao)),
                  PillButton(
                    label: 'Ver tipos — Pós-Graduação ↗',
                    variant: PillButtonVariant.secondary,
                    onPressed: () => abrirLink(context, _urlTiposSolicitacaoPos),
                  ),
                ],
              ),
            ),
            const SourceTag(text: 'Conteúdo e contatos da página de Solicitações da SRCA', topPadding: 14),
          ],
        ),
      ),
    );
  }
}

class _PassoSolicitacao extends StatelessWidget {
  const _PassoSolicitacao({required this.numero, required this.titulo, required this.texto});
  final String numero;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
          child: Text(numero, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.blueDark)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(texto, style: const TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
