import 'package:flutter/material.dart';
import '../data/home_modulos.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../util/data_pt.dart';
import '../widgets/app_card.dart';
import '../widgets/reordenar_modulos_sheet.dart';
import '../widgets/source_tag.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenNotif});

  final VoidCallback onOpenNotif;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _softColors = [AppColors.orangeSoft, AppColors.yellowSoft, AppColors.redSoft, AppColors.blueSoft];

  List<String> _ordemModulos = modulosDisponiveis.map((m) => m.key).toList();

  @override
  void initState() {
    super.initState();
    carregarOrdemModulos().then((ordem) {
      if (mounted) setState(() => _ordemModulos = ordem);
    });
  }

  Future<void> _reordenar() async {
    final novaOrdem = await abrirReordenarModulos(context, _ordemModulos);
    if (novaOrdem == null) return;
    setState(() => _ordemModulos = novaOrdem);
    await salvarOrdemModulos(novaOrdem);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Olá! 👋', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '${formatarDataCompleta(DateTime.now())} · acesso livre, sem login',
            style: const TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
          ),
          const SizedBox(height: 18),
          _Hero(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader('Módulos'),
              TextButton.icon(
                onPressed: _reordenar,
                icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.blueDark),
                label: const Text('Reordenar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.blueDark)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              for (final chave in _ordemModulos)
                for (final modulo in modulosDisponiveis.where((m) => m.key == chave))
                  _Module(
                    icon: modulo.icon,
                    bg: modulo.bg,
                    title: modulo.title,
                    desc: modulo.desc,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: modulo.builder)),
                  ),
            ],
          ),
          const SectionHeader('Notícias recentes'),
          ...homeNotices.map(
            (n) => AppCard(
              onTap: widget.onOpenNotif,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _softColors[n.iconBg],
                      borderRadius: BorderRadius.circular(14),
                    ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    CalendarEvent? proximoEvento;
    DateTime? proximaData;
    // Feriados e recessos não são "prazos" — mostrar um feriado aqui como
    // se fosse um prazo confunde o usuário, então só consideramos eventos
    // que de fato representam um compromisso/data-limite.
    for (final e in calendarEvents) {
      if (e.tag == 'feriado' || e.tag == 'recesso') continue;
      final data = proximaOcorrencia(e.day, e.month, hoje);
      if (data == null) continue;
      if (proximaData == null || data.isBefore(proximaData)) {
        proximaData = data;
        proximoEvento = e;
      }
    }

    final titulo = proximoEvento != null ? proximoEvento.title : 'Nenhum prazo no calendário no momento';
    final selo = proximaData != null
        ? 'PRÓXIMO PRAZO · ${descreverPrazo(proximaData, hoje).toUpperCase()}'
        : 'CALENDÁRIO ACADÊMICO';
    final desc = proximoEvento != null
        ? proximoEvento.desc
        : 'Consulte o calendário completo na aba Calendário.';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(color: AppColors.blue.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              selo,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.45),
          ),
          const SourceTag(
            text: 'Atualizado automaticamente · Calendário acadêmico oficial',
            dotColor: AppColors.yellow,
            topPadding: 12,
          ),
        ],
      ),
    );
  }
}

class _Module extends StatelessWidget {
  const _Module({required this.icon, required this.bg, required this.title, required this.desc, required this.onTap});

  final String icon;
  final Color bg;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.module),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.module),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.module),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}
