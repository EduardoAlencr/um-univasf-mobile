import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/pill_button.dart';
import '../widgets/um_toast.dart';
import 'termos_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final hasGrade = auth.hasGrade;
    final nome = auth.user?.displayName?.isNotEmpty == true ? auth.user!.displayName! : 'Estudante UNIVASF';
    final email = auth.user?.email ?? 'sem e-mail';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meu Perfil', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('Sua conta e seus dados pessoais no app.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(email, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🗓️ Minha grade de horários', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                      SizedBox(height: 3),
                      Text('2026.2 · visível só para você', style: TextStyle(fontSize: 11.5, color: AppColors.ink2)),
                    ],
                  ),
                ),
                AppBadge(
                  label: hasGrade ? 'Ativa' : 'Não enviada',
                  color: hasGrade ? BadgeColor.green : BadgeColor.gray,
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              children: [
                _SettingRow(label: '🔔 Notificações de prazos', trailing: const AppBadge(label: 'Ativadas', color: BadgeColor.blue)),
                _SettingRow(
                  label: '🔒 Excluir meus dados do app',
                  trailing: GestureDetector(
                    onTap: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Excluir todos os seus dados?',
                        message:
                            'Sua grade de horários, calendário pessoal e dados de conta serão apagados permanentemente. Essa ação não pode ser desfeita.',
                        confirmLabel: 'Excluir tudo',
                        destructive: true,
                      );
                      if (confirmed && context.mounted) {
                        showUmToast(context, 'Solicitação de exclusão registrada. Seus dados serão removidos em até 24h.');
                      }
                    },
                    child: const Text('Excluir', style: TextStyle(color: Color(0xFFB3402F), fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  showBorder: false,
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              children: const [
                _SettingRow(label: 'ℹ️ Sobre o UM · UNIVASF Mobile', trailing: Text('v0.3 (MVP)', style: TextStyle(color: AppColors.ink2)), showBorder: false),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(16)),
            child: const Text.rich(
              TextSpan(children: [
                TextSpan(text: '🛡️ '),
                TextSpan(text: 'O app não armazena credenciais do SIG@. Dados sensíveis (como sua grade) existem apenas porque você os enviou — e só você os vê.'),
              ]),
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
          PillButton(
            label: '📜 Termos de Uso e Privacidade',
            variant: PillButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermosScreen())),
          ),
          PillButton(
            label: 'Sair da conta',
            variant: PillButtonVariant.dark,
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Sair da conta?',
                message: 'Você precisará entrar novamente para acessar seu calendário pessoal e sua grade de horários.',
                confirmLabel: 'Sair',
              );
              if (!confirmed || !context.mounted) return;
              AuthScope.of(context).logout();
              Navigator.of(context).popUntil((r) => r.isFirst);
              showUmToast(context, 'Você saiu. Os dados públicos continuam disponíveis sem login.');
            },
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.trailing, this.showBorder = true});
  final String label;
  final Widget trailing;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showBorder ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5)),
          trailing,
        ],
      ),
    );
  }
}
