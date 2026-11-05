import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_app_bar.dart';
import '../widgets/um_toast.dart';
import '../navigation/go_profile.dart';

/// Colegiados por campus/curso + Ouvidoria/NAI — citados do Guia do
/// Estudante (Proen, 3ª ed., fev/2026), já que não há página individual
/// raspável por colegiado. Emails de biblioteca/SIC por campus e das
/// pró-reitorias já aparecem em outros grupos desta tela — não repetidos
/// aqui.
const _colegiadosPorCampus = {
  'Campus Sede (Petrolina)': [
    ContatoSetor(setor: 'Biblioteca Sede', email: 'biblioteca@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Administração', email: 'cadm@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Educação Física', email: 'cefis@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Enfermagem', email: 'cenf@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Farmácia', email: 'cfarm@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Medicina', email: 'cmed.petrolina@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Psicologia', email: 'cpsi@univasf.edu.br'),
  ],
  'Campus Ciências Agrárias': [
    ContatoSetor(setor: 'Biblioteca CCA', email: 'biblioteca.fazenda@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Ciências Biológicas', email: 'ccbio@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Engenharia Agronômica', email: 'ceagro@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Medicina Veterinária', email: 'cmvet@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Zootecnia', email: 'czoo@univasf.edu.br'),
  ],
  'Campus Juazeiro': [
    ContatoSetor(setor: 'Biblioteca Juazeiro', email: 'biblioteca.juazeiro@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Artes Visuais', email: 'cartes@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Ciências Sociais', email: 'ccsociais@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Engenharia Agrícola e Ambiental', email: 'cenamb@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Engenharia Civil', email: 'ccivil@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Engenharia da Computação', email: 'cecomp@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Engenharia de Produção', email: 'cprod@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Engenharia Elétrica', email: 'cenel@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Engenharia Mecânica', email: 'cenmec@univasf.edu.br'),
  ],
  'Campus Serra da Capivara': [
    ContatoSetor(setor: 'Biblioteca Serra da Capivara', email: 'biblioteca.srn@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Antropologia', email: 'antropologia@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Arqueologia e Preservação Patrimonial', email: 'arqueologia@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Ciências da Natureza', email: 'ccinatsrn@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Química', email: 'cliq.srn@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Gestão Ambiental', email: 'colgestaoambiental@univasf.edu.br'),
  ],
  'Campus Senhor do Bonfim': [
    ContatoSetor(setor: 'Biblioteca Senhor do Bonfim', email: 'biblioteca.sbf@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Ciências da Natureza', email: 'ccinat.bonfim@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Ecologia', email: 'cecologia@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Geografia', email: 'cgeografia@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Geologia', email: 'geologia@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de História', email: 'cohis@univasf.edu.br'),
  ],
  'Campus Paulo Afonso': [
    ContatoSetor(setor: 'Biblioteca Paulo Afonso', email: 'biblioteca.paf@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Medicina', email: 'cmed.pauloafonso@univasf.edu.br'),
  ],
  'Campus Salgueiro': [
    ContatoSetor(setor: 'Biblioteca Salgueiro', email: 'biblioteca.salgueiro@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Ciência da Computação', email: 'cicomp.salgueiro@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Engenharia de Produção', email: 'cprod.salgueiro@univasf.edu.br'),
  ],
  'Cursos EAD': [
    ContatoSetor(setor: 'Colegiado de Administração Pública', email: 'curso-ap@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Ciências Biológicas', email: 'biologia.ead@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Ciência da Computação', email: 'computacao.ead@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Educação Física', email: 'educacaofisica.ead@univasf.edu.br'),
    ContatoSetor(setor: 'Colegiado de Pedagogia', email: 'pedagogiaead@univasf.edu.br'),
  ],
};

const _outrosSetores = [
  ContatoSetor(setor: 'Ouvidoria', email: 'ouvidoria@univasf.edu.br'),
  ContatoSetor(setor: 'Núcleo de Acessibilidade e Inclusão (NAI)', email: 'nai.gr@univasf.edu.br'),
];

/// Diretório geral de contatos por setor — PROAE, PROEX, PROEN e os
/// setores internos da SRCA — coletado das páginas oficiais de contato de
/// cada um. Útil mesmo fora do contexto de uma tela específica (ex. quem
/// não está vendo Auxílios ou Solicitações, mas só quer o e-mail da PROEN).
class ContatosUniversidadeScreen extends StatelessWidget {
  const ContatosUniversidadeScreen({super.key});

  Future<void> _enviarEmail(BuildContext context, String? email) async {
    if (email == null) return;
    final uri = Uri(scheme: 'mailto', path: email);
    final aberto = await launchUrl(uri);
    if (!aberto && context.mounted) {
      showUmToast(context, 'Não foi possível abrir o app de e-mail. Copie: $email');
    }
  }

  Widget _grupo(BuildContext context, String titulo, List<ContatoSetor> contatos) {
    if (contatos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                for (final c in contatos)
                  GestureDetector(
                    onTap: () => _enviarEmail(context, c.email),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: c != contatos.last ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.setor, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                if (c.email != null) ...[
                                  const SizedBox(height: 3),
                                  Text(c.email!, style: const TextStyle(fontSize: 11.5, color: AppColors.blueDark)),
                                ],
                                if (c.telefone != null) ...[
                                  const SizedBox(height: 3),
                                  Text('📞 ${c.telefone}', style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4)),
                                ],
                                if (c.texto != null && c.email == null) ...[
                                  const SizedBox(height: 3),
                                  Text(c.texto!, style: const TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.4)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (c.email != null) const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.blueDark),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nenhumContato = contatosProae.isEmpty && contatosProex.isEmpty && contatosProen.isEmpty && srcaAtendimentoInterno.isEmpty;
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Perfil', onTap: () => Navigator.of(context).pop()),
            Text('Contatos da Universidade', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'E-mails e telefones por setor, coletados das páginas oficiais de cada pró-reitoria.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 18),
            if (nenhumContato)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Contatos indisponíveis no momento.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink2),
                ),
              ),
            _grupo(context, 'PROAE — ASSISTÊNCIA ESTUDANTIL', contatosProae),
            _grupo(context, 'PROEN — ENSINO', contatosProen),
            _grupo(context, 'PROEX — EXTENSÃO', contatosProex),
            _grupo(context, 'SRCA — REGISTRO E CONTROLE ACADÊMICO', srcaAtendimentoInterno),
            _grupo(context, 'OUTROS SETORES', _outrosSetores),
            const Text('COLEGIADOS POR CAMPUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.ink2)),
            const SizedBox(height: 2),
            const Text(
              'Biblioteca e colegiados de curso — não têm página individual raspável, por isso vêm do Guia do Estudante.',
              style: TextStyle(fontSize: 11, color: AppColors.ink2),
            ),
            const SizedBox(height: 10),
            for (final campus in _colegiadosPorCampus.entries) _grupo(context, campus.key.toUpperCase(), campus.value),
            const SourceTag(text: 'Colegiados: Guia do Estudante, Proen (3ª ed., fev/2026)', topPadding: 2),
          ],
        ),
      ),
    );
  }
}
