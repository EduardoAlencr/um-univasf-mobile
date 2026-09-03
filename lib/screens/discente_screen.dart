import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_badge.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import '../navigation/go_profile.dart';
import 'grade_result_screen.dart';
import 'grade_upload_screen.dart';
import 'login_screen.dart';
import 'redirect_notas_screen.dart';
import 'redirect_historico_screen.dart';

class DiscenteScreen extends StatelessWidget {
  const DiscenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              desc: 'Período oficial: 01/09 a 05/09',
              trailing: const AppBadge(label: 'Indisponível', color: BadgeColor.gray),
              onTap: () => showUmToast(
                context,
                'A matrícula abre em 01/09/2026. O app avisa você quando o período começar e direciona para o SIG@.',
              ),
            ),
            _SigaItem(
              icon: '🔀',
              iconBg: AppColors.yellowSoft,
              title: 'Modificação de Matrícula',
              desc: 'Ajuste encerra em 29/08',
              trailing: const AppBadge(label: 'Últimos dias', color: BadgeColor.yellow),
              onTap: () => showUmToast(
                context,
                'O ajuste de matrícula encerra em 29/08. Faça a solicitação pelo SIG@ ou presencialmente na SRCA.',
              ),
            ),
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
