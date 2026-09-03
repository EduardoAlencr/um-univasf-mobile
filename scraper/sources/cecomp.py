"""Scraper best-effort para o colegiado de Engenharia de Computação (CECOMP).

Diferente dos setores em portais.univasf.edu.br (Plone), o CECOMP roda em
domínio e CMS próprios (cecomp.univasf.edu.br). A estrutura pode variar mais
e não temos garantia de padrão — por isso cobrimos apenas título + link dos
itens mais recentes da home, e qualquer outro colegiado exigirá um scraper
próprio equivalente a este (não generalizamos).
"""
from __future__ import annotations

from dataclasses import dataclass, asdict

import requests
import urllib3
from bs4 import BeautifulSoup

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

URL = "https://cecomp.univasf.edu.br/"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 20


@dataclass
class NoticiaColegiado:
    colegiado: str
    titulo: str
    url: str


def raspar_cecomp(limite: int = 6) -> list[dict]:
    try:
        resp = requests.get(URL, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.exceptions.SSLError:
        # O certificado do cecomp.univasf.edu.br está mal configurado
        # (cadeia incompleta) no momento em que este scraper foi escrito.
        # Como é um site público e institucional (não há dado sensível
        # trafegando), aceitamos pular a verificação aqui como fallback
        # pragmático — não fazer isso para nenhuma outra fonte.
        try:
            resp = requests.get(URL, headers=HEADERS, timeout=TIMEOUT, verify=False)
            resp.raise_for_status()
        except requests.RequestException as exc:
            print(f"[cecomp] falha ao buscar {URL} mesmo sem verificar SSL: {exc}")
            return []
    except requests.RequestException as exc:
        print(f"[cecomp] falha ao buscar {URL}: {exc}")
        return []

    soup = BeautifulSoup(resp.text, "lxml")
    resultado: list[NoticiaColegiado] = []

    for link in soup.select("article a[href], .post a[href], h2 a[href], h3 a[href]"):
        titulo = link.get_text(strip=True)
        href = link.get("href", "")
        if not titulo or len(titulo) < 8 or not href:
            continue
        if href.startswith("/"):
            href = URL.rstrip("/") + href
        resultado.append(NoticiaColegiado(colegiado="CECOMP", titulo=titulo, url=href))
        if len(resultado) >= limite:
            break

    return [asdict(n) for n in resultado]


if __name__ == "__main__":
    import json

    print(json.dumps(raspar_cecomp(), ensure_ascii=False, indent=2))
