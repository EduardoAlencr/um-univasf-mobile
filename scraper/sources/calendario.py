"""Acha o calendário acadêmico vigente (PDF) e extrai eventos próximos.

Fonte oficial: https://portais.univasf.edu.br/estudante/informacoes-ao-estudante/calendario

O PDF publica, por mês, uma tabela com o mini-calendário e a lista "DIAS /
ATIVIDADES". Algumas páginas contêm DUAS tabelas de mês lado a lado (ex.:
Outubro e Novembro) — por isso extraímos cada tabela pela sua própria
bounding box (`page.find_tables()` + `within_bbox`) pra identificar o
mês/ano, mas o corpo "DIAS ATIVIDADES" é lido **célula por célula**
(`tabela.extract()`), não como texto corrido. Isso é importante: extrair
a tabela inteira como texto linearizado (`extract_text()`) intercala
atividades vizinhas quando o texto de uma quebra em várias linhas, cortando
ou embaralhando datas — ler célula por célula respeita a borda real da
tabela, então cada linha fica como um par `(dia(s), atividade)` de verdade,
sem depender de heurística pra adivinhar onde uma atividade termina e a
próxima começa. Um detalhe do PDF: célula por célula junta palavras sem
espaço se usar as tolerâncias padrão do pdfplumber — por isso sempre
chamamos `extract(x_tolerance=1.5, y_tolerance=1.5)`.
"""
from __future__ import annotations

import io
import re
from dataclasses import dataclass, asdict
from datetime import date, timedelta

import pdfplumber
import requests

import robots
from bs4 import BeautifulSoup

BASE_URL = "https://portais.univasf.edu.br"
PAGINA_CALENDARIO = f"{BASE_URL}/estudante/informacoes-ao-estudante/calendario"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 30

MESES = {
    "jan": 1, "fev": 2, "mar": 3, "abr": 4, "mai": 5, "jun": 6,
    "jul": 7, "ago": 8, "set": 9, "out": 10, "nov": 11, "dez": 12,
}
MESES_ORDEM = [
    "JANEIRO", "FEVEREIRO", "MARÇO", "ABRIL", "MAIO", "JUNHO",
    "JULHO", "AGOSTO", "SETEMBRO", "OUTUBRO", "NOVEMBRO", "DEZEMBRO",
]
_NUM_PARA_MES_ABREV = {i + 1: nome.capitalize()[:3] for i, nome in enumerate(MESES_ORDEM)}

PALAVRAS_TAG = [
    ("feriado", "feriado"),
    ("recesso", "recesso"),
    ("ponto facultativo", "recesso"),
    ("matrícula", "matricula"),
    ("matricula", "matricula"),
    ("trancamento", "matricula"),
    ("exame", "avaliacao"),
]

DIA_RE = re.compile(r"^(\d{1,2})(?:/(\d{1,2}))?(?:\s*(?:a|à|e|,)\s*(\d{1,2})(?:/(\d{1,2}))?)?")

# Palavra em maiúsculas isolada (não colada a minúscula antes/depois) — usada
# para reconstruir o nome do mês quando o layout do PDF quebra o texto do
# título de forma estranha (ex.: "N 2026\nOVEMBRO" em vez de "NOVEMBRO 2026").
_PALAVRA_MAIUSCULA_RE = re.compile(r"(?<![a-zà-ÿ])[A-ZÀ-Ü]+(?![a-zà-ÿ])")
_IGNORAR_NO_CABECALHO = {"CALENDÁRIO", "ACADÊMICO", "DIAS", "ATIVIDADES"}


@dataclass
class EventoCalendario:
    dia: str
    mes: str
    ano: int
    titulo: str
    tag: str
    dia_fim: str | None = None
    # Só preenchidos quando o intervalo atravessa pro mês seguinte (ex. "18/11
    # a 11/12") — sem isso, um evento assim mostraria "18 a 11 de Novembro",
    # com o fim antes do início. Quando `dia_fim` existe mas `mes_fim` não, o
    # fim é no mesmo mês/ano do início.
    mes_fim: str | None = None
    ano_fim: int | None = None

    def as_date(self) -> date | None:
        try:
            return date(self.ano, MESES[self.mes.lower()[:3]], int(self.dia))
        except (ValueError, KeyError):
            return None


