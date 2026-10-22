import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/bus_screen.dart';
import '../screens/discente_screen.dart';
import '../screens/editais_screen.dart';
import '../screens/ru_screen.dart';
import '../theme/app_theme.dart';

/// Um módulo de atalho da tela inicial — chave estável (`key`) usada só
/// pra persistir a ordem escolhida pelo usuário, nunca exibida.
class ModuloHome {
  const ModuloHome({required this.key, required this.icon, required this.bg, required this.title, required this.desc, required this.builder});

  final String key;
  final String icon;
  final Color bg;
  final String title;
  final String desc;
  final WidgetBuilder builder;
}

final modulosDisponiveis = <ModuloHome>[
  ModuloHome(
    key: 'discente',
    icon: '🎓',
    bg: AppColors.blueSoft,
    title: 'Discente',
    desc: 'Grade de horários e atalhos do SIG@',
    builder: (_) => const DiscenteScreen(),
  ),
  ModuloHome(
    key: 'restaurante',
    icon: '🍽️',
    bg: AppColors.yellowSoft,
    title: 'Restaurante',
    desc: 'Cardápio do RU atualizado',
    builder: (_) => const RuScreen(),
  ),
  ModuloHome(
    key: 'transporte',
    icon: '🚌',
    bg: AppColors.greenSoft,
    title: 'Transporte',
    desc: 'Rotas e horários dos ônibus',
    builder: (_) => const BusScreen(),
  ),
  ModuloHome(
    key: 'editais',
    icon: '📢',
    bg: AppColors.orangeSoft,
    title: 'Editais',
    desc: 'PROAE, PROEN, PROEX e mais',
    builder: (_) => const EditaisScreen(),
  ),
];

const _chavePrefs = 'home_modulos_ordem';

/// Ordem salva pelo usuário (reordenação da tela inicial). Sempre contém
/// todas as chaves de [modulosDisponiveis] — chaves desconhecidas (de uma
/// versão antiga) são descartadas, e módulos novos entram no fim, pra
/// nunca quebrar com uma lista salva desatualizada.
Future<List<String>> carregarOrdemModulos() async {
  final prefs = await SharedPreferences.getInstance();
  final chaves = modulosDisponiveis.map((m) => m.key).toList();
  final salvo = prefs.getStringList(_chavePrefs);
  if (salvo == null) return chaves;

  final ordem = salvo.where(chaves.contains).toList();
  for (final chave in chaves) {
    if (!ordem.contains(chave)) ordem.add(chave);
  }
  return ordem;
}

Future<void> salvarOrdemModulos(List<String> ordem) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_chavePrefs, ordem);
}
