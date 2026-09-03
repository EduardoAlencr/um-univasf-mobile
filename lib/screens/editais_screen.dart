import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import '../navigation/go_profile.dart';

class EditaisScreen extends StatefulWidget {
  const EditaisScreen({super.key});

  @override
  State<EditaisScreen> createState() => _EditaisScreenState();
}

class _EditaisScreenState extends State<EditaisScreen> {
  String? _filtroSetor;

  BadgeColor _badgeColor(String key) {
    switch (key) {
      case 'blue':
        return BadgeColor.blue;
      case 'green':
        return BadgeColor.green;
      case 'yellow':
        return BadgeColor.yellow;
      default:
        return BadgeColor.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final setores = editais.map((e) => e.setor).toSet().toList()..sort();
    final visiveis = _filtroSetor == null ? editais : editais.where((e) => e.setor == _filtroSetor).toList();

    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Início', onTap: () => Navigator.of(context).pop()),
            Text('Editais e Programas', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Agregador dos setores — sempre com link para a fonte oficial.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltroChip(label: 'Todos', selecionado: _filtroSetor == null, onTap: () => setState(() => _filtroSetor = null)),
                  for (final s in setores)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FiltroChip(label: s, selecionado: _filtroSetor == s, onTap: () => setState(() => _filtroSetor = s)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (visiveis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Nenhum edital encontrado para esse setor.', style: TextStyle(fontSize: 12.5, color: AppColors.ink2)),
              ),
            ...visiveis.map((e) => AppCard(
                  onTap: () => showUmToast(context, 'Abrindo edital no site da ${e.setor}…'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppBadge(label: e.setor, color: _badgeColor(e.setorColor)),
                          Text(e.prazo, style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(e.titulo, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(e.desc, style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.5)),
                      SourceTag(text: e.fonte),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({required this.label, required this.selecionado, required this.onTap});

  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? AppColors.blue : AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: selecionado ? Colors.transparent : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selecionado ? Colors.white : AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
