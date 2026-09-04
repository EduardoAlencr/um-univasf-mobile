"""Raspa os avisos públicos da tela inicial do SIG@ (antes do login).

A página ``https://siga.univasf.edu.br/.../inicio.jsf`` é o portal de acesso
(login) do SIG@ e não exige autenticação para ser lida — ela já expõe, em
texto, avisos institucionais úteis (prazos de matrícula, bloqueio de senha,
etc.) em dois blocos HTML diferentes:

- ``span.aviso`` (com ``span.titulo`` + ``span.descricaoAviso``)
- ``span.li`` (com ``span.h3`` + ``span.p``), usado para avisos tipo notícia

Nunca lê nada que exija login: só o conteúdo público, sem CPF/senha/dado
pessoal algum.
"""
from __future__ import annotations

import requests
from bs4 import BeautifulSoup

URL = "https://siga.univasf.edu.br/univasf/jsp/acesso/pages/inicio.jsf"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 20
LIMITE = 10


def _texto(el) -> str:
    return el.get_text(" ", strip=True) if el else ""


def raspar_avisos_siga(limite: int = LIMITE) -> list[str]:
    """Busca os avisos públicos da tela inicial do SIG@. Retorna lista vazia
    em caso de erro (nunca lança exceção)."""
    try:
        resp = requests.get(URL, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[siga_avisos] falha ao buscar {URL}: {exc}")
        return []

    soup = BeautifulSoup(resp.text, "lxml")
    avisos: list[str] = []
    vistos: set[str] = set()

    for bloco in soup.select("span.aviso"):
        titulo = _texto(bloco.select_one("span.titulo"))
        descricao = _texto(bloco.select_one("span.descricaoAviso"))
        texto = f"{titulo} — {descricao}" if titulo and descricao else (titulo or descricao)
        if texto and texto not in vistos:
            vistos.add(texto)
            avisos.append(texto)

    for item in soup.select("span.li"):
        titulo = _texto(item.select_one("span.h3"))
        descricao = _texto(item.select_one("span.p"))
        texto = f"{titulo} — {descricao}" if titulo and descricao else (titulo or descricao)
        if texto and texto not in vistos:
            vistos.add(texto)
            avisos.append(texto)

    return avisos[:limite]


if __name__ == "__main__":
    import json

    print(json.dumps(raspar_avisos_siga(), ensure_ascii=False, indent=2))