def _mes_ano_a_partir_de(mes_num: int | None, mes_base_abrev: str, ano_base: int) -> tuple[str, int]:
    """Resolve mês/ano de um dia a partir do número de mês explícito no PDF
    (ex. o "/12" em "18/11 a 11/12"), relativo a um mês/ano base — nunca
    assume que um dia com mês explícito diferente pertence ao mesmo mês da
    tabela. Só lida com a virada pro mês/ano adjacente (ex. Dez -> Jan do
    ano seguinte), que é o único caso real num calendário acadêmico — um
    intervalo não pula vários meses de uma vez."""
    if mes_num is None or not (1 <= mes_num <= 12):
        return mes_base_abrev, ano_base
    mes_base_num = MESES[mes_base_abrev.lower()[:3]]
    if mes_num == mes_base_num:
        return mes_base_abrev, ano_base
    if mes_base_num == 12 and mes_num == 1:
        return _NUM_PARA_MES_ABREV[mes_num], ano_base + 1
    if mes_base_num == 1 and mes_num == 12:
        return _NUM_PARA_MES_ABREV[mes_num], ano_base - 1
    return _NUM_PARA_MES_ABREV[mes_num], ano_base


def _achar_pdf_calendario() -> str | None:
    try:
        resp = robots.get(PAGINA_CALENDARIO, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[calendario] falha ao abrir página do calendário: {exc}")
        return None

    soup = BeautifulSoup(resp.text, "lxml")
    link = soup.find("a", href=re.compile(r"\.pdf($|\?)", re.IGNORECASE))
    if not link:
        return None
    href = link["href"]
    if href.startswith("/"):
        href = BASE_URL + href
    return href


def _classificar_tag(texto_atividade: str) -> str:
    texto = texto_atividade.lower()
    for palavra, tag in PALAVRAS_TAG:
        if palavra in texto:
            return tag
    return "outro"


def _identificar_mes_ano(texto_tabela: str) -> tuple[str, int] | None:
    """Reconstrói o nome do mês e o ano a partir do início do texto de uma
    tabela, mesmo quando o PDF quebra o título de forma incomum."""
    trecho = texto_tabela.split("CAMPI")[0]
    ano_match = re.search(r"20\d\d", trecho)
    if not ano_match:
        return None
    ano = int(ano_match.group(0))

    palavras = [
        p for p in _PALAVRA_MAIUSCULA_RE.findall(trecho)
        if p not in _IGNORAR_NO_CABECALHO
    ]
    concatenado = "".join(palavras)
    for nome in MESES_ORDEM:
        if nome in concatenado or concatenado in nome:
            return nome, ano
    return None


def _texto_valido(texto: str) -> bool:
    """Filtro de ruído mínimo — com a extração célula por célula, cada
    linha da tabela já vem isolada de verdade; isso só descarta linha
    vazia/lixo residual (ex. célula "DIAS"/"ATIVIDADES" do cabeçalho, caso
    entre por engano)."""
    if len(texto) < 6:
        return False
    if texto.upper() == texto and len(texto.split()) <= 2:
        return False
    if not re.search(r"[A-Za-zÀ-ÿ]{3,}", texto):
        return False
    return True


def _extrair_eventos_tabela_celulas(tabela, nome_mes_pt: str, ano_mes: int) -> list[EventoCalendario]:
    """Lê a tabela célula por célula (não como texto corrido) — cada linha
    da seção "DIAS ATIVIDADES" já vem como um par `(dia(s), atividade)`
    isolado pela própria borda da tabela, o que evita o corte/mistura de
    datas que a extração por texto linearizado (`extract_text`) causava
    quando uma atividade quebrava em várias linhas."""
    eventos: list[EventoCalendario] = []
    if nome_mes_pt.lower()[:3] not in MESES:
        return eventos

    try:
        linhas = tabela.extract(x_tolerance=1.5, y_tolerance=1.5)
    except Exception as exc:
        print(f"[calendario] falha ao extrair células da tabela de {nome_mes_pt}: {exc}")
        return eventos

    # A seção de eventos começa na linha de cabeçalho "DIAS" | "ATIVIDADES".
    inicio = next((i for i, linha in enumerate(linhas) if linha and (linha[0] or "").strip().upper() == "DIAS"), None)
    if inicio is None:
        return eventos

    for linha in linhas[inicio + 1:]:
        if not linha or linha[0] is None:
            continue
        dia_cel = linha[0].replace("\n", " ").strip()
        atividade_cel = (linha[1] or "").replace("\n", " ").strip() if len(linha) > 1 else ""
        atividade_cel = re.sub(r"\s+", " ", atividade_cel)

        m = DIA_RE.match(dia_cel)
        if not m or not m.group(1):
            continue
        if not _texto_valido(atividade_cel):
            continue

        mes_tabela_abrev = nome_mes_pt.capitalize()[:3]
        mes_ini_num = int(m.group(2)) if m.group(2) else None
        mes_ini_abrev, ano_ini = _mes_ano_a_partir_de(mes_ini_num, mes_tabela_abrev, ano_mes)

        dia_fim = m.group(3)
        mes_fim_abrev: str | None = None
        ano_fim: int | None = None
        if dia_fim:
            mes_fim_num = int(m.group(4)) if m.group(4) else None
            mes_fim_abrev, ano_fim = _mes_ano_a_partir_de(mes_fim_num, mes_ini_abrev, ano_ini)
            # Só guarda mes_fim/ano_fim quando realmente diferem do início —
            # mantém o JSON enxuto pro caso comum (intervalo dentro do mesmo mês).
            if mes_fim_abrev == mes_ini_abrev and ano_fim == ano_ini:
                mes_fim_abrev, ano_fim = None, None

        eventos.append(
            EventoCalendario(
                dia=m.group(1).zfill(2),
                mes=mes_ini_abrev,
                ano=ano_ini,
                titulo=atividade_cel[:300],
                tag=_classificar_tag(atividade_cel),
                dia_fim=dia_fim.zfill(2) if dia_fim else None,
                mes_fim=mes_fim_abrev,
                ano_fim=ano_fim,
            )
        )
    return eventos


def _extrair_eventos_pagina(pagina) -> list[EventoCalendario]:
    eventos: list[EventoCalendario] = []
    try:
        tabelas = pagina.find_tables()
    except Exception as exc:
        print(f"[calendario] falha ao localizar tabelas: {exc}")
        return eventos

    for tabela in tabelas:
        try:
            recorte = pagina.within_bbox(tabela.bbox)
            texto = recorte.extract_text(x_tolerance=1.5) or ""
        except Exception:
            continue

        mes_ano = _identificar_mes_ano(texto)
        if not mes_ano:
            continue
        nome_mes, ano = mes_ano
        eventos += _extrair_eventos_tabela_celulas(tabela, nome_mes, ano)

    return eventos


def raspar_calendario(dias_passado: int = 400, dias_futuro: int = 400) -> list[dict]:
    pdf_url = _achar_pdf_calendario()
    if not pdf_url:
        return []

    try:
        resp = robots.get(pdf_url, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[calendario] falha ao baixar PDF: {exc}")
        return []

    eventos: list[EventoCalendario] = []
    try:
        with pdfplumber.open(io.BytesIO(resp.content)) as pdf:
            for pagina in pdf.pages:
                eventos += _extrair_eventos_pagina(pagina)
    except Exception as exc:
        print(f"[calendario] falha ao parsear PDF: {exc}")
        return []

    hoje = date.today()
    # Janela larga (padrão ~13 meses pra cada lado) só pra descartar lixo de
    # OCR/parse com data absurda — o calendário acadêmico (passado e futuro
    # dentro do ano corrente) fica todo disponível, não só os próximos dias.
    limite_passado = hoje - timedelta(days=dias_passado)
    limite_futuro = hoje + timedelta(days=dias_futuro)
    eventos_na_janela = []
    vistos = set()
    for e in eventos:
        d = e.as_date()
        if d is None or not (limite_passado <= d <= limite_futuro):
            continue
        chave = (e.dia, e.mes, e.ano, e.titulo)
        if chave in vistos:
            continue
        vistos.add(chave)
        eventos_na_janela.append(e)

    eventos_na_janela.sort(key=lambda e: e.as_date() or date.max)
    return [asdict(e) for e in eventos_na_janela]


if __name__ == "__main__":
    import json

    print(json.dumps(raspar_calendario(), ensure_ascii=False, indent=2))
