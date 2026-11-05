"""Raspa os contatos do SIC por campus e o horário de atendimento presencial
sob o regime de teletrabalho (PGD), ambos públicos (sem login) no site da
SRCA.

1. Contatos (`requerimentos-1`): cada campus tem um bloco com "Endereço" e
   "E-mail" dentro de um `<ul>` — o wrapper em volta desse `<ul>` varia por
   campus (confirmado: a maioria usa `div.visualClear`, mas Ciências
   Agrárias usa `div.cover-richtext-tile`), então a busca é por qualquer
   `<ul>` que contenha os dois rótulos, não por uma classe fixa. O nome do
   campus é o texto não vazio mais próximo, pra trás, em ordem de
   documento (não necessariamente irmão direto).

2. Horário presencial (`pgd-teletrabalho`): a mesma página tem DUAS
   tabelas — uma por SIC de campus (cabeçalho "SIC <CAMPUS>") e outra pelos
   setores internos da própria SRCA (cabeçalho "SETOR": Diretoria,
   Coordenações de Registro Acadêmico, Divisões, Recepção, Diretoria de
   Seleção e Ingresso Discente). Em ambas, extraímos só o texto do
   horário — nunca nomes de servidor — e **descartamos qualquer linha cujo
   horário mencione uma data (ex. "Férias: 31/12/2025 a 21/01/2026")**,
   porque isso é uma exceção temporária, não o horário regular, e ficaria
   enganoso depois que a data passar. Se todas as linhas de um campus/setor
   forem descartadas por esse motivo (ex. Paulo Afonso no momento em que
   isso foi escrito), ele simplesmente não aparece no resultado — não
   inventamos um horário genérico pra substituir.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, asdict

import requests

import robots
from bs4 import BeautifulSoup, Tag

BASE_URL = "https://portais.univasf.edu.br"
URL_CONTATOS = f"{BASE_URL}/srca/servicos-menu/requerimentos-1"
URL_PGD_TELETRABALHO = f"{BASE_URL}/srca/secretaria-de-registro-e-controle-academico/pgd-teletrabalho"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 30
_REGEX_DATA = re.compile(r"\d{1,2}/\d{1,2}/\d{4}")

# Mapeia o rótulo da coluna da tabela (ex. "SIC CCA") pro mesmo nome de
# campus usado em `ContatoCampus.campus` (ex. "Campus Ciências Agrárias"),
# por correspondência de substring (case-insensitive) — não precisa ser
# exato porque quem usa isso (run.py) já faz a mesma busca por substring.
_ALIAS_CAMPUS_TABELA = {
    "SIC PETROLINA": "Petrolina",
    "SIC CCA": "Ciências Agrárias",
    "SIC JUAZEIRO": "Juazeiro",
    "SIC SENHOR DO BONFIM": "Senhor do Bonfim",
    "SIC PAULO AFONSO": "Paulo Afonso",
    "SIC SERRA DA CAPIVARA": "Serra da Capivara",
    "SIC SALGUEIRO": "Salgueiro",
}


@dataclass
class ContatoCampus:
    campus: str
    email: str
    endereco: str


def _texto_li(ul: Tag, rotulo: str) -> str | None:
    for li in ul.find_all("li"):
        texto = li.get_text(" ", strip=True)
        if texto.lower().startswith(rotulo.lower()):
            # remove o rótulo e os separadores (":" ou similares) do início
            resto = texto[len(rotulo):].lstrip(" :")
            return resto or None
    return None


def _achar_nome_campus(ul: Tag) -> str | None:
    """Texto não vazio mais próximo, pra trás em ordem de documento, que
    não seja o próprio endereço/e-mail — é aí que o CMS coloca o nome do
    campus (ex. "Campus Juazeiro", "SEAD"), independente de qual elemento
    pai/wrapper está sendo usado naquele bloco específico."""
    for el in ul.find_all_previous():
        if not isinstance(el, Tag) or el.name in ("script", "style"):
            continue
        texto = el.get_text(" ", strip=True)
        if not texto or len(texto) > 60:
            continue
        if "endere" in texto.lower() or "@" in texto or texto.lower() in ("email", "e-mail"):
            continue
        return texto
    return None


def raspar_contatos_srca() -> list[dict]:
    """Retorna a lista de contatos do SIC por campus, ou lista vazia em
    caso de erro (nunca lança exceção)."""
    try:
        resp = robots.get(URL_CONTATOS, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[srca_contatos] falha ao buscar contatos: {exc}")
        return []

    soup = BeautifulSoup(resp.text, "lxml")
    contatos: list[ContatoCampus] = []
    for ul in soup.find_all("ul"):
        texto_bloco = ul.get_text(" ", strip=True)
        if "endere" not in texto_bloco.lower() or "@" not in texto_bloco:
            continue
        endereco = _texto_li(ul, "Endereço")
        email_li = next((li for li in ul.find_all("li") if "@" in li.get_text()), None)
        link_email = email_li.find("a", href=True) if email_li else None
        email = link_email.get_text(strip=True) if link_email else None
        if not endereco or not email:
            continue
        nome = _achar_nome_campus(ul) or "Campus não identificado"
        contatos.append(ContatoCampus(campus=nome, email=email, endereco=endereco))

    return [asdict(c) for c in contatos]


def _extrair_secoes_tabela(tabela: Tag) -> dict[str, list[tuple[str, str, str]]]:
    """Varre uma tabela no formato `<RÓTULO> | PRESENCIAL | E-MAIL |
    CONTATO WHATSAPP` (linha de cabeçalho de seção = 1ª célula preenchida,
    demais vazias) e retorna `{rotulo: [(horario, email, whatsapp), ...]}`,
    já descartando linhas de horário com data (ver docstring do módulo)."""
    linhas = tabela.find_all("tr")
    secoes: dict[str, list[tuple[str, str, str]]] = {}
    secao_atual: str | None = None
    for i, linha in enumerate(linhas):
        celulas = [c.get_text(" ", strip=True) for c in linha.find_all(["td", "th"])]
        if len(celulas) < 4:
            continue
        primeira, presencial, email, whatsapp = celulas[:4]
        if i == 0:
            # linha 0 é o cabeçalho da tabela inteira; a 1ª célula já é o
            # rótulo da primeira seção, as demais são nomes de coluna.
            secao_atual = primeira
            continue
        if not presencial and not email and not whatsapp and primeira:
            secao_atual = primeira  # nova seção
            continue
        if secao_atual and presencial and not _REGEX_DATA.search(presencial):
            secoes.setdefault(secao_atual, []).append((presencial, email, whatsapp))
    return secoes


def raspar_horario_presencial_sic() -> dict[str, str]:
    """Retorna `{nome_campus_curto: horario_presencial}` (ex. `{"Petrolina":
    "08h às 14h - Segunda e Sexta ..."}`), só pros campi com pelo menos uma
    linha de horário sem data (vencimento de período temporário). Dict
    vazio em caso de erro, nunca lança exceção."""
    try:
        resp = robots.get(URL_PGD_TELETRABALHO, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[srca_contatos] falha ao buscar horário presencial: {exc}")
        return {}

    soup = BeautifulSoup(resp.text, "lxml")
    resultado: dict[str, str] = {}
    for tabela in soup.find_all("table"):
        primeira_celula = tabela.find_all("tr")[0].find_all(["td", "th"]) if tabela.find_all("tr") else []
        if not primeira_celula or not primeira_celula[0].get_text(strip=True).upper().startswith("SIC"):
            continue  # não é a tabela dos SICs (é a dos setores internos da SRCA)
        for rotulo, linhas in _extrair_secoes_tabela(tabela).items():
            horario = " · ".join(h for h, _, _ in linhas)
            resultado[_ALIAS_CAMPUS_TABELA.get(rotulo.upper(), rotulo)] = horario

    return resultado


def raspar_atendimento_presencial_srca() -> list[dict]:
    """Retorna o atendimento presencial dos setores internos da SRCA
    (Diretoria, Coordenações de Registro Acadêmico, Divisões, Recepção,
    Diretoria de Seleção e Ingresso Discente) — a 2ª tabela da mesma
    página, com cabeçalho "SETOR" em vez de "SIC <campus>". Lista vazia em
    caso de erro, nunca lança exceção."""
    try:
        resp = robots.get(URL_PGD_TELETRABALHO, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[srca_contatos] falha ao buscar atendimento presencial da SRCA: {exc}")
        return []

    soup = BeautifulSoup(resp.text, "lxml")
    resultado = []
    for tabela in soup.find_all("table"):
        primeira_celula = tabela.find_all("tr")[0].find_all(["td", "th"]) if tabela.find_all("tr") else []
        if not primeira_celula or primeira_celula[0].get_text(strip=True).upper().startswith("SIC"):
            continue  # é a tabela dos SICs de campus, não a dos setores internos
        for setor, linhas in _extrair_secoes_tabela(tabela).items():
            horario = " · ".join(h for h, _, _ in linhas if h)
            email = next((e for _, e, _ in linhas if e), None)
            whatsapp = next((w for _, _, w in linhas if w), None)
            if not horario and not email and not whatsapp:
                continue
            resultado.append({"setor": setor, "horario": horario or None, "email": email, "whatsapp": whatsapp})

    return resultado


if __name__ == "__main__":
    import json

    print(json.dumps(
        {"contatos": raspar_contatos_srca(), "horario_presencial": raspar_horario_presencial_sic()},
        ensure_ascii=False, indent=2,
    ))
