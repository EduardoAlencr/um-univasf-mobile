"""Orquestra todas as fontes de dados e grava output/dados_univasf.json.

Uso:
    python run.py

O JSON gerado deve ser copiado manualmente para
``assets/data/dados_univasf.json`` no projeto Flutter (por enquanto — a
evolução natural é publicar isso num endpoint HTTP e o app buscar direto).
"""
from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

from sources.calendario import raspar_calendario
from sources.cecomp import raspar_cecomp
from sources.itinerario import raspar_itinerario
from sources.ru_cardapio import raspar_cardapio_ru
from sources.setor_noticias import raspar_todos_setores
from sources.siga_avisos import raspar_avisos_siga

OUTPUT_DIR = Path(__file__).parent / "output"
OUTPUT_FILE = OUTPUT_DIR / "dados_univasf.json"


def _dados_anteriores() -> dict:
    if OUTPUT_FILE.exists():
        try:
            return json.loads(OUTPUT_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def main() -> None:
    anterior = _dados_anteriores()

    print("Coletando notícias dos setores (PROAE, PROEX, PROEN)...")
    noticias = raspar_todos_setores()
    print(f"  -> {len(noticias)} notícias")

    print("Coletando cardápio vigente do RU...")
    cardapio = raspar_cardapio_ru()
    if not cardapio and anterior.get("ru_cardapio"):
        print("  -> sem dados agora; mantendo o último cardápio válido coletado")
        cardapio = anterior["ru_cardapio"]
    else:
        print(f"  -> {'ok' if cardapio else 'sem dados (fallback pro mock no app)'}")

    print("Coletando calendário acadêmico...")
    calendario = raspar_calendario()
    if not calendario and anterior.get("calendario"):
        print("  -> sem eventos agora; mantendo a última lista válida")
        calendario = anterior["calendario"]
    else:
        print(f"  -> {len(calendario)} eventos na janela considerada")

    print("Coletando notícias do CECOMP...")
    cecomp = raspar_cecomp()
    print(f"  -> {len(cecomp)} itens")

    print("Lendo itinerário dos ônibus (PDF local da PROAE)...")
    itinerario = raspar_itinerario()
    if not itinerario and anterior.get("itinerario_onibus"):
        print("  -> sem dados agora; mantendo o último itinerário válido")
        itinerario = anterior["itinerario_onibus"]
    else:
        print(f"  -> {len(itinerario)} viagens")

    print("Coletando avisos públicos da tela inicial do SIG@...")
    avisos_siga = raspar_avisos_siga()
    if not avisos_siga and anterior.get("avisos_siga"):
        print("  -> sem avisos agora; mantendo os últimos coletados")
        avisos_siga = anterior["avisos_siga"]
    else:
        print(f"  -> {len(avisos_siga)} avisos")

    dados = {
        "gerado_em": datetime.now().isoformat(timespec="seconds"),
        "noticias_setores": noticias or anterior.get("noticias_setores", []),
        "ru_cardapio": cardapio,
        "calendario": calendario,
        "colegiado_cecomp": cecomp or anterior.get("colegiado_cecomp", []),
        "itinerario_onibus": itinerario,
        "avisos_siga": avisos_siga,
    }

    OUTPUT_DIR.mkdir(exist_ok=True)
    OUTPUT_FILE.write_text(json.dumps(dados, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nSalvo em {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
