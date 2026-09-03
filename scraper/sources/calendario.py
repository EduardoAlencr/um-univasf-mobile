"""Acha o calendário acadêmico vigente (PDF) e extrai eventos próximos.

Fonte oficial: https://portais.univasf.edu.br/estudante/informacoes-ao-estudante/calendario

O PDF publica, por mês, uma tabela com o mini-calendário e a lista "DIAS /
ATIVIDADES". Algumas páginas contêm DUAS tabelas de mês lado a lado (ex.:
Outubro e Novembro) — por isso extraímos cada tabela pela sua própria
bounding box (`page.find_tables()` + `within_bbox`) e processamos o texto
recortado de cada uma isoladamente. Isso evita o bug de atribuir eventos ao
mês errado quando uma página tem mais de uma tabela.
"""
from __future__ import annotations

import io
import re
from dataclasses import dataclass, asdict
from datetime import date, timedelta

import pdfplumber
import requests
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

PALAVRAS_TAG = [
    ("feriado", "feriado"),
    ("recesso", "recesso"),
    ("ponto facultativo", "recesso"),
    ("matrícula", "matricula"),
    ("matricula", "matricula"),
    ("trancamento", "matricula"),
    ("exame", "avaliacao"),
]

DIA_RE = re.compile(r"^(\d{1,2})(?:/(\d{1,2}))?(?:\s*(?:a|e|,)\s*(\d{1,2})(?:/(\d{1,2}))?)?")

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

    def as_date(self) -> date | None:
        try:
            return date(self.ano, MESES[self.mes.lower()[:3]], int(self.dia))
        except (ValueError, KeyError):
            return None


def _achar_pdf_calendario() -> str | None:
    try:
        resp = requests.get(PAGINA_CALENDARIO, headers=HEADERS, timeout=TIMEOUT)
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


def _extrair_eventos_tabela(texto_tabela: str, nome_mes_pt: str, ano_mes: int) -> list[EventoCalendario]:
    eventos: list[EventoCalendario] = []
    if nome_mes_pt.lower()[:3] not in MESES:
        return eventos

    # A seção de eventos vem depois do cabeçalho "DIAS ATIVIDADES".
    partes = re.split(r"\bDIAS\s+ATIVIDADES\b", texto_tabela, maxsplit=1)
    corpo = partes[1] if len(partes) > 1 else texto_tabela

    for linha in corpo.splitlines():
        linha = linha.strip()
        m = DIA_RE.match(linha)
        if not m or len(linha) < 8:
            continue
        dia_num = m.group(1)
        resto = linha[m.end():].strip(" -–")
        if len(resto) < 6:
            continue
        if resto.upper() == resto and len(resto.split()) <= 2:
            continue
        if re.fullmatch(r"[\d\s]+", resto):
            continue
        if not re.search(r"[A-Za-zÀ-ÿ]{3,}", resto):
            continue
        eventos.append(
            EventoCalendario(
                dia=dia_num.zfill(2),
                mes=nome_mes_pt.capitalize()[:3],
                ano=ano_mes,
                titulo=resto[:140],
                tag=_classificar_tag(resto),
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
        eventos += _extrair_eventos_tabela(texto, nome_mes, ano)

    return eventos


def raspar_calendario(janela_dias: int = 60) -> list[dict]:
    pdf_url = _achar_pdf_calendario()
    if not pdf_url:
        return []

    try:
        resp = requests.get(pdf_url, headers=HEADERS, timeout=TIMEOUT)
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
    limite = hoje + timedelta(days=janela_dias)
    eventos_na_janela = []
    vistos = set()
    for e in eventos:
        d = e.as_date()
        if d is None or not (hoje <= d <= limite):
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
