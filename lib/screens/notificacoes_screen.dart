import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../util/abrir_link.dart';
import '../widgets/app_card.dart';

/// Feed de notícias agregando todos os setores (PROAE, PROEX, PROEN, ...),
/// com scroll infinito: carrega um lote inicial e vai revelando mais itens
/// conforme o usuário rola até perto do fim da lista.
class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  static const _lote = 10;
  static const _softColors = [AppColors.orangeSoft, AppColors.yellowSoft, AppColors.redSoft, AppColors.blueSoft];

  final _scrollController = ScrollController();
  int _visivel = _lote;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_visivel >= allNotices.length) return;
    final proximoDoFim = _scrollController.position.maxScrollExtent - _scrollController.position.pixels < 300;
    if (proximoDoFim) {
      setState(() => _visivel = (_visivel + _lote).clamp(0, allNotices.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = allNotices.take(_visivel).toList();
    final temMais = _visivel < allNotices.length;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      itemCount: itens.length + 2, // cabeçalho + itens + rodapé de loading/fim
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notícias', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                const Text(
                  'Agregador de notícias de todos os setores, com link para a fonte oficial.',
                  style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
                ),
              ],
            ),
          );
        }

        if (index == itens.length + 1) {
          if (!temMais) return const SizedBox.shrink();
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blue),
              ),
            ),
          );
        }

        final n = itens[index - 1];
        return AppCard(
          onTap: () => abrirLink(context, n.url),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: _softColors[n.iconBg % _softColors.length], borderRadius: BorderRadius.circular(14)),
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
        );
      },
    );
  }
}
