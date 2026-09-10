import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../navigation/go_profile.dart';

const _diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

const _iconesPorPeriodo = {
  'café da manhã': '☕',
  'almoço': '🍽️',
  'jantar': '🌙',
};

class RuScreen extends StatelessWidget {
  const RuScreen({super.key});

  bool _ehHoje(String label) {
    final hojeNome = _diasSemana[DateTime.now().weekday - 1];
    return label.toLowerCase().contains(hojeNome.toLowerCase());
  }

  String? _periodoVigente() {
    for (final d in ruDays) {
      if (d.badge != null) return d.badge;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final periodo = _periodoVigente();

    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Início', onTap: () => Navigator.of(context).pop()),
            Text('Restaurante Universitário', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Cardápio da semana', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
                if (periodo != null) ...[
                  const SizedBox(width: 8),
                  AppBadge(label: periodo, color: BadgeColor.yellow),
                ],
              ],
            ),
            const SizedBox(height: 18),
            ...ruDays.map((day) {
              final hoje = _ehHoje(day.label);
              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(day.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                        if (hoje) const AppBadge(label: 'Hoje', color: BadgeColor.blue),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < day.meals.length; i++)
                      Container(
                        decoration: i == 0
                            ? null
                            : const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                        child: _RefeicaoBloco(meal: day.meals[i]),
                      ),
                  ],
                ),
              );
            }),
            if (ruLegenda != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  ruLegenda!,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.ink2, height: 1.5),
                ),
              ),
            const SourceTag(text: 'Atualizado automaticamente · site da PROAE · hoje, 06:00'),
          ],
        ),
      ),
    );
  }
}

class _RefeicaoBloco extends StatelessWidget {
  const _RefeicaoBloco({required this.meal});
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final icone = _iconesPorPeriodo[meal.time.toLowerCase()] ?? '🍴';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icone, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                meal.time,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.blueDark),
              ),
            ],
          ),
          if (meal.itens.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 24),
              child: Text(meal.what, style: const TextStyle(fontSize: 13, height: 1.4)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: meal.itens
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.ink),
                            children: [
                              TextSpan(
                                text: '${item.categoria}: ',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink2),
                              ),
                              TextSpan(text: item.prato),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
