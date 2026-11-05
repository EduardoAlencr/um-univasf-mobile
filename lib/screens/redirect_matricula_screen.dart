import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/um_app_bar.dart';
import '../util/abrir_link.dart';
import '../navigation/go_profile.dart';

const _sigaUrl = 'https://siga.univasf.edu.br/univasf/jsp/acesso/pages/inicio.jsf';
const _urlTiposSolicitacaoGraduacao = 'https://portais.univasf.edu.br/srca/solicitacoes-gerais-da-graduacao';

/// Matrícula, ajuste/modificação de matrícula e trancamento — tudo
/// resolvido no SIG@ dentro do período oficial (não há um passo a passo
/// oficial detalhado publicado pra citar aqui, então a tela só direciona
/// pras duas fontes reais: o sistema e o catálogo de requerimentos da SRCA,
/// pra quem precisa de algo fora da janela do SIG@).
class RedirectMatriculaScreen extends StatelessWidget {
  const RedirectMatriculaScreen({super.key});

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
            Text('Matrícula', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Matrícula, ajuste/modificação e trancamento — tudo feito pelo SIG@ dentro do período oficial.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🖥️ Pelo SIG@', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Acesse o SIG@ com seu login institucional. A matrícula e o ajuste ficam disponíveis só durante o período oficial divulgado no calendário acadêmico — fora dessa janela, o sistema não deixa fazer a solicitação.',
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
                  const Text('📄 Fora do período do SIG@', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Precisa de algo fora da janela (ex. trancamento)? Esses casos têm requerimento próprio na categoria "Matrícula semestral" do catálogo da SRCA, enviado ao SIC do seu campus.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  PillButton(
                    label: 'Ver catálogo da SRCA ↗',
                    variant: PillButtonVariant.secondary,
                    onPressed: () => abrirLink(context, _urlTiposSolicitacaoGraduacao),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
