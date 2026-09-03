import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/um_app_bar.dart';
import '../navigation/go_profile.dart';
import 'grade_processing_screen.dart';

class GradeUploadScreen extends StatelessWidget {
  const GradeUploadScreen({super.key});

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
            Text('Minha Grade de Horários', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text('Exclusiva da sua conta — só você vê.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 14),
              child: Column(
                children: [
                  const Text('🗓️', style: TextStyle(fontSize: 38)),
                  const SizedBox(height: 10),
                  const Text('Nenhuma grade enviada ainda', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'No SIG@, abra '),
                        TextSpan(text: 'Consultas → Grade de Horário', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: ' e tire um print da tela (o mural com os códigos e a legenda embaixo). O app lê os códigos, cruza com a legenda e monta sua agenda automaticamente.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.55),
                  ),
                ],
              ),
            ),
            Material(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GradeProcessingScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.blue, width: 2, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    children: [
                      Text('📸', style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text('Enviar print da grade', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                      SizedBox(height: 3),
                      Text('Aceita o modelo padrão do SIG@ (mural + legenda)', style: TextStyle(fontSize: 12, color: AppColors.ink2)),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(color: AppColors.yellowSoft, border: Border.all(color: const Color(0xFFF2DF9B)), borderRadius: BorderRadius.circular(16)),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '🔒 '),
                    TextSpan(text: 'Privacidade: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: 'a imagem fica vinculada apenas à sua conta e pode ser excluída a qualquer momento. Nada é compartilhado.'),
                  ],
                ),
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
