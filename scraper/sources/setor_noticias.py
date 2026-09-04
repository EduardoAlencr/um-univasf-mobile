"""Raspa a listagem de notícias de um setor da UNIVASF (portal Plone).

Cada setor (PROAE, PROEX, PROEN, ...) publica suas próprias notícias em
``https://portais.univasf.edu.br/<setor>/noticias/ultimas-noticias``. A página
lista itens com título, data e um resumo curto; extraímos esses três campos.

O mesmo padrão de URL vale para o feed geral da universidade
(``https://portais.univasf.edu.br/univasf/noticias/ultimas-noticias``), então
ele é raspado com a mesma função, só trocando o slug do "setor".

A listagem pagina via ``?b_start:int=25,50,75,...`` (padrão Plone). Para
limites maiores que uma página, percorremos páginas subsequentes até atingir
o limite pedido ou não haver mais notícias novas.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, asdict

import requests
from bs4 import BeautifulSoup

BASE_URL = "https://portais.univasf.edu.br"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 20
ITENS_POR_PAGINA = 25
MAX_PAGINAS = 6  # trava de segurança, nunca varre mais que isso

DATE_RE = re.compile(r"\d{2}[./]\d{2}[./]\d{4}")
DATE_PREFIX_RE = re.compile(r"^\s*(\d{2}[./]\d{2}[./]\d{4})\s*[–\-]\s*")


@dataclass
class NoticiaSetor:
    setor: str
    titulo: str
    data: str | None
    resumo: str
    url: str


def _parse_item(link, setor_label: str) -> NoticiaSetor | None:
    texto = link.get_text(strip=True)
    if not texto:
        return None
    href = link.get("href", "")
    if href.startswith("/"):
        href = BASE_URL + href

    prefixo = DATE_PREFIX_RE.match(texto)
    if prefixo:
        data = prefixo.group(1).replace(".", "/")
        titulo = texto[prefixo.end():].strip()
    else:
        data_match = DATE_RE.search(texto)
        data = data_match.group(0).replace(".", "/") if data_match else None
        titulo = texto

    return NoticiaSetor(setor=setor_label, titulo=titulo, data=data, resumo="", url=href)


def raspar_noticias_setor(setor_slug: str, setor_label: str, limite: int = 6) -> list[NoticiaSetor]:
    """Busca as últimas notícias de um setor, paginando conforme necessário até
    atingir `limite`. Retorna lista vazia em caso de erro (nunca lança exceção
    para não derrubar o restante do scraper)."""
    url_base = f"{BASE_URL}/{setor_slug}/noticias/ultimas-noticias"
    noticias: list[NoticiaSetor] = []
    vistos: set[str] = set()

    for pagina in range(MAX_PAGINAS):
        b_start = pagina * ITENS_POR_PAGINA
        url = url_base if b_start == 0 else f"{url_base}?b_start:int={b_start}"
        try:
            resp = requests.get(url, headers=HEADERS, timeout=TIMEOUT)
            resp.raise_for_status()
        except requests.RequestException as exc:
            print(f"[setor_noticias] falha ao buscar {url}: {exc}")
            break

        soup = BeautifulSoup(resp.text, "lxml")
        # O template de notícias da UNIVASF (Plone) varia por setor: a maioria
        # usa <h2 class="headline"><a class="summary url">DD.MM.AAAA – Título</a></h2>,
        # mas alguns (ex. PROEX) usam <span class="summary"><a class="...url">Título</a></span>.
        links = soup.select(
            "h2.headline a.summary, h2.tileHeadline a, article a.summary, span.summary a.url"
        )

        novos_nesta_pagina = 0
        for link in links:
            item = _parse_item(link, setor_label)
            if item is None or item.url in vistos:
                continue
            vistos.add(item.url)
            novos_nesta_pagina += 1
            noticias.append(item)
            if len(noticias) >= limite:
                return noticias

        if novos_nesta_pagina == 0:
            break  # página sem itens novos: acabou a listagem

    return noticias


def raspar_todos_setores() -> list[dict]:
    setores = [
        ("proae", "PROAE"),
        ("proex", "PROEX"),
        ("proen", "PROEN"),
        ("univasf", "Últimas notícias"),
    ]
    resultado: list[dict] = []
    for slug, label in setores:
        limite = 40 if slug == "univasf" else 20
        for noticia in raspar_noticias_setor(slug, label, limite=limite):
            resultado.append(asdict(noticia))
    return resultado


if __name__ == "__main__":
    import json

    print(json.dumps(raspar_todos_setores(), ensure_ascii=False, indent=2))
