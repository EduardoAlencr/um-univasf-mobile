"""Raspa a listagem de notícias de um setor da UNIVASF (portal Plone).

Cada setor (PROAE, PROEX, PROEN, ...) publica suas próprias notícias em
``https://portais.univasf.edu.br/<setor>/noticias/ultimas-noticias``. A página
lista itens com título, data e um resumo curto; extraímos esses três campos.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, asdict

import requests
from bs4 import BeautifulSoup

BASE_URL = "https://portais.univasf.edu.br"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 20

DATE_RE = re.compile(r"\d{2}[./]\d{2}[./]\d{4}")
DATE_PREFIX_RE = re.compile(r"^\s*(\d{2}[./]\d{2}[./]\d{4})\s*[–\-]\s*")


@dataclass
class NoticiaSetor:
    setor: str
    titulo: str
    data: str | None
    resumo: str
    url: str


def raspar_noticias_setor(setor_slug: str, setor_label: str, limite: int = 6) -> list[NoticiaSetor]:
    """Busca as últimas notícias de um setor. Retorna lista vazia em caso de erro
    (nunca lança exceção para não derrubar o restante do scraper)."""
    url = f"{BASE_URL}/{setor_slug}/noticias/ultimas-noticias"
    try:
        resp = requests.get(url, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[setor_noticias] falha ao buscar {url}: {exc}")
        return []

    soup = BeautifulSoup(resp.text, "lxml")
    noticias: list[NoticiaSetor] = []

    # No template de notícias da UNIVASF (Plone), cada item é um
    # <h2 class="headline"><a class="summary url">DD.MM.AAAA – Título</a></h2>.
    links = soup.select("h2.headline a.summary, h2.tileHeadline a, article a.summary")
    for link in links[: limite * 2]:
        texto = link.get_text(strip=True)
        if not texto:
            continue
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

        noticias.append(
            NoticiaSetor(setor=setor_label, titulo=titulo, data=data, resumo="", url=href)
        )
        if len(noticias) >= limite:
            break

    return noticias


def raspar_todos_setores() -> list[dict]:
    setores = [
        ("proae", "PROAE"),
        ("proex", "PROEX"),
        ("proen", "PROEN"),
    ]
    resultado: list[dict] = []
    for slug, label in setores:
        for noticia in raspar_noticias_setor(slug, label, limite=20):
            resultado.append(asdict(noticia))
    return resultado


if __name__ == "__main__":
    import json

    print(json.dumps(raspar_todos_setores(), ensure_ascii=False, indent=2))
