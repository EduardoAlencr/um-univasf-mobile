"""Parseia o PDF de itinerário dos ônibus estudantis da PROAE.

Por enquanto lê o PDF local fornecido em MATERIAIS/ (o documento não tem uma
URL pública estável identificada ainda — ver README do scraper para o plano
de manter isso atualizado automaticamente no futuro).

Layout do PDF: uma única tabela por página, com linhas de três tipos:
  - cabeçalho de turno: "Itinerário: MANHÃ" / "Itinerário: TARDE"
  - cabeçalho de viagem: 'ÔNIBUS "A"  JUAZEIRO -> CCA -> ... - AUGUSTO'
  - parada: horário (HH:MM) na primeira coluna, local na quarta coluna
"""
from __future__ import annotations

import re
from dataclasses import dataclass, asdict, field

import pdfplumber

HORA_RE = re.compile(r"^\d{1,2}[:;]\d{2}$")
TURNO_RE = re.compile(r"Itiner[aá]rio\s*:?\s*(MANH[AÃ]|TARDE)", re.IGNORECASE)
# As aspas em torno da letra são obrigatórias no regex para não confundir
# textos como "(ÔNIBUS COM PLATAFORMA ELEVATÓRIA)" com um cabeçalho real
# (sem isso, "COM" seria lido como se "C" fosse a letra do ônibus).
ONIBUS_RE = re.compile(r'[ÔO]NIBUS\s*["\'“]([A-Z])["\'”]\s*(.*)')


def _limpar(texto: str | None) -> str:
    if not texto:
        return ""
    # (cid:415) é a ligadura "ti" que não tem glifo mapeado nesse PDF.
    return texto.replace("(cid:415)", "ti").strip()


@dataclass
class Parada:
    horario: str
    local: str


@dataclass
class Viagem:
    letra: str
    turno: str
    rota: str
    paradas: list[Parada] = field(default_factory=list)


def _linha_relevante(row: list) -> tuple[str, str, str]:
    """Retorna (primeira_coluna_limpa, ultima_coluna_nao_vazia_limpa,
    texto_completo_da_linha). O texto completo é usado para reconhecer
    cabeçalhos de turno/ônibus, que nem sempre caem na primeira coluna
    (o layout do PDF varia entre páginas)."""
    primeira = _limpar(row[0] if row else None)
    ultima = ""
    for cel in reversed(row[1:]):
        if cel:
            ultima = _limpar(cel)
            break
    completo = " ".join(_limpar(c) for c in row if c)
    return primeira, ultima, completo


def parsear_itinerario(caminho_pdf: str) -> list[dict]:
    viagens: list[Viagem] = []
    turno_atual = "Manhã"
    viagem_atual: Viagem | None = None

    with pdfplumber.open(caminho_pdf) as pdf:
        for pagina in pdf.pages:
            tabelas = pagina.extract_tables()
            for tabela in tabelas:
                for row in tabela:
                    if not row or all(c is None or str(c).strip() == "" for c in row):
                        continue
                    primeira, ultima, completo = _linha_relevante(row)
                    if not primeira and not completo:
                        continue

                    turno_match = TURNO_RE.search(completo)
                    if turno_match:
                        bruto = turno_match.group(1).upper()
                        turno_atual = "Manhã" if bruto.startswith("MANH") else "Tarde"
                        continue

                    onibus_match = ONIBUS_RE.search(completo)
                    if onibus_match:
                        if viagem_atual and viagem_atual.paradas:
                            viagens.append(viagem_atual)
                        letra = onibus_match.group(1).upper()
                        rota = onibus_match.group(2).strip(' -"\'')
                        # normaliza travessão/en-dash pro hífen comum, pra não
                        # escapar dos filtros abaixo por causa do caractere
                        rota = rota.replace("–", "-").replace("—", "-")
                        # remove prefixos redundantes tipo "SAÍDA DO CCA ÀS 15:10 -"
                        # (tolerando espaço espúrio dentro do horário, ex. "16:1 0")
                        rota = re.sub(
                            r"^SA[IÍ]DA\s+D[EO]\s+.*?\s+[AÀ]S\s+\d{1,2}[:;]\d\s?\d\s*-\s*",
                            "",
                            rota,
                            flags=re.IGNORECASE,
                        )
                        # o nome do motorista vem sempre como o último trecho
                        # depois de um " - " solto (diferente das setas "->"
                        # usadas entre os pontos da rota) — é dado pessoal,
                        # não faz parte do itinerário, então descartamos.
                        if " - " in rota:
                            rota = rota.rsplit(" - ", 1)[0].strip()
                        viagem_atual = Viagem(letra=letra, turno=turno_atual, rota=rota, paradas=[])
                        continue

                    if primeira.upper() in {"HORÁRIO", "HORARIO"}:
                        continue

                    if HORA_RE.match(primeira) and ultima and viagem_atual is not None:
                        viagem_atual.paradas.append(Parada(horario=primeira.replace(";", ":"), local=ultima))

    if viagem_atual and viagem_atual.paradas:
        viagens.append(viagem_atual)

    return [
        {
            "letra": v.letra,
            "turno": v.turno,
            "rota": v.rota,
            "horario_saida": v.paradas[0].horario if v.paradas else None,
            "paradas": [asdict(p) for p in v.paradas],
        }
        for v in viagens
    ]


def raspar_itinerario() -> list[dict]:
    """Lê o PDF local do itinerário. Ainda não temos uma URL pública estável
    para baixar isso automaticamente — o arquivo precisa ser atualizado
    manualmente em MATERIAIS/ quando a PROAE publicar uma nova versão (ver
    README do scraper)."""
    from pathlib import Path

    caminho = Path(__file__).parent.parent.parent / "MATERIAIS" / "Itinerário PROAE 2026.2.pdf"
    if not caminho.exists():
        print(f"[itinerario] PDF não encontrado em {caminho}")
        return []
    try:
        return parsear_itinerario(str(caminho))
    except Exception as exc:
        print(f"[itinerario] falha ao parsear: {exc}")
        return []


if __name__ == "__main__":
    import json
    import sys

    caminho = sys.argv[1] if len(sys.argv) > 1 else None
    if not caminho:
        print("uso: python itinerario.py <caminho_do_pdf>")
        sys.exit(1)
    resultado = parsear_itinerario(caminho)
    print(json.dumps(resultado, ensure_ascii=False, indent=2))
    print(f"\n{len(resultado)} viagens encontradas", file=sys.stderr)
