import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../navigation/go_profile.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key});

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  String? _turno; // null = Todos
  String? _letra; // null = Todos
  final _buscaController = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letras = onibusViagens.map((v) => v.letra).toSet().toList()..sort();
    final buscaLower = _busca.trim().toLowerCase();

    final visiveis = onibusViagens.where((v) {
      if (_turno != null && v.turno != _turno) return false;
      if (_letra != null && v.letra != _letra) return false;
      if (buscaLower.isEmpty) return true;
      if (v.rota.toLowerCase().contains(buscaLower)) return true;
      return v.paradas.any((p) => p.local.toLowerCase().contains(buscaLower));
    }).toList();

    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Início', onTap: () => Navigator.of(context).pop()),
            Text('Ônibus Universitários', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              itinerarioVigencia != null ? 'Transporte estudantil · PROAE · vigência $itinerarioVigencia' : 'Transporte estudantil · PROAE · 2026.2',
              style: const TextStyle(fontSize: 13, color: AppColors.ink2),
            ),
            if (itinerarioPublicadoEm != null) ...[
              const SizedBox(height: 3),
              Text(
                'Documento publicado em $itinerarioPublicadoEm — confira se há uma versão mais recente se algo parecer desatualizado.',
                style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4),
              ),
            ],
            const SizedBox(height: 16),
            _CampoBusca(
              controller: _buscaController,
              onChanged: (v) => setState(() => _busca = v),
            ),
            const SizedBox(height: 12),
            const Text('TURNO', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ink2, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltroChip(label: 'Todos', selecionado: _turno == null, onTap: () => setState(() => _turno = null)),
                  const SizedBox(width: 8),
                  _FiltroChip(label: 'Manhã', selecionado: _turno == 'Manhã', onTap: () => setState(() => _turno = 'Manhã')),
                  const SizedBox(width: 8),
                  _FiltroChip(label: 'Tarde', selecionado: _turno == 'Tarde', onTap: () => setState(() => _turno = 'Tarde')),
                  const SizedBox(width: 8),
                  _FiltroChip(label: 'Noite', selecionado: _turno == 'Noite', onTap: () => setState(() => _turno = 'Noite')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('ÔNIBUS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ink2, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltroChip(label: 'Todos', selecionado: _letra == null, onTap: () => setState(() => _letra = null)),
                  for (final l in letras)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FiltroChip(label: l, selecionado: _letra == l, onTap: () => setState(() => _letra = l)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (onibusViagens.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Carregando itinerário...', style: TextStyle(fontSize: 12.5, color: AppColors.ink2)),
              )
            else if (visiveis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Nenhuma viagem encontrada para esse filtro.', style: TextStyle(fontSize: 12.5, color: AppColors.ink2)),
              )
            else
              ...visiveis.map((v) => _ViagemCard(viagem: v, destaque: buscaLower)),
            const SourceTag(text: 'Itinerário PROAE 2026.2 · Transporte estudantil'),
          ],
        ),
      ),
    );
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13.5),
        decoration: const InputDecoration(
          hintText: 'Buscar por ponto (ex: Petrolina, Cohab...)',
          hintStyle: TextStyle(fontSize: 13, color: AppColors.ink2),
          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.ink2),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 4),
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
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: selecionado ? Colors.white : AppColors.ink2),
          ),
        ),
      ),
    );
  }
}

class _ViagemCard extends StatefulWidget {
  const _ViagemCard({required this.viagem, required this.destaque});
  final Viagem viagem;
  final String destaque;

  @override
  State<_ViagemCard> createState() => _ViagemCardState();
}

class _ViagemCardState extends State<_ViagemCard> {
  bool _aberto = false;

  @override
  void didUpdateWidget(covariant _ViagemCard old) {
    super.didUpdateWidget(old);
    if (widget.destaque.isNotEmpty && widget.destaque != old.destaque) {
      _aberto = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viagem;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _aberto = !_aberto),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text(v.letra, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                v.horarioSaida ?? '--:--',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.blueDark),
                              ),
                              const SizedBox(width: 6),
                              Text('· ${v.turno}', style: const TextStyle(fontSize: 11.5, color: AppColors.ink2)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v.rota,
                            style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.35),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(_aberto ? Icons.expand_less : Icons.expand_more, color: AppColors.ink2),
                  ],
                ),
              ),
            ),
          ),
          if (_aberto)
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final p in v.paradas)
                    _ParadaRow(parada: p, destacada: widget.destaque.isNotEmpty && p.local.toLowerCase().contains(widget.destaque)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ParadaRow extends StatelessWidget {
  const _ParadaRow({required this.parada, required this.destacada});
  final Parada parada;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: destacada ? AppColors.yellowSoft : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(parada.horario, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.blueDark)),
          ),
          Expanded(child: Text(parada.local, style: const TextStyle(fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }
}
