// Dados mockados usados pelo protótipo de alta fidelidade, espelhando
// exatamente os exemplos do protótipo HTML de referência.

class Notice {
  const Notice({required this.icon, required this.iconBg, required this.title, required this.desc, required this.when});
  final String icon;
  final int iconBg; // índice de cor suave (ver AppColors soft variants)
  final String title;
  final String desc;
  final String when;
}

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

class Meal {
  const Meal({required this.time, required this.what});
  final String time;
  final String what;
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
  });
  final String setor;
  final String setorColor; // blue, green, yellow
  final String prazo;
  final String titulo;
  final String desc;
  final String fonte;
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
  const CalendarEvent({required this.day, required this.month, required this.title, required this.desc});
  final String day;
  final String month;
  final String title;
  final String desc;
}

List<CalendarEvent> calendarEvents = [
  CalendarEvent(day: '29', month: 'Ago', title: 'Fim do ajuste de matrícula', desc: 'SRCA · solicitações pelo SIG@ até 23h59'),
  CalendarEvent(day: '01', month: 'Set', title: 'Início da matrícula 2026.2', desc: 'Período oficial: 01/09 a 05/09'),
  CalendarEvent(day: '07', month: 'Set', title: 'Feriado — Independência', desc: 'Sem aulas · RU fechado'),
];

/// Dias com eventos no mês exibido (agosto/2026), usados para marcar o grid.
const calendarEventDays = {29};
const calendarTodayDay = 26;

class ClassEntry {
  const ClassEntry({
    required this.code,
    required this.name,
    required this.details,
    required this.room,
    this.isSaturday = false,
  });
  final String code;
  final String name;
  final String details; // código da disciplina, ex: CCMP0230
  final String room;
  final bool isSaturday;
}

const classLegend = [
  ClassEntry(code: 'C4', name: 'Eletrônica Analógica', details: 'CCMP0230', room: 'Sala 01'),
  ClassEntry(code: '6B', name: 'Sistemas Distribuídos I', details: 'CCMP0268', room: 'Sala 10'),
  ClassEntry(code: 'C8', name: 'Sistemas de Controle II', details: 'CCMP0266', room: 'Sala 19'),
  ClassEntry(code: 'C0', name: 'Aprendizado Profundo', details: 'CCMP0213', room: 'Lab. Automação e Robótica'),
  ClassEntry(code: 'C8', name: 'Teoria da Computação', details: 'CCMP0273', room: 'Sala 21'),
  ClassEntry(code: 'X1', name: 'Org. e Arquitetura de Computadores II', details: 'CCMP0031', room: 'Sala 01', isSaturday: true),
];

/// Grade semanal: dia (0=Seg..5=Sáb) -> horário -> índice em [classLegend] (ou null).
/// Usa índice (não código) porque "C8" aparece duas vezes com disciplinas diferentes.
const weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
const timeSlots = ['08–10', '10–12', '14–16', '16–18'];

// índices: 0=C4 Eletrônica, 1=6B Sist.Distribuídos, 2=C8 Sist.Controle,
// 3=C0 Aprendizado Profundo, 4=C8 Teoria Computação, 5=X1 Org.Arquitetura
const Map<String, List<int?>> weeklyGrid = {
  '08–10': [0, null, 0, 2, null, null],
  '10–12': [1, null, 1, 2, null, null],
  '14–16': [null, null, null, null, null, 5],
  '16–18': [3, 4, 3, 4, null, 5],
};

const todayColumnIndex = 2; // Quarta-feira

class SicContact {
  const SicContact({required this.campus, required this.email});
  final String campus;
  final String email;
}

/// Contatos do SIC (Serviço de Informação ao Cidadão) por campus, vinculados
/// à SRCA — cada campus/colegiado tem seu próprio e-mail de atendimento.
const sicContacts = [
  SicContact(campus: 'Ciências Agrárias', email: 'siccca.srca@univasf.edu.br'),
  SicContact(campus: 'Juazeiro', email: 'sicjzr.srca@univasf.edu.br'),
  SicContact(campus: 'Salgueiro', email: 'sicsal.srca@univasf.edu.br'),
  SicContact(campus: 'Senhor do Bonfim', email: 'sicsbf.srca@univasf.edu.br'),
  SicContact(campus: 'Serra da Capivara', email: 'sicsrn.srca@univasf.edu.br'),
  SicContact(campus: 'Paulo Afonso', email: 'sicpaf.srca@univasf.edu.br'),
  SicContact(campus: 'SEAD', email: 'sic.sead@univasf.edu.br'),
];
