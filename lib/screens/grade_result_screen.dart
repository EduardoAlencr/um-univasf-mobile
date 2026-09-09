import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../data/grade_arquivo.dart';
import '../data/grade_parser.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/pill_button.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import '../navigation/go_profile.dart';
import 'grade_upload_screen.dart';

class GradeResultScreen extends StatefulWidget {
  const GradeResultScreen({super.key});

  @override
  State<GradeResultScreen> createState() => _GradeResultScreenState();
}

class _GradeResultScreenState extends State<GradeResultScreen> {
  late Future<GradeArquivo?> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<GradeArquivo?> _carregar() async {
    final uid = AuthScope.of(context).user?.uid;
    if (uid == null) return null;
    return lerGradeArquivo(uid);
  }

  Future<void> _abrir(GradeArquivo arquivo) async {
    try {
      final dir = await getTemporaryDirectory();
      final caminho = '${dir.path}/${arquivo.nomeArquivo}';
      await File(caminho).writeAsBytes(arquivo.bytes);
      final resultado = await OpenFilex.open(caminho);
      if (resultado.type != ResultType.done && mounted) {
        showUmToast(context, 'Não foi possível abrir o arquivo (${resultado.message}).');
      }
    } catch (_) {
      if (mounted) showUmToast(context, 'Não foi possível abrir o arquivo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: FutureBuilder<GradeArquivo?>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.blue));
          }
          final arquivo = snapshot.data;
          if (arquivo == null) {
            // Estado inconsistente (ex. flag "hasGrade" ficou true sem
            // arquivo salvo) — corrige a flag e oferece ir direto pro envio.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AuthScope.of(context).setHasGrade(false);
            });
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nenhuma grade enviada ainda.', style: TextStyle(color: AppColors.ink2)),
                    const SizedBox(height: 16),
                    PillButton(
                      label: 'Enviar minha grade',
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const GradeUploadScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackRow(label: 'Discente', onTap: () => Navigator.of(context).pop()),
                if (arquivo.parseada != null && arquivo.parseada!.temAulas)
                  ..._conteudoGradeMontada(arquivo.parseada!)
                else
                  ..._conteudoSomenteArquivo(arquivo),
                _CardArquivo(arquivo: arquivo, onAbrir: () => _abrir(arquivo)),
                PillButton(
                  label: '↑ Enviar novo arquivo',
                  variant: PillButtonVariant.secondary,
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Substituir sua grade atual?',
                      message: 'O arquivo enviado agora vai substituir o que você já tem no app.',
                      confirmLabel: 'Enviar novo arquivo',
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
                      message: 'O arquivo enviado será apagado. Você pode enviar um novo depois, a qualquer momento.',
                      confirmLabel: 'Excluir',
                      destructive: true,
                    );
                    if (!confirmed || !context.mounted) return;
                    final uid = AuthScope.of(context).user?.uid;
                    if (uid != null) await excluirGradeArquivo(uid);
                    if (!context.mounted) return;
                    await AuthScope.of(context).setHasGrade(false);
                    if (!context.mounted) return;
                    showUmToast(context, 'Grade excluída da sua conta.');
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GradeUploadScreen()));
                  },
                ),
                const SourceTag(text: 'Dado pessoal · armazenado apenas na sua conta', topPadding: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _conteudoSomenteArquivo(GradeArquivo arquivo) {
    final motivo = arquivo.mimeType == 'application/pdf'
        ? 'Não conseguimos montar sua grade automaticamente a partir desse PDF — o formato pode ser diferente do padrão do SIG@.'
        : 'Imagens não têm texto extraível, então a grade não é montada automaticamente — só o arquivo fica salvo.';
    return [
      Text('Minha Grade de Horários', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      const Text('Só você vê 🔒', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppColors.soft2, borderRadius: BorderRadius.circular(16)),
        child: Text(motivo, style: const TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.5)),
      ),
    ];
  }

  List<Widget> _conteudoGradeMontada(GradeParseada g) {
    final contexto = [g.curso, g.periodo, g.turno].where((s) => s != null && s.isNotEmpty).join(' · ');
    return [
      Text('Minha Agenda', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      Text(
        contexto.isEmpty ? 'Montada automaticamente a partir do seu PDF do SIG@ · só você vê 🔒' : '$contexto · só você vê 🔒',
        style: const TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
      ),
      const SizedBox(height: 18),
      _MuralGrade(grade: g),
      const Padding(
        padding: EdgeInsets.fromLTRB(2, 8, 2, 16),
        child: Text('Toque em um horário para ver os detalhes da disciplina.', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
      ),
      const _TituloSecao('Disciplinas'),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Column(
          children: g.disciplinas.entries
              .map((e) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 28,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text(
                            e.key.split('-').last,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.blueDark),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value.nome, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                              Text(
                                '${e.key.split('-').first} · ${e.value.sala}',
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
      const SizedBox(height: 4),
    ];
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(titulo.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
    );
  }
}

class _CardArquivo extends StatelessWidget {
  const _CardArquivo({required this.arquivo, required this.onAbrir});
  final GradeArquivo arquivo;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final tamanhoKb = (arquivo.bytes.length / 1024).toStringAsFixed(0);
    final data = arquivo.enviadoEm;
    final dataFormatada = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(arquivo.mimeType == 'application/pdf' ? '📄' : '🖼️', style: const TextStyle(fontSize: 20)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(arquivo.nomeArquivo, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('Enviado em $dataFormatada · ${tamanhoKb}KB', style: const TextStyle(fontSize: 11.5, color: AppColors.ink2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PillButton(label: 'Abrir arquivo original', variant: PillButtonVariant.secondary, onPressed: onAbrir),
        ],
      ),
    );
  }
}

class _MuralGrade extends StatelessWidget {
  const _MuralGrade({required this.grade});
  final GradeParseada grade;

  @override
  Widget build(BuildContext context) {
    final horas = grade.grade.keys.toList()..sort();
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
              for (final dia in GradeParseada.diasSemana)
                Expanded(
                  child: Container(
                    color: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Text(
                      dia.substring(0, 3),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          for (final hora in horas)
            if (grade.grade[hora]!.any((c) => c != null))
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
                        child: Text(hora, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.ink2), textAlign: TextAlign.center),
                      ),
                      for (final chave in grade.grade[hora]!)
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 46),
                            padding: const EdgeInsets.all(3),
                            child: chave == null ? null : _buildCell(context, chave),
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

  Widget _buildCell(BuildContext context, String chave) {
    final disciplina = grade.disciplinas[chave];
    return Material(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: disciplina == null
            ? null
            : () => showUmToast(context, '${disciplina.nome} · ${chave.split('-').first} turma ${chave.split('-').last} · ${disciplina.sala}'),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 38),
          child: Text(
            chave.split('-').last,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.blueDark),
          ),
        ),
      ),
    );
  }
}
