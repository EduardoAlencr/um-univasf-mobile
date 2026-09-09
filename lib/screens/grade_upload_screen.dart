import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/grade_arquivo.dart';
import '../data/grade_parser.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import '../navigation/go_profile.dart';
import 'grade_result_screen.dart';

class GradeUploadScreen extends StatefulWidget {
  const GradeUploadScreen({super.key});

  @override
  State<GradeUploadScreen> createState() => _GradeUploadScreenState();
}

class _GradeUploadScreenState extends State<GradeUploadScreen> {
  bool _enviando = false;

  Future<void> _selecionarEEnviar() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    final arquivo = resultado.files.single;
    final bytes = arquivo.bytes;
    if (bytes == null) {
      if (mounted) showUmToast(context, 'Não foi possível ler o arquivo selecionado.');
      return;
    }
    if (bytes.length > limiteBytesGrade) {
      if (mounted) {
        showUmToast(context, 'Arquivo muito grande (máx. ${(limiteBytesGrade / 1024).round()}KB). Envie um PDF/imagem de 1 página.');
      }
      return;
    }

    if (!mounted) return;
    final auth = AuthScope.of(context);
    final uid = auth.user?.uid;
    if (uid == null) return;

    setState(() => _enviando = true);
    try {
      final extensao = (arquivo.extension ?? 'pdf').toLowerCase();
      final mimeType = switch (extensao) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        _ => 'image/jpeg',
      };
      // Só PDF tem texto extraível — imagem (print) fica só guardada/aberta,
      // sem tentar montar a grade automaticamente (evita OCR impreciso).
      final parseada = mimeType == 'application/pdf' ? await parsearGradePdf(bytes) : null;
      await salvarGradeArquivo(uid, nomeArquivo: arquivo.name, mimeType: mimeType, bytes: bytes, parseada: parseada);
      await auth.setHasGrade(true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GradeResultScreen()));
    } catch (e) {
      if (mounted) showUmToast(context, 'Falha ao enviar o arquivo. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Discente', onTap: () => Navigator.of(context).pop()),
            Text('Minha Grade de Horários', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text('Exclusiva da sua conta — só você vê.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
              child: Column(
                children: const [
                  Text('🗓️', style: TextStyle(fontSize: 38)),
                  SizedBox(height: 10),
                  Text('Nenhuma grade enviada ainda', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text(
                    'Envie o PDF oficial exportado pelo SIG@ e o app monta sua agenda automaticamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.55),
                  ),
                ],
              ),
            ),
            const _PassoAPasso(),
            const SizedBox(height: 6),
            Material(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _enviando ? null : _selecionarEEnviar,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.blue, width: 2, style: BorderStyle.solid),
                  ),
                  child: _enviando
                      ? const Column(
                          children: [
                            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blue)),
                            SizedBox(height: 10),
                            Text('Lendo grade…', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                          ],
                        )
                      : const Column(
                          children: [
                            Text('📎', style: TextStyle(fontSize: 32)),
                            SizedBox(height: 8),
                            Text('Selecionar PDF ou imagem', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                            SizedBox(height: 3),
                            Text('PDF, JPG ou PNG · até 700KB', style: TextStyle(fontSize: 12, color: AppColors.ink2)),
                          ],
                        ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(color: AppColors.yellowSoft, border: Border.all(color: const Color(0xFFF2DF9B)), borderRadius: BorderRadius.circular(16)),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '🔒 '),
                    TextSpan(text: 'Privacidade: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: 'o arquivo fica vinculado apenas à sua conta e pode ser excluído a qualquer momento. Nada é compartilhado.'),
                  ],
                ),
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassoAPasso extends StatelessWidget {
  const _PassoAPasso();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('PASSO A PASSO NO SIG@', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
        ),
        AppCard(
          child: Column(
            children: const [
              _PassoItem(numero: 1, texto: 'Acesse o SIG@ e abra Consultas → Detalhamento de Discente → Grade de Horário.'),
              _PassoItem(numero: 2, texto: 'A página mostra sua grade da semana e a lista "Disciplinas Solicitadas" — é essa a tela certa.'),
              _PassoItem(numero: 3, texto: 'Use a opção de imprimir do navegador e escolha "Salvar como PDF" (não precisa imprimir de verdade).'),
              _PassoItem(numero: 4, texto: 'Envie esse PDF aqui embaixo. É esse arquivo, exportado direto do SIG@, que o app consegue ler automaticamente.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PassoItem extends StatelessWidget {
  const _PassoItem({required this.numero, required this.texto});
  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$numero', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.blueDark)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(texto, style: const TextStyle(fontSize: 13, height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }
}
