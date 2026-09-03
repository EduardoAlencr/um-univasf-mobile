import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/um_app_bar.dart';
import '../navigation/go_profile.dart';

class TermosScreen extends StatelessWidget {
  const TermosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UmAppBar(onAvatarTap: () => goProfile(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackRow(label: 'Voltar', onTap: () => Navigator.of(context).pop()),
            Text('Termos de Uso e Privacidade', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Versão 1.0 · Agosto de 2026 · Em conformidade com a LGPD (Lei nº 13.709/2018)',
              style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.45),
            ),
            const SizedBox(height: 10),
            const _Term(
              title: '1. O que é o UM · UNIVASF Mobile',
              body:
                  'Aplicativo que centraliza informações públicas da UNIVASF (cardápio do RU, ônibus, calendário acadêmico, editais e avisos) coletadas automaticamente dos sites oficiais, e que redireciona serviços restritos (notas, histórico, matrícula) para o portal oficial SIG@.',
            ),
            const _Term(
              title: '2. O que você acessa sem criar conta',
              body:
                  'Todos os dados públicos: avisos, cardápio do RU, transporte, editais, contatos dos setores e os atalhos de redirecionamento ao SIG@. Nenhum dado pessoal é exigido para esse uso.',
            ),
            const _Term(
              title: '3. O que exige login',
              body:
                  'Apenas o Calendário pessoal (sua agenda individual de prazos e lembretes) e a Grade de horários enviada por você exigem conta, pois são dados individuais de cada usuário. Cada conta vê somente os próprios dados.',
            ),
            const _Term(
              title: '4. Dados que coletamos',
              body:
                  'Com conta: e-mail institucional e nome, apenas para identificar sua agenda.\nEnviados por você: o print da grade de horários, usado unicamente para montar sua agenda pessoal.\nNunca coletamos: senha do SIG@, notas, histórico ou qualquer dado acadêmico restrito.',
            ),
            const _Term(
              title: '5. Como seus dados são protegidos',
              body:
                  'Arquivos enviados ficam criptografados e vinculados somente à sua conta. Você pode excluir sua grade e sua conta a qualquer momento em Perfil → Excluir meus dados, com remoção imediata e definitiva.',
            ),
            const _Term(
              title: '6. Seus direitos (LGPD, art. 18)',
              body:
                  'Você pode solicitar a qualquer momento: confirmação de tratamento, acesso, correção, anonimização, portabilidade, eliminação dos seus dados e revogação do consentimento, pelo canal de contato abaixo.',
            ),
            const _Term(
              title: '7. Fontes e responsabilidade',
              body:
                  'As informações públicas exibem a fonte oficial e a data da última atualização. Se uma coleta automática falhar, o app avisa que o dado pode estar desatualizado e oferece o link oficial. O app é um projeto acadêmico (TCC) e não substitui os canais oficiais da UNIVASF.',
            ),
            const _Term(
              title: '8. Redirecionamentos ao SIG@',
              body:
                  'Ao tocar em "Abrir SIG@", você sai do app e é atendido pelo portal oficial, que possui termos e política próprios. O app não intermedeia nem armazena esse acesso.',
            ),
            const _Term(
              title: '9. Contato do encarregado de dados',
              body: '📧 privacidade@um-univasf.app.br\nProjeto de TCC · Engenharia de Computação · UNIVASF, Campus Juazeiro.',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: AppColors.yellowSoft, border: Border.all(color: const Color(0xFFF2DF9B)), borderRadius: BorderRadius.circular(16)),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '🛡️ '),
                    TextSpan(text: 'Resumo em uma frase: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: 'dados públicos para todos, dados pessoais só seus, senha do SIG@ nunca.'),
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

class _Term extends StatelessWidget {
  const _Term({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          ),
          Text(body, style: const TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.6)),
        ],
      ),
    );
  }
}
