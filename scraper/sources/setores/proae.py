"""Raspa as páginas de auxílios/bolsas de permanência da PROAE — públicas
(sem login), mas em texto corrido, não em tabela.

As URLs abaixo são uma escolha humana (são as páginas que confirmei, na
exploração do site, que respondem sem login e trazem valor/critério no
próprio texto — `auxilio-moradia` e `auxilio-transporte` são login-walled e
por isso não entram). Adicionar uma página no futuro também é decisão
humana, não descoberta automática.

Como o conteúdo é texto livre (não tabela), a extração de valor/critério/
campi/regras de acúmulo é por regex e busca de palavras-chave, não por
posição fixa — mais frágil a mudanças de redação do que os scrapers
baseados em tabela/HTML estruturado. Por isso cada campo é opcional: se um
campo não for encontrado, a página ainda é incluída com o que foi
encontrado (nome + url sempre presentes), nunca inventando um valor/
critério que não está no texto.

A página da Bolsa Permanência MEC descreve DUAS modalidades com valores e
público-alvo diferentes (indígenas/quilombolas e estudantes de Medicina),
então ela gera duas entradas, não uma — ver `_raspar_bolsa_mec`.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, asdict, field

import requests

import robots
from bs4 import BeautifulSoup

BASE_URL = "https://portais.univasf.edu.br"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 30

_PAGINAS_SIMPLES = [
    "proae/servicos-proae/auxilio-alimentacao",
    "proae/servicos-proae/auxilio-permanencia",
    "proae/servicos-proae/bolsa-permanencia-univasf",
]

URL_CONTATO = f"{BASE_URL}/proae/proae/contato"
_PAGINA_MEC = "proae/servicos-proae/bolsa-permanencia-mec-indigena-e-quilombola"

_CAMPI = {
    "Petrolina": ["petrolina"],
    "Ciências Agrárias": ["ciências agrárias", "cca"],
    "Juazeiro": ["juazeiro"],
    "Senhor do Bonfim": ["senhor do bonfim"],
    "Paulo Afonso": ["paulo afonso"],
    "Serra da Capivara": ["serra da capivara", "são raimundo nonato"],
    "Salgueiro": ["salgueiro"],
}

_REGEX_VALOR = re.compile(r"R\$\s?[\d.,]+")
_REGEX_CRITERIO = re.compile(r"renda per capita[^,.;]{0,80}", re.IGNORECASE)
_REGEX_DURACAO = re.compile(r"em torno de (\d+) dias", re.IGNORECASE)
# Separa em frases sem quebrar valores como "R$1.400,00" (o ponto aí tem
# dígito dos dois lados, então o lookaround abaixo não trata como fim de
# frase).
_REGEX_FRASES = re.compile(r"(?<!\d)\.(?!\d)")
_REGEX_ACUMULA = re.compile(r"acumular.*?\bcom\b[:\s]*(.+)", re.IGNORECASE)


@dataclass
class AuxilioProae:
    nome: str
    valor: str | None
    criterio: str | None
    campi: list[str] = field(default_factory=list)
    acumula_com: list[str] = field(default_factory=list)
    nao_acumula_com: list[str] = field(default_factory=list)
    duracao_dias: int | None = None
    inscricao_online: bool = False
    url: str = ""


def _regras_acumulo(texto: str) -> tuple[list[str], list[str]]:
    sim: list[str] = []
    nao: list[str] = []
    for frase in _REGEX_FRASES.split(texto):
        if "acumular" not in frase.lower():
            continue
        m = _REGEX_ACUMULA.search(frase)
        if not m:
            continue
        resto = m.group(1).strip().rstrip(".")
        if re.search(r"n[ãa]o\s+poder", frase, re.IGNORECASE):
            nao.append(resto)
        else:
            sim.append(resto)
    return sim, nao


def _buscar(caminho: str) -> tuple[str, str] | None:
    """Busca a página e retorna `(nome, texto_do_conteudo)`, ou None se
    falhar ou for login-wall (conteúdo curto demais pra ser real)."""
    url = f"{BASE_URL}/{caminho}"
    try:
        resp = robots.get(url, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[proae_auxilios] falha ao buscar {url}: {exc}")
        return None

    soup = BeautifulSoup(resp.text, "lxml")
    titulo_tag = soup.select_one("h1.documentFirstHeading")
    nome = titulo_tag.get_text(strip=True) if titulo_tag else None
    conteudo = soup.select_one("div#content-core")
    texto = conteudo.get_text(" ", strip=True) if conteudo else ""
    if not nome or len(texto) < 200:
        print(f"[proae_auxilios] {url} sem conteúdo real (possível login-wall) — ignorada")
        return None
    return nome, texto


def _raspar_pagina_simples(caminho: str) -> AuxilioProae | None:
    achado = _buscar(caminho)
    if achado is None:
        return None
    nome, texto = achado

    valor_match = _REGEX_VALOR.search(texto)
    criterio_match = _REGEX_CRITERIO.search(texto)
    duracao_match = _REGEX_DURACAO.search(texto)
    texto_lower = texto.lower()
    campi = [nome_campus for nome_campus, aliases in _CAMPI.items() if any(a in texto_lower for a in aliases)]
    sim, nao = _regras_acumulo(texto)

    return AuxilioProae(
        nome=nome,
        valor=valor_match.group() if valor_match else None,
        criterio=criterio_match.group().strip() if criterio_match else None,
        campi=campi,
        acumula_com=sim,
        nao_acumula_com=nao,
        duracao_dias=int(duracao_match.group(1)) if duracao_match else None,
        inscricao_online="PAE" in texto,
        url=f"{BASE_URL}/{caminho}",
    )


def _raspar_bolsa_mec() -> list[AuxilioProae]:
    achado = _buscar(_PAGINA_MEC)
    if achado is None:
        return []
    _, texto = achado
    url = f"{BASE_URL}/{_PAGINA_MEC}"
    sim, nao = _regras_acumulo(texto)
    inscricao_online = "PAE" in texto

    modalidades = [
        ("Bolsa Permanência MEC — Indígenas e Quilombolas", ["indígena", "quilombola"]),
        ("Bolsa Permanência MEC — Estudantes de Medicina", ["médic"]),
    ]
    resultado = []
    for nome, palavras_chave in modalidades:
        valor = None
        for m in _REGEX_VALOR.finditer(texto):
            contexto = texto[max(0, m.start() - 80):m.start()].lower()
            if any(p in contexto for p in palavras_chave):
                valor = m.group()
                break
        resultado.append(AuxilioProae(
            nome=nome,
            valor=valor,
            criterio=None,
            campi=["Paulo Afonso"] if "médic" in palavras_chave[0] else [],
            acumula_com=sim,
            nao_acumula_com=nao,
            inscricao_online=inscricao_online,
            url=url,
        ))
    return resultado


def raspar_auxilios_proae() -> list[dict]:
    """Retorna a lista de auxílios/bolsas da PROAE com o que foi possível
    extrair de cada página, ou lista vazia em caso de erro total (nunca
    lança exceção)."""
    auxilios = [a for a in (_raspar_pagina_simples(p) for p in _PAGINAS_SIMPLES) if a is not None]
    auxilios.extend(_raspar_bolsa_mec())
    return [asdict(a) for a in auxilios]


@dataclass
class ContatoSetor:
    setor: str
    email: str | None
    telefone: str | None


_REGEX_LABEL_SIMPLES = re.compile(r"^[^@:]{1,60}:$")  # "Rótulo:" numa linha, sem e-mail/dígitos


def raspar_contato_proae() -> list[dict]:
    """Retorna os contatos por setor interno da PROAE (pró-reitoria,
    pagamento de bolsas, transporte, restaurantes, serviço social,
    residências) — lista vazia em caso de erro, nunca lança exceção.

    A página é "Rótulo:" numa linha, seguido de uma ou mais linhas de
    valor livre (e-mail(s) e telefone(s) juntos, sem rótulo próprio). Um
    rótulo cujo valor ainda não apareceu (ex. "Campus Petrolina Sede:"
    antes de "Campus Juazeiro/BA:") é unido ao próximo rótulo em vez de
    virar uma seção vazia — é assim que a página representa "esses 3
    campi compartilham o mesmo e-mail de Restaurante Universitário"."""
    try:
        resp = robots.get(URL_CONTATO, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[proae] falha ao buscar contato: {exc}")
        return []

    soup = BeautifulSoup(resp.text, "lxml")
    conteudo = soup.select_one("div#content-core") or soup.select_one("div#content")
    if conteudo is None:
        return []
    linhas = [l.strip() for l in conteudo.get_text("\n", strip=True).split("\n") if l.strip()]

    secoes: dict[str, list[str]] = {}
    atual: str | None = None
    tem_valor = False
    for linha in linhas:
        if _REGEX_LABEL_SIMPLES.match(linha) and not re.search(r"\d{3,}", linha):
            rotulo = linha.rstrip(":").strip()
            if atual is not None and not tem_valor:
                atual = f"{atual} — {rotulo}"
            else:
                atual = rotulo
                secoes.setdefault(atual, [])
                tem_valor = False
            continue
        if atual:
            secoes.setdefault(atual, []).append(linha)
            tem_valor = True

    resultado = []
    for setor, valores in secoes.items():
        if not valores:
            continue
        texto = " ".join(valores)
        email_match = re.search(r"[\w.+-]+@[\w-]+\.[\w.-]+", texto)
        resultado.append(ContatoSetor(setor=setor, email=email_match.group() if email_match else None, telefone=None).__dict__ | {"texto": texto})
    return resultado


if __name__ == "__main__":
    import json

    print(json.dumps({"auxilios": raspar_auxilios_proae(), "contato": raspar_contato_proae()}, ensure_ascii=False, indent=2))
