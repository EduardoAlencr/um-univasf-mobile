"""Raspa os contatos por setor interno da PROEN (Pró-Reitoria de Ensino),
públicos (sem login).

A página (`proen/proen/contato`) usa um padrão diferente do de
`setores.proae`: cada bloco é um título em negrito (ex. "Diretoria de
Planejamento de Ensino - DPE") seguido de linhas "E-mail:"/"Telefone/
WhatsApp:" (às vezes rótulo e valor na mesma linha, às vezes em linhas
separadas). Os blocos de "Coordenação Pedagógica" têm sub-blocos "Campus
<nome>" — tratamos como `"<título pai> — Campus <nome>"`.

Não tentamos extrair o bloco "Endereço" (texto livre, sem rótulo
"E-mail"/"Telefone", indistinguível de um título qualquer por regex) —
qualquer "título" que nunca ganha e-mail/telefone (como "Endereço" e as
linhas do endereço em si) simplesmente não aparece no resultado, porque só
retornamos entradas com pelo menos um contato real.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, asdict

import requests

import robots
from bs4 import BeautifulSoup

BASE_URL = "https://portais.univasf.edu.br"
URL_CONTATO = f"{BASE_URL}/proen/proen/contato"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 30

_REGEX_CAMPO_INLINE = re.compile(r"^(e-?mail|telefone/?whatsapp|whatsapp|telefone)\s*:\s*(.+)$", re.IGNORECASE)
_CAMPOS_ROTULO = {"e-mail", "email", "telefone/whatsapp", "whatsapp", "telefone"}


@dataclass
class ContatoSetor:
    setor: str
    email: str | None
    telefone: str | None


def raspar_contato_proen() -> list[dict]:
    """Retorna os contatos por setor interno da PROEN, ou lista vazia em
    caso de erro (nunca lança exceção)."""
    try:
        resp = robots.get(URL_CONTATO, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[proen] falha ao buscar contato: {exc}")
        return []

    soup = BeautifulSoup(resp.text, "lxml")
    conteudo = soup.select_one("div#content-core") or soup.select_one("div#content")
    if conteudo is None:
        return []
    linhas = [l.strip() for l in conteudo.get_text("\n", strip=True).split("\n") if l.strip()]

    registros: dict[str, dict[str, str | None]] = {}
    titulo_pai: str | None = None
    atual: str | None = None
    i = 0
    while i < len(linhas):
        linha = linhas[i]

        m = _REGEX_CAMPO_INLINE.match(linha)
        if m and atual:
            campo = "email" if "mail" in m.group(1).lower() else "telefone"
            registros.setdefault(atual, {})[campo] = m.group(2).strip()
            i += 1
            continue

        rotulo_sozinho = linha.rstrip(":").strip().lower()
        if rotulo_sozinho in _CAMPOS_ROTULO and atual and i + 1 < len(linhas):
            campo = "email" if "mail" in rotulo_sozinho else "telefone"
            registros.setdefault(atual, {})[campo] = linhas[i + 1].strip()
            i += 2
            continue

        if linha == "Campus" and i + 1 < len(linhas):
            nome_campus = linhas[i + 1].strip()
            atual = f"{titulo_pai} — Campus {nome_campus}" if titulo_pai else f"Campus {nome_campus}"
            registros.setdefault(atual, {})
            i += 2
            continue

        # qualquer outra linha é um novo título (sector, ou ruído de
        # endereço/cabeçalho genérico que será descartado no final por não
        # ganhar e-mail/telefone).
        titulo_pai = linha
        atual = linha
        registros.setdefault(atual, {})
        i += 1

    resultado = [
        ContatoSetor(setor=setor, email=dados.get("email"), telefone=dados.get("telefone"))
        for setor, dados in registros.items()
        if dados.get("email") or dados.get("telefone")
    ]
    return [asdict(c) for c in resultado]


if __name__ == "__main__":
    import json

    print(json.dumps(raspar_contato_proen(), ensure_ascii=False, indent=2))
