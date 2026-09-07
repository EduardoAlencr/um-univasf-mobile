import 'package:firebase_auth/firebase_auth.dart';
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
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cursoCtrl = TextEditingController(text: 'Engenharia de Computação');
  final _periodoCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _termsAccepted = true;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _cursoCtrl.dispose();
    _periodoCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    if (_nomeCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _senhaCtrl.text.isEmpty) {
      showUmToast(context, 'Preencha nome, e-mail e senha.');
      return;
    }
    if (_senhaCtrl.text != _confirmarCtrl.text) {
      showUmToast(context, 'As senhas não coincidem.');
      return;
    }
    setState(() => _carregando = true);
    try {
      await AuthScope.of(context).cadastrar(
        email: _emailCtrl.text,
        senha: _senhaCtrl.text,
        nome: _nomeCtrl.text.trim(),
        curso: _cursoCtrl.text.trim(),
        periodo: _periodoCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      showUmToast(context, 'Bem-vindo! Seu calendário pessoal foi desbloqueado.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showUmToast(context, _mensagemErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _mensagemErro(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Já existe uma conta com esse e-mail.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha muito fraca — use pelo menos 6 caracteres.';
      default:
        return 'Não foi possível criar a conta (${e.code}).';
    }
  }

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
              _Field(label: 'Nome completo', controller: _nomeCtrl, hint: 'Seu Nome Completo'),
              const SizedBox(height: 12),
              _Field(label: 'E-mail institucional', controller: _emailCtrl, hint: 'seu.nome@discente.univasf.edu.br'),
              const SizedBox(height: 12),
              _Field(label: 'Curso', controller: _cursoCtrl),
              const SizedBox(height: 12),
              _Field(label: 'Período de ingresso', controller: _periodoCtrl, hint: '2020.2'),
              const SizedBox(height: 12),
              _Field(label: 'Senha do aplicativo', controller: _senhaCtrl, obscure: true, hint: '••••••••'),
              const SizedBox(height: 12),
              _Field(label: 'Confirmar senha', controller: _confirmarCtrl, obscure: true, hint: '••••••••'),
              const SizedBox(height: 16),
              _TermsCheck(
                checked: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v),
              ),
              const SizedBox(height: 4),
              IgnorePointer(
                ignoring: !_termsAccepted || _carregando,
                child: AnimatedOpacity(
                  opacity: _termsAccepted ? 1 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: PillButton(
                    label: _carregando ? 'Criando conta…' : 'Criar conta',
                    onPressed: () => _criarConta(),
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
  const _Field({required this.label, required this.controller, this.hint, this.obscure = false});
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.ink2),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
            ),
          ),
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
