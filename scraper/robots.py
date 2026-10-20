"""Checagem de robots.txt compartilhada por todos os módulos de coleta.

Cada domínio raspado (portais.univasf.edu.br, cecomp.univasf.edu.br,
siga.univasf.edu.br) é consultado uma única vez por execução — o
``RobotFileParser`` é cacheado por domínio para não buscar o robots.txt a
cada requisição. Se o robots.txt não existir ou a busca falhar por qualquer
motivo, assume-se permitido (mesmo padrão de resiliência do resto do
scraper: uma falha de rede nunca deve impedir a coleta)."""
from __future__ import annotations

from urllib.parse import urlparse
from urllib.robotparser import RobotFileParser

import requests

_cache: dict[str, RobotFileParser] = {}


def _parser_para(url: str) -> RobotFileParser:
    partes = urlparse(url)
    dominio = f"{partes.scheme}://{partes.netloc}"
    if dominio in _cache:
        return _cache[dominio]

    parser = RobotFileParser()
    parser.set_url(f"{dominio}/robots.txt")
    try:
        resp = requests.get(f"{dominio}/robots.txt", timeout=10)
        if resp.status_code == 200:
            parser.parse(resp.text.splitlines())
        else:
            # Sem robots.txt publicado: trata como "tudo permitido".
            parser.parse([])
    except requests.RequestException:
        parser.parse([])

    _cache[dominio] = parser
    return parser


def permitido(url: str, user_agent: str = "UM-UNIVASF-Mobile-Scraper") -> bool:
    """True se o robots.txt do domínio permite raspar essa URL (ou se não
    foi possível determinar, caso em que assume permitido)."""
    try:
        return _parser_para(url).can_fetch(user_agent, url)
    except Exception:
        return True


class BloqueadoPorRobotsTxt(requests.RequestException):
    """Levantada no lugar de uma resposta HTTP quando o robots.txt do site
    proíbe a URL — é uma subclasse de RequestException de propósito, para
    ser capturada pelos mesmos blocos `except requests.RequestException`
    que cada módulo de coleta já usa, sem precisar de tratamento à parte."""


def get(url: str, **kwargs):
    """Substituto de requests.get que primeiro verifica o robots.txt do
    domínio. Levanta BloqueadoPorRobotsTxt se a URL não for permitida."""
    if not permitido(url):
        raise BloqueadoPorRobotsTxt(f"bloqueado por robots.txt: {url}")
    return requests.get(url, **kwargs)
