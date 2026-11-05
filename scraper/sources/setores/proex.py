"""Raspa os e-mails gerais por setor interno da PROEX (Pró-Reitoria de
Extensão), públicos (sem login).

A PROEX não tem uma página `/contato` própria (dá 404) — só a página
`equipe`, que mistura texto institucional estável (nome do setor,
endereço, e-mail genérico do setor) com conteúdo pessoa a pessoa (nomes de
servidores, horário individual, e-mail/WhatsApp pessoal), separados por
divisórias decorativas (`━───...`).

Extraímos só o e-mail genérico de cada setor — o **primeiro** "E-mail:"
que aparece depois do título do setor (Secretaria Administrativa, DEX,
DACC, Espaço Plural), antes de qualquer nome de pessoa. Depois do primeiro
e-mail capturado pra um setor, ignoramos qualquer outro "E-mail:" até o
próximo título de setor reconhecido — é assim que pulamos os e-mails
pessoais dos servidores sem precisar identificar "isto é um nome de
pessoa" (bem mais frágil que reconhecer os 4 nomes de setor, que são
estáveis).
"""
from __future__ import annotations

import re
from dataclasses import dataclass, asdict

import requests

import robots
from bs4 import BeautifulSoup

BASE_URL = "https://portais.univasf.edu.br"
URL_EQUIPE = f"{BASE_URL}/proex/proex/equipe"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 30

_REGEX_TITULO_SETOR = re.compile(r"^(Pró-Reitoria|Secretaria Administrativa|Departamento|Espaço Plural)")


@dataclass
class ContatoSetor:
    setor: str
    email: str | None
    telefone: str | None = None


def raspar_contato_proex() -> list[dict]:
    """Retorna os e-mails gerais por setor da PROEX, ou lista vazia em
    caso de erro (nunca lança exceção)."""
    try:
        resp = robots.get(URL_EQUIPE, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[proex] falha ao buscar equipe: {exc}")
        return []

    soup = BeautifulSoup(resp.text, "lxml")
    conteudo = soup.select_one("div#content-core") or soup.select_one("div#content")
    if conteudo is None:
        return []
    linhas = [l.strip() for l in conteudo.get_text("\n", strip=True).split("\n") if l.strip()]

    registros: dict[str, str | None] = {}
    setor_atual: str | None = None
    for i, linha in enumerate(linhas):
        if _REGEX_TITULO_SETOR.match(linha):
            setor_atual = linha
            registros.setdefault(setor_atual, None)
            continue
        if (
            setor_atual
            and registros.get(setor_atual) is None
            and linha.rstrip(":").strip().lower() in ("e-mail", "email")
            and i + 1 < len(linhas)
        ):
            registros[setor_atual] = linhas[i + 1].strip()

    resultado = [ContatoSetor(setor=setor, email=email) for setor, email in registros.items() if email]
    return [asdict(c) for c in resultado]


if __name__ == "__main__":
    import json

    print(json.dumps(raspar_contato_proex(), ensure_ascii=False, indent=2))
