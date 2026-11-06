// Dados mockados usados pelo protótipo de alta fidelidade, espelhando
// exatamente os exemplos do protótipo HTML de referência.

class Notice {
  const Notice({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.desc,
    required this.when,
    this.url,
    this.setor = 'UNIVASF',
  });
  final String icon;
  final int iconBg; // índice de cor suave (ver AppColors soft variants)
  final String title;
  final String desc;
  final String when;
  final String? url;
  final String setor;
}

/// Avisos públicos da página inicial do SIG@ (sem login), coletados pelo
/// scraper. Vazio até o scraper rodar / não há mock de exemplo.
List<String> sigaAvisos = [];

/// Timestamp (`gerado_em` do JSON do scraper) da última vez que os dados
/// públicos foram raspados — nulo enquanto só os mocks estão em uso.
DateTime? dadosAtualizadosEm;

List<Notice> homeNotices = [
  Notice(
    icon: '🛠️',
    iconBg: 0,
    title: 'Manutenção no bloco de Engenharias',
    desc: 'Sábado, das 8h às 12h. Acesso pela entrada lateral.',
    when: 'há 2 horas · Comunicação institucional',
  ),
  Notice(
    icon: '🍽️',
    iconBg: 1,
    title: 'Cardápio do RU atualizado',
    desc: 'Nova semana disponível — inclui opção vegetariana diária.',
    when: 'hoje, 06:00 · Atualização automática',
  ),
];

List<Notice> allNotices = [
  Notice(
    icon: '⚠️',
    iconBg: 2,
    title: 'Ajuste de matrícula encerra em 3 dias',
    desc: 'Prazo final: 29/08. Solicite pelo SIG@ ou na SRCA.',
    when: 'Gerada do calendário acadêmico oficial',
  ),
  Notice(
    icon: '📢',
    iconBg: 3,
    title: 'Novo edital: Monitoria 2026.2',
    desc: 'PROEN abriu 40 vagas. Inscrições até 04/09.',
    when: 'há 5 horas · coletado do site da PROEN',
  ),
  Notice(
    icon: '🛠️',
    iconBg: 0,
    title: 'Manutenção no bloco de Engenharias',
    desc: 'Sábado, das 8h às 12h. Acesso pela entrada lateral.',
    when: 'há 2 horas · Comunicação institucional',
  ),
  Notice(
    icon: '🍽️',
    iconBg: 1,
    title: 'Cardápio do RU atualizado',
    desc: 'Nova semana disponível — opção vegetariana diária.',
    when: 'hoje, 06:00 · Atualização automática',
  ),
];

class ItemCardapio {
  const ItemCardapio({required this.categoria, required this.prato});
  final String categoria;
  final String prato;
}

class Meal {
  const Meal({required this.time, required this.what, this.itens = const []});
  final String time;

  /// Resumo curto (usado no mock e como fallback se o scraper não trouxer
  /// itens detalhados por algum motivo).
  final String what;

  /// Cardápio detalhado por categoria (proteína, vegetariano, salada,
  /// arroz, feijão, guarnição, molho, bebida, sobremesa...), quando vindo
  /// de dados reais.
  final List<ItemCardapio> itens;
}

class RuDay {
  const RuDay({required this.label, required this.badge, required this.meals});
  final String label;
  final String? badge;
  final List<Meal> meals;
}

/// Legenda dos asteriscos do cardápio (alergênicos etc.), raspada do rodapé
/// do PDF vigente. Nula quando o mock não tem uma (dados mockados não usam
/// marcação de alergênicos).
String? ruLegenda;

List<RuDay> ruDays = [
  RuDay(
    label: 'Hoje · Quarta-feira',
    badge: 'Almoço R\$ 2,00',
    meals: [
      Meal(time: 'Café 6h45', what: 'Cuscuz, ovos mexidos, café com leite'),
      Meal(time: 'Almoço 11h', what: 'Frango grelhado, arroz, feijão, salada, suco'),
      Meal(time: 'Jantar 17h30', what: 'Sopa de legumes, pão, fruta'),
    ],
  ),
  RuDay(
    label: 'Amanhã · Quinta-feira',
    badge: null,
    meals: [
      Meal(time: 'Almoço 11h', what: 'Carne de panela, macarrão, legumes'),
      Meal(time: 'Jantar 17h30', what: 'Escondidinho de frango (opção veg: grão-de-bico)'),
    ],
  ),
];

class Parada {
  const Parada({required this.horario, required this.local});
  final String horario;
  final String local;
}

class Viagem {
  const Viagem({
    required this.letra,
    required this.turno,
    required this.rota,
    required this.horarioSaida,
    required this.paradas,
  });
  final String letra;
  final String turno; // 'Manhã' | 'Tarde'
  final String rota;
  final String? horarioSaida;
  final List<Parada> paradas;
}

/// Viagens dos ônibus estudantis (PROAE), lidas do PDF de itinerário mais
/// recente pelo scraper. Vazio até o asset carregar.
List<Viagem> onibusViagens = [];

