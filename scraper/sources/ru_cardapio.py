"""Acha o cardápio vigente do RU (PDF) e extrai o cardápio completo por dia.

Fluxo:
1. Busca por texto ("cardapio") no portal, ordenado por data de modificação
   decrescente, e pega o primeiro resultado em PDF cujo link/título aponte
   pra um cardápio semanal — isso é robusto a mudanças de estrutura do site
   (a tag "Cardápio vigente" usada antes parou de ser aplicada; buscar pelo
   PDF mais recente evita depender dessa marcação manual).
2. Baixa o PDF e usa pdfplumber para extrair a tabela.
3. Pra cada refeição (desjejum/almoço/jantar), captura TODAS as categorias
   do cardápio daquele dia (proteína, vegetariano, salada, arroz, feijão,
   guarnição, molho, bebida, sobremesa, fruta...), não só um resumo.

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
BUSCA_URL = f"{BASE_URL}/proae/@@search?SearchableText=cardapio&sort_on=Date&sort_order=reverse"
HEADERS = {"User-Agent": "UM-UNIVASF-Mobile-Scraper/1.0 (+TCC academico)"}
TIMEOUT = 30

DIAS_SEMANA = ["Segunda", "Terça", "Quarta", "Quinta", "Sexta"]
SECOES = {"CAFÉ DA MANHÃ", "DESJEJUM", "ALMOÇO", "JANTAR"}

# Nome de exibição amigável pros rótulos de linha do PDF (que variam:
# "PRATO PROTEICO 1", "ACOMP_01", "SALADA CRUA/ COZIDA", ...). Correspondência
# por prefixo — o rótulo cru vira a chave de busca (maiúsculo, sem espaço).
_APELIDOS = [
    ("PRATOPROTEICO", "Proteína"),
    ("PRATOVEGETARIANO", "Vegetariano"),
    ("VEGETARIANO", "Vegetariano"),
    ("SALADA", "Salada"),
    ("ACOMP", "Acompanhamento"),
    ("GUARNI", "Guarnição"),
    ("MOLHO", "Molho"),
    ("BEBIDA", "Bebida"),
    ("SOBREMESA", "Sobremesa"),
    ("FRUTA", "Fruta"),
]


@dataclass
class ItemCardapio:
    categoria: str
    prato: str


@dataclass
class RefeicaoDia:
    dia: str
    periodo: str  # "Café da Manhã" | "Almoço" | "Jantar"
    itens: list[ItemCardapio]


def _achar_pdf_vigente() -> tuple[str, str] | None:
    """Retorna (url_pdf, titulo) do cardápio vigente, ou None se não achar."""
    try:
        resp = requests.get(BUSCA_URL, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"[ru_cardapio] falha na busca: {exc}")
        return None

    soup = BeautifulSoup(resp.text, "lxml")
    for link in soup.select("dt.contenttype-file a"):
        href = link.get("href", "")
        titulo = link.get_text(strip=True)
        if "cardapio" not in href.lower() and "cardápio" not in titulo.lower():
            continue

        pdf_url = href
        if pdf_url.startswith("/"):
            pdf_url = BASE_URL + pdf_url
        # a busca retorna a página "/view" do arquivo; removê-la baixa o PDF cru.
        if pdf_url.endswith("/view"):
            pdf_url = pdf_url[: -len("/view")]
        return pdf_url, titulo or "Cardápio vigente"

    return None


def _extrair_periodo(titulo: str, texto_pdf: str) -> str:
    match = re.search(r"\d{2}/\d{2}(?:/\d{4})?\s*a\s*\d{2}/\d{2}(?:/\d{4})?", texto_pdf or titulo)
    return match.group(0) if match else titulo


def _bloco_da_secao(tabela: list[list[str | None]], nome_secao: str) -> list[list[str | None]]:
    """Retorna só as linhas entre o cabeçalho ``nome_secao`` (ou seus
    sinônimos) e o próximo cabeçalho de seção (ou o fim da tabela)."""
    sinonimos = {"ALMOÇO": {"ALMOÇO"}, "JANTAR": {"JANTAR"}, "CAFÉ DA MANHÃ": {"CAFÉ DA MANHÃ", "DESJEJUM"}}[nome_secao]

    inicio = None
    for i, linha in enumerate(tabela):
        primeiro = linha[0].strip().upper() if linha and linha[0] else None
        if primeiro in sinonimos:
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


def _apelido(rotulo_cru: str) -> str:
    chave = re.sub(r"[^A-ZÀ-Ú0-9]", "", rotulo_cru.upper())
    for prefixo, nome in _APELIDOS:
        if chave.startswith(prefixo):
            # preserva sufixo numérico, ex. "PRATOPROTEICO1" -> "Proteína 1"
            sufixo = chave[len(prefixo):]
            return f"{nome} {sufixo}".strip() if sufixo.isdigit() else nome
    return rotulo_cru.strip().title()


def _linhas_de_itens(bloco: list[list[str | None]]) -> list[tuple[str, list[str]]]:
    """Cada linha do bloco vira (rótulo, [prato por dia]) — linhas sem rótulo
    (ex. o suco extra embaixo de "BEBIDAS") são mescladas na linha anterior."""
    resultado: list[tuple[str, list[str]]] = []
    for linha in bloco:
        if not linha:
            continue
        rotulo_cru = linha[0].strip() if linha[0] else None
        if rotulo_cru and rotulo_cru.upper() == "PREPARACÃO":
            continue  # cabeçalho dos dias da semana, não é item
        valores = [_limpar(c) if c else "" for c in linha[1:6]]
        if not any(valores):
            continue
        if rotulo_cru:
            resultado.append((_apelido(rotulo_cru), valores))
        elif resultado:
            categoria_anterior, valores_anteriores = resultado[-1]
            resultado[-1] = (
                categoria_anterior,
                [f"{a} / {b}" if a and b else (a or b) for a, b in zip(valores_anteriores, valores)],
            )
    return resultado


def _montar_refeicoes(tabela: list[list[str | None]], periodo_label: str, nome_secao: str) -> list[RefeicaoDia]:
    bloco = _bloco_da_secao(tabela, nome_secao)
    linhas = _linhas_de_itens(bloco)
    if not linhas:
        return []

    refeicoes = []
    for i, dia in enumerate(DIAS_SEMANA):
        itens = [ItemCardapio(categoria=rotulo, prato=valores[i]) for rotulo, valores in linhas if i < len(valores) and valores[i]]
        if not itens:
            continue
        refeicoes.append(RefeicaoDia(dia=dia, periodo=periodo_label, itens=itens))
    return refeicoes


def raspar_cardapio_ru() -> dict:
    """Retorna {"periodo": str, "refeicoes": [...], "legenda": str|None} ou dict vazio."""
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
    refeicoes += _montar_refeicoes(tabela, "Café da Manhã", "CAFÉ DA MANHÃ")
    refeicoes += _montar_refeicoes(tabela, "Almoço", "ALMOÇO")
    refeicoes += _montar_refeicoes(tabela, "Jantar", "JANTAR")

    if not refeicoes:
        return {}

    return {
        "periodo": _extrair_periodo(titulo, texto),
        "refeicoes": [
            {"dia": r.dia, "periodo": r.periodo, "itens": [asdict(it) for it in r.itens]} for r in refeicoes
        ],
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
