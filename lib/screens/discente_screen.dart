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
import 'solicitacoes_screen.dart';
import 'auxilios_screen.dart';
import 'redirect_matricula_screen.dart';

const _descSemPeriodo = 'Consulte o período vigente no SIG@.';

const _tabelaFaltas = [
  ('30h', '7 faltas'),
  ('45h', '11 faltas'),
  ('60h', '15 faltas'),
  ('75h', '18 faltas'),
  ('90h', '22 faltas'),
  ('120h', '30 faltas'),
];

void _mostrarFrequencia(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📏 Frequência mínima', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              'Frequência mínima obrigatória de 75% da carga horária de cada disciplina. Passando de 25% de faltas, o discente é reprovado por falta no componente curricular como um todo — inclusive se a disciplina tiver carga teórica e prática separadas, o limite se aplica aos dois módulos de forma independente.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.5),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: AppColors.soft2),
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('Carga horária', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Faltas que reprovam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                  ],
                ),
                for (final linha in _tabelaFaltas)
                  TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(8), child: Text(linha.$1, style: const TextStyle(fontSize: 12.5))),
                      Padding(padding: const EdgeInsets.all(8), child: Text(linha.$2, style: const TextStyle(fontSize: 12.5))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fechar', style: TextStyle(color: AppColors.blueDark, fontWeight: FontWeight.w800)),
              ),
            ),
            const Text('Fonte: Guia do Estudante, Proen (3ª ed., fev/2026)', style: TextStyle(fontSize: 10.5, color: AppColors.ink2)),
          ],
        ),
      ),
    ),
  );
}

class _StatusMatricula {
  const _StatusMatricula({required this.desc, required this.badge, required this.disponivel});
  final String desc;
  final Widget badge;
  final bool disponivel;
}

/// Procura, entre os eventos de calendário com `tag == 'matricula'`
/// (matrícula, ajuste/modificação e trancamento — o calendário oficial não
/// distingue esses tipos, então também não dividimos aqui), o mais próximo
/// que ainda não passou. Só fica "disponível" (mostra data/prazo de verdade)
/// quando estiver a no máximo 7 dias — fora dessa janela, mesmo havendo um
/// evento real mais distante, o card fica "Indisponível" (não revela a
/// data com antecedência). Nunca inventa datas: sem evento real na janela
/// do scraper (~60 dias), cai no mesmo estado honesto "Indisponível".
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
  const indisponivel = _StatusMatricula(
    desc: _descSemPeriodo,
    badge: AppBadge(label: 'Indisponível', color: BadgeColor.gray),
    disponivel: false,
  );
  if (melhor == null || melhorData == null) return indisponivel;

  final diasRestantes = DateTime(melhorData.year, melhorData.month, melhorData.day)
      .difference(DateTime(hoje.year, hoje.month, hoje.day))
      .inDays;
  if (diasRestantes > 7) return indisponivel;

  return _StatusMatricula(
    desc: '${melhor.title} · ${descreverPrazo(melhorData, hoje)}',
    badge: const AppBadge(label: 'Últimos dias', color: BadgeColor.yellow),
    disponivel: true,
  );
}

class DiscenteScreen extends StatelessWidget {
  const DiscenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statusMatricula = _statusDoEvento(eventosMatricula);
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
              desc: 'Envie o PDF da grade do SIG@ e o app organiza sua agenda',
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
              icon: '🗂️',
              iconBg: AppColors.soft2,
              title: 'Solicitações da SRCA',
              desc: 'Catálogo de requerimentos (declarações, 2ª via, trancamento...)',
              trailing: const Text('→', style: TextStyle(fontSize: 16, color: AppColors.ink2)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SolicitacoesScreen())),
            ),
            _SigaItem(
              icon: '💰',
              iconBg: AppColors.greenSoft,
              title: 'Auxílios e Bolsas',
              desc: 'Permanência, alimentação e outros programas da PROAE',
              trailing: const Text('→', style: TextStyle(fontSize: 16, color: AppColors.ink2)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuxiliosScreen())),
            ),
            _SigaItem(
              icon: '✏️',
              iconBg: AppColors.soft2,
              title: 'Matrícula',
              desc: statusMatricula.desc,
              trailing: statusMatricula.badge,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RedirectMatriculaScreen())),
            ),
            _SigaItem(
              icon: '📏',
              iconBg: AppColors.soft2,
              title: 'Frequência mínima',
              desc: 'Regra dos 75% e a tabela de faltas por carga horária',
              trailing: const Text('→', style: TextStyle(fontSize: 16, color: AppColors.ink2)),
              onTap: () => _mostrarFrequencia(context),
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