/// Vigência oficial do itinerário (ex. "10/08/2026 a 30/12/2026"), extraída
/// do texto do PDF. Nula até o asset carregar.
String? itinerarioVigencia;

/// Quando o PDF do itinerário foi gerado/alterado por último (metadados do
/// próprio arquivo) — permite ao usuário notar se há uma revisão mais nova
/// (ex. troca pontual de rota) mesmo dentro do mesmo período de vigência.
String? itinerarioPublicadoEm;

class BusLine {
  const BusLine({required this.name, required this.hours, required this.status, required this.active});
  final String name;
  final String hours;
  final String status;
  final bool active;
}

const busLines = [
  BusLine(name: 'Linha 01 · Centro → Campus', hours: '6h30 · 7h10 · 11h40 · 13h10', status: 'Ativa', active: true),
  BusLine(name: 'Linha 02 · Cidade Universitária', hours: '7h00 · 12h10 · 17h40', status: 'Ativa', active: true),
  BusLine(name: 'Linha 03 · Petrolina (rodoviária)', hours: '6h50 · 12h30 · 18h10', status: 'Atraso hoje', active: false),
];

class Edital {
  const Edital({
    required this.setor,
    required this.setorColor,
    required this.prazo,
    required this.titulo,
    required this.desc,
    required this.fonte,
    this.url,
  });
  final String setor;
  final String setorColor; // blue, green, yellow
  final String prazo;
  final String titulo;
  final String desc;
  final String fonte;
  final String? url;
}

List<Edital> editais = [
  Edital(
    setor: 'PROEN',
    setorColor: 'blue',
    prazo: 'inscrições até 04/09',
    titulo: 'Monitoria 2026.2 — 40 vagas',
    desc: 'Bolsas para graduação em todas as áreas. Resultado em 18/09.',
    fonte: 'Coletado do site da PROEN · hoje, 06:00',
  ),
  Edital(
    setor: 'PROAE',
    setorColor: 'green',
    prazo: 'fluxo contínuo',
    titulo: 'Auxílio permanência estudantil',
    desc: 'Cadastro atualizado mensalmente pelo app da PROAE.',
    fonte: 'Coletado do site da PROAE · hoje, 06:00',
  ),
  Edital(
    setor: 'PROEX',
    setorColor: 'yellow',
    prazo: 'resultado 30/08',
    titulo: 'Programa de extensão — edital 12/2026',
    desc: 'Projetos comunitários com bolsa de R\$ 700.',
    fonte: 'Coletado do site da PROEX · ontem, 18:00',
  ),
];

class CalendarEvent {
  const CalendarEvent({
    required this.day,
    required this.month,
    required this.title,
    required this.desc,
    this.tag = 'outro',
    this.year,
    this.dayEnd,
    this.monthEnd,
    this.yearEnd,
  });
  final String day;
  final String month;
  final String title;
  final String desc;
  final String tag; // 'feriado' | 'recesso' | 'matricula' | 'avaliacao' | 'outro'
  final int? year;

  /// Último dia de um intervalo (ex. "15 a 22"), ou "18 a 11" quando o
  /// intervalo atravessa pro mês seguinte — nesse caso [monthEnd]/[yearEnd]
  /// também vêm preenchidos, nunca assumindo que o fim é no mesmo mês do
  /// início. Nulo quando o evento é de um único dia.
  final String? dayEnd;
  final String? monthEnd;
  final int? yearEnd;
}

List<CalendarEvent> calendarEvents = [
  CalendarEvent(day: '29', month: 'Ago', title: 'Fim do ajuste de matrícula', desc: 'SRCA · solicitações pelo SIG@ até 23h59', tag: 'matricula'),
  CalendarEvent(day: '01', month: 'Set', title: 'Início da matrícula 2026.2', desc: 'Período oficial: 01/09 a 05/09', tag: 'matricula'),
  CalendarEvent(day: '07', month: 'Set', title: 'Feriado — Independência', desc: 'Sem aulas · RU fechado'),
];

/// Eventos de calendário com `tag == 'matricula'` (matrícula, ajuste,
/// trancamento), usados pelos cards de status na Área do Discente. Vazio
/// (não "indisponível" hardcoded) sempre que não houver período de
/// matrícula publicado no calendário oficial dentro da janela do scraper.
List<CalendarEvent> eventosMatricula = calendarEvents.where((e) => e.tag == 'matricula').toList();

/// Dias com eventos no mês exibido (agosto/2026), usados para marcar o grid.
const calendarEventDays = {29};
const calendarTodayDay = 26;

class SicContact {
  const SicContact({required this.campus, required this.email, this.endereco, this.horarioPresencial});
  final String campus;
  final String email;
  final String? endereco;

  /// Horário de atendimento presencial (regime PGD/teletrabalho), coletado
  /// da página oficial. Nulo quando não há horário regular identificado
  /// pro campus (ex. período de férias de quem atende, sem substituto
  /// definido) — nunca um horário inventado ou genérico.
  final String? horarioPresencial;
}

