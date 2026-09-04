import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../util/abrir_link.dart';
import '../navigation/go_profile.dart';

const _sigaUrl = 'https://siga.univasf.edu.br/univasf/jsp/acesso/pages/inicio.jsf';
const _srcaUrl = 'https://portais.univasf.edu.br/srca';
const _instagramSrcaUrl = 'https://www.instagram.com/srca.univasf';

class RedirectHistoricoScreen extends StatelessWidget {
  const RedirectHistoricoScreen({super.key});

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
            Text('Histórico Escolar', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text('Duas formas de acesso, dependendo do que você precisa.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('🔍 Consulta rápida', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      AppBadge(label: 'SIG@', color: BadgeColor.blue),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Visualize disciplinas cursadas, médias e situação, direto no portal oficial.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  PillButton(label: 'Abrir SIG@ ↗', onPressed: () => abrirLink(context, _sigaUrl)),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('📄 Documento oficial', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      AppBadge(label: 'SRCA / Colegiado', color: BadgeColor.yellow),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'O histórico assinado é emitido pelo '),
                        TextSpan(text: 'SIC da SRCA do seu campus', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: ' (ou pelo Colegiado do seu curso). Prazo médio: '),
                        TextSpan(text: '5 dias úteis', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: ', enviado ao e-mail institucional.'),
                      ],
                    ),
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  const Text('🕘 Seg–Sex, 8h às 17h', style: TextStyle(fontSize: 12, height: 1.7)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✉️ Contato do SIC por campus',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Cada campus/colegiado tem seu próprio e-mail de atendimento.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 8),
                  for (final c in sicContacts)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(c.campus, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          Text(c.email, style: const TextStyle(fontSize: 11.5, color: AppColors.blueDark)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Em caso de dificuldade com os e-mails acima:',
                    style: TextStyle(fontSize: 11.5, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 10),
                  PillButton(
                    label: 'Ver página da SRCA ↗',
                    variant: PillButtonVariant.secondary,
                    onPressed: () => abrirLink(context, _srcaUrl),
                  ),
                  PillButton(
                    label: '📷 Instagram @srca.univasf ↗',
                    variant: PillButtonVariant.secondary,
                    onPressed: () => abrirLink(context, _instagramSrcaUrl),
                  ),
                  const SourceTag(text: 'Contatos do SIC/SRCA · verificados em 02/09/2026', topPadding: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
