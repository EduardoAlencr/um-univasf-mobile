import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../util/abrir_link.dart';
import '../widgets/app_card.dart';
import '../widgets/source_tag.dart';

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
  String? _filtroSetor;

  List<Notice> get _itensFiltrados =>
      _filtroSetor == null ? allNotices : allNotices.where((n) => n.setor == _filtroSetor).toList();

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
    final total = _itensFiltrados.length;
    if (_visivel >= total) return;
    final proximoDoFim = _scrollController.position.maxScrollExtent - _scrollController.position.pixels < 300;
    if (proximoDoFim) {
      setState(() => _visivel = (_visivel + _lote).clamp(0, total));
    }
  }

  void _selecionarFiltro(String? setor) {
    setState(() {
      _filtroSetor = setor;
      _visivel = _lote;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _itensFiltrados;
    final itens = filtrados.take(_visivel).toList();
    final temMais = _visivel < filtrados.length;
    final setores = allNotices.map((n) => n.setor).toSet().toList()..sort();

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
                if (dadosAtualizadosEm != null) ...[
                  const SizedBox(height: 6),
                  Text(_formatarAtualizacao(dadosAtualizadosEm!), style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
                ],
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FiltroChip(label: 'Todos', selecionado: _filtroSetor == null, onTap: () => _selecionarFiltro(null)),
                      for (final s in setores)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FiltroChip(label: s, selecionado: _filtroSetor == s, onTap: () => _selecionarFiltro(s)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (itens.isEmpty && index == 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Nenhuma notícia encontrada para esse setor.', style: TextStyle(fontSize: 12.5, color: AppColors.ink2)),
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
                    if (n.when.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(n.when, style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
                    ],
                    SourceTag(text: 'Fonte oficial: ${n.setor}', dotColor: AppColors.blue, topPadding: 5),
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

String _formatarAtualizacao(DateTime data) {
  final local = data.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return 'Dados públicos atualizados em $dd/$mm às $hh:${min}h';
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