/// Contatos do SIC (Serviço de Informação ao Cidadão) por campus, vinculados
/// à SRCA — cada campus/colegiado tem seu próprio e-mail de atendimento.
/// Lista de exemplo até o scraper rodar (`_aplicarSrcaContatos`); o valor
/// real substitui esta lista inteira, sem mesclar.
List<SicContact> sicContacts = [
  SicContact(
    campus: 'Petrolina (Sede)',
    email: 'sicpnz.srca@univasf.edu.br',
    endereco: 'Av. José de Sá Maniçoba, S/N – Centro – CEP 56304-917, Petrolina-PE',
  ),
  SicContact(
    campus: 'Ciências Agrárias',
    email: 'siccca.srca@univasf.edu.br',
    endereco: 'Rodovia BR 407, KM 12, Lote 543 – PSNC, S/N – C1, Petrolina-PE',
  ),
  SicContact(
    campus: 'Juazeiro',
    email: 'sicjzr.srca@univasf.edu.br',
    endereco: 'Av. Antônio Carlos Magalhães, Nº 510, Country Club, Juazeiro-BA',
  ),
  SicContact(
    campus: 'Senhor do Bonfim',
    email: 'sicsbf.srca@univasf.edu.br',
    endereco: 'Rua Tomaz Guimarães, 45, Derba, Senhor do Bonfim-BA',
  ),
  SicContact(
    campus: 'Paulo Afonso',
    email: 'sicpaf.srca@univasf.edu.br',
    endereco: 'Rua da Liberdade, S/N, Sal Torrado, Paulo Afonso-BA',
  ),
  SicContact(
    campus: 'Serra da Capivara',
    email: 'sicsrn.srca@univasf.edu.br',
    endereco: 'Rua João Ferreira dos Santos, S/N, Bairro Campestre, São Raimundo Nonato-PI',
  ),
  SicContact(
    campus: 'Salgueiro',
    email: 'sicsal.srca@univasf.edu.br',
    endereco: 'Av. Antônio Angelim, 570, 2º andar Shopping, Santo Antônio, Salgueiro-PE',
  ),
  SicContact(
    campus: 'SEAD',
    email: 'sic.sead@univasf.edu.br',
    endereco: 'Av. José de Sá Maniçoba, S/N, Centro, Petrolina-PE',
  ),
];

/// Um auxílio/bolsa de permanência da PROAE — valor, critério e campi em
/// texto livre, extraídos da própria página oficial (não normatizados),
/// já que a redação de cada edital varia.
class AuxilioProae {
  const AuxilioProae({
    required this.nome,
    this.valor,
    this.criterio,
    this.campi = const [],
    this.acumulaCom = const [],
    this.naoAcumulaCom = const [],
    this.duracaoDias,
    this.inscricaoOnline = false,
    required this.url,
  });
  final String nome;
  final String? valor;
  final String? criterio;
  final List<String> campi;

  /// Com quais outros auxílios/bolsas pode acumular, em texto livre tal
  /// como aparece na página oficial (ex. "Auxílio Creche, Residência
  /// Estudantil").
  final List<String> acumulaCom;
  final List<String> naoAcumulaCom;

  /// Duração aproximada do processo seletivo completo, em dias.
  final int? duracaoDias;
  final bool inscricaoOnline;
  final String url;
}

/// Auxílios/bolsas da PROAE, coletados das páginas oficiais. Vazio até o
/// scraper rodar — sem exemplo mocado (valor/critério errado seria pior
/// que não mostrar nada, já que é informação financeira).
List<AuxilioProae> auxiliosProae = [];

/// Contato de um setor interno de uma pró-reitoria (PROAE, PROEN, PROEX) ou
/// da SRCA — e-mail/telefone/WhatsApp, coletados das páginas oficiais de
/// contato de cada setor. `telefone` cobre tanto telefone fixo quanto
/// WhatsApp, como vem na fonte (às vezes é o mesmo número pros dois).
class ContatoSetor {
  const ContatoSetor({required this.setor, this.email, this.telefone, this.texto, this.horario});
  final String setor;
  final String? email;
  final String? telefone;

  /// Texto completo coletado (quando o setor tem mais de um e-mail/telefone
  /// na mesma seção da página oficial) — usado pra não perder informação
  /// quando `email`/`telefone` só conseguem capturar o primeiro valor.
  final String? texto;

  /// Horário de atendimento presencial (regime PGD) — só preenchido pros
  /// setores internos da SRCA, que vêm da tabela do PGD Teletrabalho.
  final String? horario;
}

/// Contatos por setor, agrupados por pró-reitoria/órgão. Vazios até o
/// scraper rodar.
List<ContatoSetor> contatosProae = [];
List<ContatoSetor> contatosProen = [];
List<ContatoSetor> contatosProex = [];

/// Atendimento presencial dos setores internos da SRCA (Diretoria,
/// Coordenações de Registro Acadêmico, Divisões, Recepção, Diretoria de
/// Seleção e Ingresso Discente) — mesma tabela PGD Teletrabalho que
/// alimenta `SicContact.horarioPresencial`, só que pros setores internos
/// em vez dos SICs por campus.
List<ContatoSetor> srcaAtendimentoInterno = [];
