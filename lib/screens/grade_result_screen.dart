import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/pill_button.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import '../navigation/go_profile.dart';
import 'grade_upload_screen.dart';

class GradeResultScreen extends StatelessWidget {
  const GradeResultScreen({super.key});

  ClassEntry? _entryFor(int? index) => index == null ? null : classLegend[index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Discente', onTap: () => Navigator.of(context).pop()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Minha Agenda', style: Theme.of(context).textTheme.headlineMedium),
                const AppBadge(label: '2026.2', color: BadgeColor.yellow),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Engenharia de Computação · Gerada do seu print do SIG@ · só você vê 🔒',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 18),
            _Mural(entryFor: _entryFor),
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 8, 2, 16),
              child: Text('Toque em um horário para ver os detalhes da disciplina.', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
            ),
            const SectionTitle('Legenda das disciplinas'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                children: classLegend
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 28,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: c.isSaturday ? AppColors.yellow : AppColors.blueSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  c.code,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: c.isSaturday ? AppColors.ink : AppColors.blueDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                    Text(
                                      '${c.details} · ${c.room}${c.isSaturday ? ' · Sábado' : ''} · Confirmada',
                                      style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            PillButton(
              label: '↑ Enviar novo print',
              variant: PillButtonVariant.secondary,
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Substituir sua grade atual?',
                  message: 'A grade enviada agora vai substituir a agenda que você já tem no app.',
                  confirmLabel: 'Enviar novo print',
                );
                if (!confirmed || !context.mounted) return;
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GradeUploadScreen()));
              },
            ),
            PillButton(
              label: '🗑 Excluir minha grade',
              variant: PillButtonVariant.secondary,
              foregroundColorOverride: const Color(0xFFB3402F),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Excluir sua grade de horários?',
                  message: 'Sua agenda montada a partir do print será apagada. Você pode enviar um novo print depois, a qualquer momento.',
                  confirmLabel: 'Excluir',
                  destructive: true,
                );
                if (!confirmed || !context.mounted) return;
                AuthScope.of(context).setHasGrade(false);
                showUmToast(context, 'Grade excluída da sua conta.');
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GradeUploadScreen()));
              },
            ),
            const SourceTag(text: 'Dado pessoal · armazenado apenas na sua conta', topPadding: 4),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
    );
  }
}

class _Mural extends StatelessWidget {
  const _Mural({required this.entryFor});
  final ClassEntry? Function(int?) entryFor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 46),
              for (int i = 0; i < weekDays.length; i++)
                Expanded(
                  child: Container(
                    color: i == todayColumnIndex ? AppColors.blue : AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Text(
                      weekDays[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: i == todayColumnIndex ? Colors.white : Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final slot in timeSlots)
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 46,
                      color: AppColors.soft,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(slot, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.ink2), textAlign: TextAlign.center),
                    ),
                    for (int i = 0; i < weekDays.length; i++)
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 46),
                          padding: const EdgeInsets.all(3),
                          color: i == todayColumnIndex ? AppColors.blue.withValues(alpha: 0.08) : null,
                          child: _buildCell(context, weeklyGrid[slot]![i]),
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

  Widget _buildCell(BuildContext context, int? index) {
    if (index == null) return const SizedBox.shrink();
    final entry = entryFor(index);
    final isSat = entry?.isSaturday ?? false;
    return Material(
      color: isSat ? AppColors.yellow : AppColors.blueSoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: entry == null
            ? null
            : () => showUmToast(
                  context,
                  '${entry.details} · ${entry.name} · Turma ${entry.code} · ${entry.room} · CONFIRMADA',
                ),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 38),
          child: Text(
            entry!.code,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: isSat ? AppColors.ink : AppColors.blueDark),
          ),
        ),
      ),
    );
  }
}
