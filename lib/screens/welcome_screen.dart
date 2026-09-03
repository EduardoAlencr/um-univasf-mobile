import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinuar});

  final VoidCallback onContinuar;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _naoMostrarNovamente = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 30),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Text('🎓', style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(height: 18),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
                          children: [
                            TextSpan(text: 'UM · '),
                            TextSpan(text: 'UNIVASF', style: TextStyle(color: AppColors.blue)),
                            TextSpan(text: ' Mobile'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Todos os serviços públicos da universidade reunidos em um só lugar — atualizados automaticamente direto dos sites oficiais.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: AppColors.ink2, height: 1.5),
                      ),
                      const SizedBox(height: 30),
                      const _ItemExplicativo(
                        icon: '📰',
                        titulo: 'Informação sempre atual',
                        descricao: 'Notícias, cardápio do RU, ônibus, editais e calendário acadêmico, coletados automaticamente — sem precisar procurar em vários sites.',
                      ),
                      const _ItemExplicativo(
                        icon: '🔐',
                        titulo: 'Sem senha do SIG@',
                        descricao: 'O app nunca pede sua senha institucional. Serviços restritos (notas, matrícula, histórico) abrem direto no portal oficial.',
                      ),
                      const _ItemExplicativo(
                        icon: '🗓️',
                        titulo: 'Acesso livre, conta opcional',
                        descricao: 'A maior parte do app funciona sem login. Só o calendário pessoal e sua grade de horários exigem conta.',
                      ),
                    ],
                  ),
                ),
              ),
              CheckboxListTile(
                value: _naoMostrarNovamente,
                onChanged: (v) => setState(() => _naoMostrarNovamente = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.blue,
                title: const Text('Não mostrar novamente', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
              ),
              PillButton(
                label: 'Começar',
                onPressed: () {
                  if (_naoMostrarNovamente) {
                    AuthScope.of(context).dismissWelcome();
                  }
                  widget.onContinuar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemExplicativo extends StatelessWidget {
  const _ItemExplicativo({required this.icon, required this.titulo, required this.descricao});
  final String icon;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(descricao, style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
