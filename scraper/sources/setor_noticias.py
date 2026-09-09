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


_SELETOR_LINK_TITULO = "h2.headline a.summary, h2.tileHeadline a, article a.summary, span.summary a.url"


def _extrair_data_do_titulo(texto: str) -> tuple[str, str | None]:
    """Alguns setores (ex. PROAE) embutem a data no próprio texto do título
    ("DD.MM.AAAA – Título"). Retorna (título limpo, data ou None)."""
    prefixo = DATE_PREFIX_RE.match(texto)
    if prefixo:
        return texto[prefixo.end():].strip(), prefixo.group(1).replace(".", "/")
    return texto, None


def _extrair_data_da_byline(item_el) -> str | None:
    """Outros setores (ex. PROEN) não têm data no título — ela fica num
    bloco `div.documentByLine > span.documentPublished` dentro do mesmo
    item da listagem."""
    byline = item_el.find(class_="documentByLine")
    if not byline:
        return None
    publicado = byline.find(class_="documentPublished")
    texto = (publicado or byline).get_text(" ", strip=True)
    m = DATE_RE.search(texto)
    return m.group(0).replace(".", "/") if m else None


def _parse_link_solto(link, setor_label: str) -> NoticiaSetor | None:
    """Fallback pra quando a listagem não usa blocos `div.item` (ex. PROEX,
    feed geral "Últimas notícias") — a página não expõe data por item nesse
    caso, então `data` fica None (não inventamos)."""
    texto = link.get_text(strip=True)
    if not texto:
        return None
    href = link.get("href", "")
    if href.startswith("/"):
        href = BASE_URL + href
    titulo, data = _extrair_data_do_titulo(texto)
    return NoticiaSetor(setor=setor_label, titulo=titulo, data=data, resumo="", url=href)


def _parse_item_div(item_el, setor_label: str) -> NoticiaSetor | None:
    link = item_el.select_one(_SELETOR_LINK_TITULO)
    if link is None:
        return None
    texto = link.get_text(strip=True)
    if not texto:
        return None
    href = link.get("href", "")
    if href.startswith("/"):
        href = BASE_URL + href
    titulo, data = _extrair_data_do_titulo(texto)
    if data is None:
        data = _extrair_data_da_byline(item_el)
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
        # agrupa cada notícia num <div class="item">, com a data em algum
        # lugar dentro desse bloco (no título ou numa "byline" separada).
        # Alguns feeds (ex. PROEX, "Últimas notícias" geral) usam outro
        # template de busca sem esse agrupamento — nesses, cada link vira
        # uma notícia sem data (a página não expõe isso por item).
        blocos = soup.select("div.item")
        if blocos:
            itens_pagina = [_parse_item_div(b, setor_label) for b in blocos]
        else:
            links = soup.select(_SELETOR_LINK_TITULO)
            itens_pagina = [_parse_link_solto(link, setor_label) for link in links]

        novos_nesta_pagina = 0
        for item in itens_pagina:
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
