import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/um_toast.dart';

/// Abre [url] no navegador do sistema. Se [url] for nulo/vazio ou a
/// abertura falhar, mostra um toast em vez de deixar o toque sem efeito.
Future<void> abrirLink(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) {
    showUmToast(context, 'Link não disponível para esta notícia.');
    return;
  }
  final uri = Uri.tryParse(url);
  if (uri == null) {
    showUmToast(context, 'Não foi possível abrir o link.');
    return;
  }
  final aberto = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!aberto && context.mounted) {
    showUmToast(context, 'Não foi possível abrir o link.');
  }
}
