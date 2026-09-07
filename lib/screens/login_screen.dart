import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';
import '../widgets/um_toast.dart';
import 'cadastro_screen.dart';
import 'termos_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_emailCtrl.text.trim().isEmpty || _senhaCtrl.text.isEmpty) {
      showUmToast(context, 'Preencha e-mail e senha.');
      return;
    }
    setState(() => _carregando = true);
    try {
      await AuthScope.of(context).login(_emailCtrl.text, _senhaCtrl.text);
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
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'E-mail ou senha incorretos.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas — tente novamente em instantes.';
      default:
        return 'Não foi possível entrar (${e.code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 0, 26, 40),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _LoginHero(),
                  const SizedBox(height: 26),
                  _EditableField(label: 'E-mail institucional', controller: _emailCtrl, hint: 'seu.nome@discente.univasf.edu.br'),
                  const SizedBox(height: 12),
                  _EditableField(label: 'Senha do aplicativo', controller: _senhaCtrl, obscure: true, hint: '••••••••'),
                  const SizedBox(height: 12),
                  PillButton(
                    label: _carregando ? 'Entrando…' : 'Entrar',
                    onPressed: () {
                      if (!_carregando) _entrar();
                    },
                  ),
                  PillButton(
                    label: 'Criar conta',
                    variant: PillButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CadastroScreen()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '🔒 O app não usa sua senha do SIG@.\nServiços acadêmicos restritos abrem no portal oficial.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.55),
                  ),
                  const SizedBox(height: 14),
                  _TermsLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.55),
        children: [
          const TextSpan(text: 'Ao entrar, você concorda com os\n'),
          TextSpan(
            text: 'Termos de Uso e Política de Privacidade',
            style: const TextStyle(color: AppColors.blueDark, fontWeight: FontWeight.w800),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TermosScreen()),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 128,
          height: 62,
          child: CustomPaint(painter: _UmLogoPainter()),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 3.5, color: AppColors.ink),
            children: [
              TextSpan(text: 'UNIVASF '),
              TextSpan(text: 'MOBILE', style: TextStyle(color: AppColors.blue)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Informações públicas agregadas, com conta só pra grade e calendário pessoal',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.ink2),
        ),
      ],
    );
  }
}

class _UmLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = AppColors.yellow;
    canvas.drawCircle(Offset(size.width / 2, 6), 8, dotPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      children: [
        TextSpan(text: 'U', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: AppColors.ink)),
        TextSpan(text: 'M', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: AppColors.blue)),
      ],
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, size.height - textPainter.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EditableField extends StatelessWidget {
  const _EditableField({required this.label, required this.controller, this.hint, this.obscure = false});

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: obscure ? TextInputType.visiblePassword : TextInputType.emailAddress,
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
