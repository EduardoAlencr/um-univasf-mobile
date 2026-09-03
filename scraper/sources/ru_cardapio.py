"""Acha o cardápio vigente do RU (PDF) e extrai as refeições por dia.

Fluxo:
1. Busca ``@@busca?Subject:list=Cardápio vigente`` no portal para achar o link
   do PDF mais recente.
2. Baixa o PDF e usa pdfplumber para extrair a tabela.
3. Mapeia as linhas conhecidas (FRUTA, PRATO PROTEICO, PRATO PRINCIPAL,
   PROTEÍNA, VEGETARIANO, ...) para os 5 dias úteis, café/almoço/jantar.

O layout é o mesmo usado pela empresa terceirizada (Marmitek) todo semestre,
mas se a estrutura mudar e nada bater com o esperado, retornamos lista vazia
em vez de dados errados — o app cai de volta no mock.
"""
from __future__ import annotations

import io
import re
from dataclasses import dataclass, asdict

import pdfplumber
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://portais.univasf.edu.br"
BUSCA_URL = f"{BASE_URL}/proae/@@busca?Subject%3Alist=Card%C3%A1pio%20vigente"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 30

DIAS_SEMANA = ["Segunda", "Terça", "Quarta", "Quinta", "Sexta"]

# Linhas de cada bloco de refeição que consideramos "o prato principal do dia"
# para montar a descrição curta que o app mostra.
LINHAS_RELEVANTES = {
    "café da manhã": ["PRATO PROTEICO", "PRATO VEGETARIANO"],
    "almoço": ["PRATO PRINCIPAL", "VEGETARIANO"],
    "jantar": ["PROTEÍNA", "VEGETARIANO"],
}


@dataclass
class RefeicaoDia:
    dia: str
    periodo: str  # "Café da Manhã" | "Almoço" | "Jantar"
    descricao: str


def _achar_pdf_vigente() -> tuple[str, str] | None:
    """Retorna (url_pdf, titulo) do cardápio vigente, ou None se não achar."""
    try:
        resp = requests.get(BUSCA_URL, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[ru_cardapio] falha na busca: {exc}")
        return None

    soup = BeautifulSoup(resp.text, "lxml")
    link = soup.find("a", href=re.compile(r"\.pdf(/|$|\?)", re.IGNORECASE))
    if not link:
        return None

    pdf_url = link["href"]
    if pdf_url.startswith("/"):
        pdf_url = BASE_URL + pdf_url
    # a busca retorna a página "/view" do arquivo; removê-la baixa o PDF cru.
    if pdf_url.endswith("/view"):
        pdf_url = pdf_url[: -len("/view")]
    titulo = link.get_text(strip=True) or "Cardápio vigente"
    return pdf_url, titulo


def _extrair_periodo(titulo: str, texto_pdf: str) -> str:
    match = re.search(r"\d{2}/\d{2}(?:/\d{4})?\s*a\s*\d{2}/\d{2}(?:/\d{4})?", texto_pdf or titulo)
    return match.group(0) if match else titulo


SECOES = {"CAFÉ DA MANHÃ", "ALMOÇO", "JANTAR"}


def _bloco_da_secao(tabela: list[list[str | None]], nome_secao: str) -> list[list[str | None]]:
    """Retorna só as linhas entre o cabeçalho ``nome_secao`` e o próximo
    cabeçalho de seção (ou o fim da tabela)."""
    inicio = None
    for i, linha in enumerate(tabela):
        if linha and linha[0] and linha[0].strip().upper() == nome_secao.upper():
            inicio = i + 1
            break
    if inicio is None:
        return []

    fim = len(tabela)
    for i in range(inicio, len(tabela)):
        primeiro = tabela[i][0] if tabela[i] else None
        if primeiro and primeiro.strip().upper() in SECOES:
            fim = i
            break
    return tabela[inicio:fim]


def _limpar(texto: str) -> str:
    return " ".join(texto.split())


def _linha_por_rotulo(bloco: list[list[str | None]], rotulo: str) -> list[str] | None:
    for linha in bloco:
        if not linha or not linha[0]:
            continue
        if linha[0].strip().upper() == rotulo.upper():
            return [_limpar(c) if c else "" for c in linha[1:6]]
    return None


def _montar_refeicoes(tabela: list[list[str | None]], periodo_label: str, nome_secao: str, rotulos: list[str]) -> list[RefeicaoDia]:
    bloco = _bloco_da_secao(tabela, nome_secao)
    valores_por_rotulo = []
    for rotulo in rotulos:
        linha = _linha_por_rotulo(bloco, rotulo)
        if linha:
            valores_por_rotulo.append(linha)

    if not valores_por_rotulo:
        return []

    refeicoes = []
    for i, dia in enumerate(DIAS_SEMANA):
        partes = [v[i] for v in valores_por_rotulo if i < len(v) and v[i]]
        if not partes:
            continue
        refeicoes.append(RefeicaoDia(dia=dia, periodo=periodo_label, descricao=" · ".join(partes)))
    return refeicoes


def raspar_cardapio_ru() -> dict:
    """Retorna {"periodo": str, "refeicoes": [RefeicaoDia,...]} ou dict vazio."""
    achado = _achar_pdf_vigente()
    if not achado:
        return {}
    pdf_url, titulo = achado

    try:
        resp = requests.get(pdf_url, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[ru_cardapio] falha ao baixar PDF: {exc}")
        return {}

    try:
        with pdfplumber.open(io.BytesIO(resp.content)) as pdf:
            pagina = pdf.pages[0]
            tabelas = pagina.extract_tables()
            texto = pagina.extract_text() or ""
    except Exception as exc:  # pdfplumber pode levantar vários tipos de erro
        print(f"[ru_cardapio] falha ao parsear PDF: {exc}")
        return {}

    if not tabelas:
        return {}

    tabela = max(tabelas, key=len)  # a tabela principal costuma ser a maior

    refeicoes: list[RefeicaoDia] = []
    refeicoes += _montar_refeicoes(tabela, "Café da Manhã", "CAFÉ DA MANHÃ", LINHAS_RELEVANTES["café da manhã"])
    refeicoes += _montar_refeicoes(tabela, "Almoço", "ALMOÇO", LINHAS_RELEVANTES["almoço"])
    refeicoes += _montar_refeicoes(tabela, "Jantar", "JANTAR", LINHAS_RELEVANTES["jantar"])

    if not refeicoes:
        return {}

    return {
        "periodo": _extrair_periodo(titulo, texto),
        "refeicoes": [asdict(r) for r in refeicoes],
        "legenda": _extrair_legenda(texto),
    }


def _extrair_legenda(texto: str) -> str | None:
    """Captura a linha de rodapé com o significado dos asteriscos
    (ex.: "*Contém lactose ** Contém produtos de origem animal
    ***Contém glúten"), que muda pouco mas não é fixa — melhor raspar do
    que hardcodar."""
    match = re.search(r"\*Contém.*?(?:altera[cç][õoã]es)?\.?$", texto, re.IGNORECASE | re.MULTILINE)
    if not match:
        return None
    return match.group(0).replace("Cardápio sujeito a alterações", "").strip()


if __name__ == "__main__":
    import json

    print(json.dumps(raspar_cardapio_ru(), ensure_ascii=False, indent=2))
