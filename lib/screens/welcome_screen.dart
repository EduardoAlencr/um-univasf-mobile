import 'dart:async';
import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinuar});

  final VoidCallback onContinuar;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeSlide {
  const _WelcomeSlide({required this.icon, this.tag, required this.titulo, required this.descricao});
  final IconData icon;
  final String? tag;
  final String titulo;
  final String descricao;
}

const _slides = [
  _WelcomeSlide(
    icon: Icons.school_rounded,
    tag: 'TRABALHO DE CONCLUSÃO DE CURSO',
    titulo: 'Sobre este app',
    descricao:
        'Protótipo de TCC (Engenharia da Computação, UNIVASF) que reúne, num só lugar, informações públicas hoje espalhadas em vários sites da universidade.',
  ),
  _WelcomeSlide(
    icon: Icons.article_rounded,
    titulo: 'Notícias da PROAE, PROEN e PROEX',
    descricao: 'Coletadas automaticamente — os demais setores ainda não estão cobertos.',
  ),
  _WelcomeSlide(
    icon: Icons.grid_view_rounded,
    titulo: 'RU, ônibus, editais e calendário',
    descricao: 'Sempre atualizados, direto dos sites oficiais.',
  ),
  _WelcomeSlide(
    icon: Icons.lock_rounded,
    titulo: 'Sem senha do SIG@',
    descricao: 'Serviços restritos abrem no portal oficial, sem sua senha institucional.',
  ),
  _WelcomeSlide(
    icon: Icons.event_available_rounded,
    titulo: 'Conta só pra duas coisas',
    descricao: 'Grade de horários e calendário pessoal — o resto é livre, sem login.',
  ),
];

const _duracaoAuto = Duration(milliseconds: 3200);

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _atual = 0;
  bool _naoMostrarNovamente = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _agendarAvanco();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _agendarAvanco() {
    _timer?.cancel();
    if (_atual >= _slides.length - 1) return;
    _timer = Timer(_duracaoAuto, _avancar);
  }

  void _avancar() {
    if (_atual >= _slides.length - 1) return;
    setState(() => _atual++);
    _agendarAvanco();
  }

  void _voltarSlide() {
    if (_atual <= 0) return;
    setState(() => _atual--);
    _agendarAvanco();
  }

  void _comecar() {
    if (_naoMostrarNovamente) {
      AuthScope.of(context).dismissWelcome();
    }
    widget.onContinuar();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_atual];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              Row(
                children: List.generate(_slides.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(right: i == _slides.length - 1 ? 0 : 4),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: i < _atual ? 1 : (i == _atual ? 1 : 0),
                        child: AnimatedContainer(
                          duration: i == _atual ? _duracaoAuto : Duration.zero,
                          curve: Curves.linear,
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(child: GestureDetector(onTap: _voltarSlide, behavior: HitTestBehavior.opaque)),
                          Expanded(child: GestureDetector(onTap: _avancar, behavior: HitTestBehavior.opaque)),
                        ],
                      ),
                    ),
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: Column(
                          key: ValueKey(_atual),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (slide.tag != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.blueSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  slide.tag!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: AppColors.blueDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Icon(slide.icon, size: 30, color: AppColors.blueDark),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              slide.titulo,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.ink),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                slide.descricao,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _naoMostrarNovamente = !_naoMostrarNovamente),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: _naoMostrarNovamente,
                      onChanged: (v) => setState(() => _naoMostrarNovamente = v),
                      activeTrackColor: AppColors.blue,
                    ),
                    const SizedBox(width: 4),
                    const Text('Não mostrar novamente', style: TextStyle(fontSize: 12, color: AppColors.ink2, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _comecar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(999)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Center(
                        child: Text('Começar', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Protótipo de TCC · dados reais da UNIVASF',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppColors.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
