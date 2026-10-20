import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../util/data_pt.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import '../navigation/go_profile.dart';
import 'grade_result_screen.dart';
import 'grade_upload_screen.dart';
import 'login_screen.dart';
import 'redirect_notas_screen.dart';
import 'redirect_historico_screen.dart';

const _palavrasAjuste = ['ajuste', 'modificaç', 'trancamento'];
const _descSemPeriodo = 'Consulte o período vigente no SIG@.';

class _StatusMatricula {
  const _StatusMatricula({required this.desc, required this.badge, required this.disponivel});
  final String desc;
  final Widget badge;
  final bool disponivel;
}

/// Procura, entre os eventos de calendário com `tag == 'matricula'`, o mais
/// próximo cujo título bata com [eventos] (já filtrado por palavra-chave).
/// Nunca inventa datas: se não houver evento real na janela do scraper
/// (~60 dias), cai no estado honesto "Indisponível".
_StatusMatricula _statusDoEvento(List<CalendarEvent> eventos) {
  final hoje = DateTime.now();
  final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
  CalendarEvent? melhor;
  DateTime? melhorData;
  for (final e in eventos) {
    // Evento real do calendário sempre vem com ano (extraído do PDF
    // oficial); sem ano, não há como saber se já passou ou não, então não
    // arriscamos "adivinhar" rolando pro próximo ano — é descartado.
    if (e.year == null) continue;
    final mesIndex = mesesAbrevPt.indexWhere((m) => m.toLowerCase() == e.month.toLowerCase());
    if (mesIndex == -1) continue;
    final dia = int.tryParse(e.day);
    if (dia == null) continue;
    final data = DateTime(e.year!, mesIndex + 1, dia);
    if (data.isBefore(hojeSemHora)) continue; // prazo já passou: não lista
    if (melhor == null || data.isBefore(melhorData!)) {
      melhor = e;
      melhorData = data;
    }
  }
  if (melhor == null || melhorData == null) {
    return const _StatusMatricula(
      desc: _descSemPeriodo,
      badge: AppBadge(label: 'Indisponível', color: BadgeColor.gray),
      disponivel: false,
    );
  }
  final diasRestantes = DateTime(melhorData.year, melhorData.month, melhorData.day)
      .difference(DateTime(hoje.year, hoje.month, hoje.day))
      .inDays;
  final badge = diasRestantes <= 7
      ? const AppBadge(label: 'Últimos dias', color: BadgeColor.yellow)
      : const AppBadge(label: 'Em breve', color: BadgeColor.blue);
  return _StatusMatricula(
    desc: '${melhor.title} · ${descreverPrazo(melhorData, hoje)}',
    badge: badge,
    disponivel: true,
  );
}

class DiscenteScreen extends StatelessWidget {
  const DiscenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventosAjuste = eventosMatricula.where((e) => _palavrasAjuste.any((p) => e.title.toLowerCase().contains(p))).toList();
    final eventosGeral = eventosMatricula.where((e) => !_palavrasAjuste.any((p) => e.title.toLowerCase().contains(p))).toList();
    final statusMatricula = _statusDoEvento(eventosGeral);
    final statusAjuste = _statusDoEvento(eventosAjuste);
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Início', onTap: () => Navigator.of(context).pop()),
            Text('Área do Discente', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Sua grade fica no app. Serviços restritos abrem no SIG@ oficial.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 18),
            _SigaItem(
              icon: '🗓️',
              iconBg: AppColors.blueSoft,
              title: 'Minha Grade de Horários',
              desc: 'Envie o print do SIG@ e o app organiza sua agenda',
              trailing: const AppBadge(label: 'No app', color: BadgeColor.blue),
              onTap: () {
                final auth = AuthScope.of(context);
                if (!auth.loggedIn) {
                  showUmToast(context, 'Faça login para enviar e acessar sua grade de horários.');
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => auth.hasGrade ? const GradeResultScreen() : const GradeUploadScreen(),
                  ),
                );
              },
            ),
            _SigaItem(
              icon: '📊',
              iconBg: AppColors.soft2,
              title: 'Notas e Boletins',
              desc: 'Consulta no portal oficial SIG@',
              trailing: const Text('↗', style: TextStyle(fontSize: 16, color: AppColors.ink2)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RedirectNotasScreen())),
            ),
            _SigaItem(
              icon: '📜',
              iconBg: AppColors.soft2,
              title: 'Histórico Escolar',
              desc: 'Consulta no SIG@ · Solicitação na SRCA/Colegiado',
              trailing: const Text('↗', style: TextStyle(fontSize: 16, color: AppColors.ink2)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RedirectHistoricoScreen())),
            ),
            _SigaItem(
              icon: '✏️',
              iconBg: AppColors.soft2,
              title: 'Matrícula',
              desc: statusMatricula.desc,
              trailing: statusMatricula.badge,
              onTap: () => showUmToast(
                context,
                statusMatricula.disponivel
                    ? '${statusMatricula.desc}. Faça a solicitação pelo SIG@.'
                    : 'Consulte o período de matrícula vigente diretamente no SIG@.',
              ),
            ),
            _SigaItem(
              icon: '🔀',
              iconBg: AppColors.yellowSoft,
              title: 'Modificação de Matrícula',
              desc: statusAjuste.desc,
              trailing: statusAjuste.badge,
              onTap: () => showUmToast(
                context,
                statusAjuste.disponivel
                    ? '${statusAjuste.desc}. Faça a solicitação pelo SIG@ ou presencialmente na SRCA.'
                    : 'Consulte o período de ajuste de matrícula vigente diretamente no SIG@.',
              ),
            ),
            if (sigaAvisos.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('AVISOS DO SIG@', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
              const SizedBox(height: 4),
              const Text(
                'Coletados da tela pública de acesso — não exigem login.',
                style: TextStyle(fontSize: 11.5, color: AppColors.ink2),
              ),
              const SizedBox(height: 12),
              for (final aviso in sigaAvisos)
                AppCard(
                  child: Text(aviso, style: const TextStyle(fontSize: 12.5, height: 1.5)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SigaItem extends StatelessWidget {
  const _SigaItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.desc,
    required this.trailing,
    required this.onTap,
  });

  final String icon;
  final Color iconBg;
  final String title;
  final String desc;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 13),
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(15)),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 19)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
