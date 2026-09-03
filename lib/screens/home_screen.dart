import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/source_tag.dart';
import 'discente_screen.dart';
import 'ru_screen.dart';
import 'bus_screen.dart';
import 'editais_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenNotif});

  final VoidCallback onOpenNotif;

  static const _softColors = [AppColors.orangeSoft, AppColors.yellowSoft, AppColors.redSoft, AppColors.blueSoft];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Olá! 👋', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Quarta-feira, 26 de agosto de 2026 · acesso livre, sem login',
            style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
          ),
          const SizedBox(height: 18),
          _Hero(),
          const SectionHeader('Módulos'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _Module(
                icon: '🎓',
                bg: AppColors.blueSoft,
                title: 'Discente',
                desc: 'Grade de horários e atalhos do SIG@',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiscenteScreen())),
              ),
              _Module(
                icon: '🍽️',
                bg: AppColors.yellowSoft,
                title: 'Restaurante',
                desc: 'Cardápio do RU atualizado',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RuScreen())),
              ),
              _Module(
                icon: '🚌',
                bg: AppColors.greenSoft,
                title: 'Transporte',
                desc: 'Rotas e horários dos ônibus',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BusScreen())),
              ),
              _Module(
                icon: '📢',
                bg: AppColors.orangeSoft,
                title: 'Editais',
                desc: 'PROAE, PROEN, PROEX e mais',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditaisScreen())),
              ),
            ],
          ),
          const SectionHeader('Notícias recentes'),
          ...homeNotices.map(
            (n) => AppCard(
              onTap: onOpenNotif,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _softColors[n.iconBg],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(n.icon, style: const TextStyle(fontSize: 18)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.35)),
                        const SizedBox(height: 3),
                        Text(n.desc, style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.45)),
                        const SizedBox(height: 6),
                        Text(n.when, style: const TextStyle(fontSize: 10.5, color: AppColors.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(color: AppColors.blue.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text(
              'PRÓXIMO PRAZO · EM 3 DIAS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ajuste de matrícula encerra em 29/08',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Solicitações presenciais na SRCA ou via SIG@.',
            style: TextStyle(fontSize: 12.5, color: Colors.white, height: 1.45),
          ),
          const SourceTag(
            text: 'Atualizado automaticamente · Calendário acadêmico oficial · hoje, 06:00',
            dotColor: AppColors.yellow,
            topPadding: 12,
          ),
        ],
      ),
    );
  }
}

class _Module extends StatelessWidget {
  const _Module({required this.icon, required this.bg, required this.title, required this.desc, required this.onTap});

  final String icon;
  final Color bg;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.module),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.module),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.module),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}
