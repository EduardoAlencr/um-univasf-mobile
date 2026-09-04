import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/um_app_bar.dart';
import '../util/abrir_link.dart';
import '../navigation/go_profile.dart';

const _sigaUrl = 'https://siga.univasf.edu.br/univasf/jsp/acesso/pages/inicio.jsf';

class RedirectNotasScreen extends StatelessWidget {
  const RedirectNotasScreen({super.key});

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
            Text('Notas e Boletins', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text('Este serviço é restrito e acontece no portal oficial.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.hero)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('🔐', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 10),
                  const Text('Disponível no SIG@ UNIVASF',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 7),
                  Text(
                    'Suas notas são dados pessoais e protegidos. A consulta é feita no portal oficial, com o seu login institucional — o app nunca pede nem guarda essa senha.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.55),
                  ),
                ],
              ),
            ),
            PillButton(label: 'Abrir SIG@ ↗', onPressed: () => abrirLink(context, _sigaUrl)),
            const SectionHeaderNotas(),
            AppCard(
              child: Column(
                children: const [
                  _StepLi(number: 1, text: 'Toque em Abrir SIG@ — o portal oficial abre no navegador.'),
                  _StepLi(number: 2, text: 'Entre com seu CPF e senha do SIG@.'),
                  _StepLi(number: 3, text: 'No menu, acesse Consultar Notas e escolha o período letivo.'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                border: Border.all(color: const Color(0xFFC4DCCF)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '🛡️ '),
                    TextSpan(text: 'Por que não está no app? ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: 'A UNIVASF não disponibiliza integração pública com o SIG@. O redirecionamento mantém seus dados seguros e sempre atualizados.'),
                  ],
                ),
                style: TextStyle(fontSize: 12, color: AppColors.ink, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeaderNotas extends StatelessWidget {
  const SectionHeaderNotas({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 22, bottom: 12),
      child: Text('PASSO A PASSO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
    );
  }
}

class _StepLi extends StatelessWidget {
  const _StepLi({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.blueDark)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: const TextStyle(fontSize: 13, height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }
}
