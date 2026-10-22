import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../util/abrir_link.dart';
import '../widgets/pill_button.dart';
import '../widgets/um_app_bar.dart';
import '../navigation/go_profile.dart';
import 'termos_screen.dart';

class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Voltar', onTap: () => Navigator.of(context).pop()),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('🎓', style: TextStyle(fontSize: 24)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UM · UNIVASF Mobile', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 2),
                      const Text('Protótipo acadêmico', style: TextStyle(fontSize: 12.5, color: AppColors.ink2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _Secao(
              titulo: 'O que é',
              corpo:
                  'Trabalho de Conclusão de Curso em Engenharia da Computação (UNIVASF, Campus Juazeiro) que reúne, num só lugar, informações públicas hoje espalhadas em vários sites da universidade — notícias, cardápio do RU, ônibus, editais e calendário — além de uma grade de horários pessoal montada a partir do PDF exportado do SIG@.',
            ),
            const _Secao(
              titulo: 'O que não é',
              corpo:
                  'Não é um aplicativo oficial da UNIVASF e não substitui o SIG@: serviços restritos (notas, histórico, matrícula) continuam sendo abertos direto no portal oficial, sem que o app guarde sua senha institucional.',
            ),
            const SizedBox(height: 4),
            PillButton(
              label: '📜 Termos de Uso e Privacidade',
              variant: PillButtonVariant.secondary,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermosScreen())),
            ),
            PillButton(
              label: '💻 Código-fonte no GitHub',
              variant: PillButtonVariant.secondary,
              onPressed: () => abrirLink(context, 'https://github.com/EduardoAlencr/um-univasf-mobile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.corpo});
  final String titulo;
  final String corpo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(titulo, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          ),
          Text(corpo, style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.6)),
        ],
      ),
    );
  }
}
