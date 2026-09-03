import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/um_app_bar.dart';
import '../navigation/go_profile.dart';
import 'grade_result_screen.dart';

class GradeProcessingScreen extends StatefulWidget {
  const GradeProcessingScreen({super.key});

  @override
  State<GradeProcessingScreen> createState() => _GradeProcessingScreenState();
}

class _GradeProcessingScreenState extends State<GradeProcessingScreen> {
  static const _steps = [
    '✅ 6 disciplinas identificadas no mural (C4, 6B, C8, C0, C8, X1)',
    '✅ Códigos cruzados com a legenda de disciplinas do rodapé do print',
    '✅ Horários distribuídos em Seg a Sáb · salas e situação extraídas',
  ];

  bool _reading = true;
  int _stepsShown = 0;

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _reading = false);
    for (var i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _stepsShown = i + 1);
    }
  }

  bool get _done => !_reading && _stepsShown == _steps.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Cancelar', onTap: () => Navigator.of(context).pop()),
            Text('Organizando sua grade…', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text('Identificando disciplinas, dias e horários no print.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              child: Column(
                children: [
                  if (_reading) ...[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blue),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _reading ? 'Lendo imagem…' : 'Leitura concluída',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '2026.2 · Engenharia de Computação · Turno Integral',
                    style: TextStyle(fontSize: 12, color: AppColors.ink2),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedOpacity(
                      opacity: i < _stepsShown ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : 8),
                        child: Text(
                          i < _stepsShown ? _steps[i] : '',
                          style: const TextStyle(fontSize: 13, height: 1.45),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IgnorePointer(
              ignoring: !_done,
              child: AnimatedOpacity(
                opacity: _done ? 1 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: PillButton(
                  label: 'Ver minha agenda',
                  onPressed: () {
                    AuthScope.of(context).setHasGrade(true);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const GradeResultScreen()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
