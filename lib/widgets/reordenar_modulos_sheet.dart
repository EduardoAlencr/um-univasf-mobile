import 'package:flutter/material.dart';
import '../data/home_modulos.dart';
import '../theme/app_theme.dart';

/// Abre o modal de reordenação dos módulos da Home. Retorna a nova ordem
/// (lista de chaves) se o usuário confirmar, ou `null` se cancelar.
Future<List<String>?> abrirReordenarModulos(BuildContext context, List<String> ordemAtual) {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _ReordenarModulosSheet(ordemInicial: ordemAtual),
  );
}

class _ReordenarModulosSheet extends StatefulWidget {
  const _ReordenarModulosSheet({required this.ordemInicial});
  final List<String> ordemInicial;

  @override
  State<_ReordenarModulosSheet> createState() => _ReordenarModulosSheetState();
}

class _ReordenarModulosSheetState extends State<_ReordenarModulosSheet> {
  final List<String> _ordem = [];

  @override
  void initState() {
    super.initState();
    _ordem.addAll(widget.ordemInicial);
  }

  ModuloHome _moduloPorChave(String chave) => modulosDisponiveis.firstWhere((m) => m.key == chave);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Reordenar módulos', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text(
              'Arraste pelo ícone ☰ para mudar a ordem dos atalhos na tela inicial.',
              style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.4),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final chave = _ordem.removeAt(oldIndex);
                    _ordem.insert(newIndex, chave);
                  });
                },
                children: [
                  for (final chave in _ordem)
                    _ModuloTile(key: ValueKey(chave), modulo: _moduloPorChave(chave)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.ink2, fontWeight: FontWeight.w700)),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                    onPressed: () => Navigator.of(context).pop(_ordem),
                    child: const Text('Salvar ordem'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuloTile extends StatelessWidget {
  const _ModuloTile({required super.key, required this.modulo});
  final ModuloHome modulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: modulo.bg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(modulo.icon, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: Text(modulo.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          ),
          const Icon(Icons.drag_handle_rounded, color: AppColors.ink2),
        ],
      ),
    );
  }
}
