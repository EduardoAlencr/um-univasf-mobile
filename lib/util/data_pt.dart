/// Nomes de dias/meses em pt-BR, usados para formatar datas sem depender do
/// pacote `intl` (não é uma dependência do projeto).
const diasSemanaPt = [
  'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado',
]; // índice: DateTime.weekday % 7 (Dom=0)

const mesesAbrevPt = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

const mesesNomesPt = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// Ex.: "Quarta-feira, 3 de setembro de 2026".
String formatarDataCompleta(DateTime data) {
  final diaSemana = diasSemanaPt[data.weekday % 7];
  final mes = mesesNomesPt[data.month - 1];
  return '$diaSemana, ${data.day} de $mes de ${data.year}';
}

/// Converte um evento do calendário (dia numérico + mês abreviado, sem ano)
/// na próxima ocorrência dessa data a partir de [hoje] — assume o ano atual,
/// ou o ano seguinte se a data já passou este ano (o scraper já limita a
/// uma janela de ~60 dias, então isso raramente ambiguidade).
DateTime? proximaOcorrencia(String? diaStr, String? mesAbrev, DateTime hoje) {
  final dia = int.tryParse(diaStr ?? '');
  final mesIndex = mesesAbrevPt.indexWhere((m) => m.toLowerCase() == (mesAbrev ?? '').toLowerCase());
  if (dia == null || mesIndex == -1) return null;
  final mes = mesIndex + 1;

  var candidato = DateTime(hoje.year, mes, dia);
  final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
  if (candidato.isBefore(hojeSemHora)) {
    candidato = DateTime(hoje.year + 1, mes, dia);
  }
  return candidato;
}

/// Ex.: "hoje", "amanhã", "em 3 dias".
String descreverPrazo(DateTime data, DateTime hoje) {
  final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
  final alvo = DateTime(data.year, data.month, data.day);
  final dias = alvo.difference(hojeSemHora).inDays;
  if (dias <= 0) return 'hoje';
  if (dias == 1) return 'amanhã';
  return 'em $dias dias';
}
