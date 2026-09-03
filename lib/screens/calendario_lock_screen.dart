import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';

class CalendarioLockScreen extends StatelessWidget {
  const CalendarioLockScreen({super.key, required this.onLogin, required this.onContinue});

  final VoidCallback onLogin;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendário', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('Recurso individual — exige login.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 14),
            child: Column(
              children: const [
                Text('🔐', style: TextStyle(fontSize: 38)),
                SizedBox(height: 10),
                Text('Sua agenda é só sua', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text(
                  'O calendário guarda seus prazos e lembretes pessoais. Por ser um recurso individual de cada usuário, é o único que pede login. Todo o resto do app funciona sem conta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.55),
                ),
              ],
            ),
          ),
          PillButton(label: 'Entrar ou criar conta', onPressed: onLogin),
          PillButton(
            label: 'Continuar sem login (dados públicos)',
            variant: PillButtonVariant.secondary,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
