import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import 'termos_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  bool _termsAccepted = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackRow(label: 'Voltar para o login', onTap: () => Navigator.of(context).pop()),
              Text('Criar conta', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              const Text(
                'Gratuita, só com seu e-mail institucional. Necessária apenas para o calendário pessoal e sua grade.',
                style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
              ),
              const SizedBox(height: 18),
              const _Field(label: 'Nome completo', value: 'Seu Nome Completo'),
              const SizedBox(height: 12),
              const _Field(label: 'E-mail institucional', value: 'seu.nome@discente.univasf.edu.br'),
              const SizedBox(height: 12),
              const _Field(label: 'Curso', value: 'Engenharia de Computação'),
              const SizedBox(height: 12),
              const _Field(label: 'Período de ingresso', value: '2020.2'),
              const SizedBox(height: 12),
              const _Field(label: 'Senha do aplicativo', value: '••••••••'),
              const SizedBox(height: 12),
              const _Field(label: 'Confirmar senha', value: '••••••••'),
              const SizedBox(height: 16),
              _TermsCheck(
                checked: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v),
              ),
              const SizedBox(height: 4),
              IgnorePointer(
                ignoring: !_termsAccepted,
                child: AnimatedOpacity(
                  opacity: _termsAccepted ? 1 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: PillButton(
                    label: 'Criar conta',
                    onPressed: () {
                      AuthScope.of(context).login();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      showUmToast(context, 'Bem-vindo! Seu calendário pessoal foi desbloqueado.');
                    },
                  ),
                ),
              ),
              if (!_termsAccepted)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Aceite os termos para criar sua conta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: Color(0xFFB3402F), fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                '🔒 A senha é exclusiva do aplicativo.\nO app nunca pede a senha do SIG@.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
        ),
      ],
    );
  }
}

class _TermsCheck extends StatelessWidget {
  const _TermsCheck({required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: checked,
          activeColor: AppColors.blue,
          onChanged: (v) => onChanged(v ?? true),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.5),
                children: [
                  const TextSpan(text: 'Li e aceito os '),
                  TextSpan(
                    text: 'Termos de Uso e Política de Privacidade',
                    style: const TextStyle(color: AppColors.blueDark, fontWeight: FontWeight.w800),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TermosScreen()),
                          ),
                  ),
                  const TextSpan(text: ', em conformidade com a LGPD (Lei nº 13.709/2018).'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
