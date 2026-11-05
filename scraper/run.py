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
from sources.setores.proae import raspar_auxilios_proae, raspar_contato_proae
from sources.setores.proen import raspar_contato_proen
from sources.setores.proex import raspar_contato_proex
from sources.setores.srca import (
    raspar_atendimento_presencial_srca,
    raspar_contatos_srca,
    raspar_horario_presencial_sic,
)

OUTPUT_DIR = Path(__file__).parent / "output"
OUTPUT_FILE = OUTPUT_DIR / "dados_univasf.json"
# Arquivo de verdade publicado pro app (via GitHub raw) — ao contrário de
# OUTPUT_FILE (que está no .gitignore e não existe num checkout limpo do
# GitHub Actions), este sempre existe no checkout, pois é versionado.
ASSETS_FILE = Path(__file__).parent.parent / "assets" / "data" / "dados_univasf.json"


def _dados_anteriores() -> dict:
    # Prioriza o arquivo publicado (ASSETS_FILE): é ele que reflete o último
    # estado realmente em produção. OUTPUT_FILE só existe em execuções
    # locais manuais e serve como fallback pra desenvolvimento.
    for candidato in (ASSETS_FILE, OUTPUT_FILE):
        if candidato.exists():
            try:
                return json.loads(candidato.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                continue
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
        print(f"  -> {len(itinerario.get('viagens', []))} viagens · vigência: {itinerario.get('vigencia')}")

    print("Coletando avisos públicos da tela inicial do SIG@...")
    avisos_siga = raspar_avisos_siga()
    if not avisos_siga and anterior.get("avisos_siga"):
        print("  -> sem avisos agora; mantendo os últimos coletados")
        avisos_siga = anterior["avisos_siga"]
    else:
        print(f"  -> {len(avisos_siga)} avisos")

    print("Coletando contatos do SIC por campus (SRCA)...")
    srca_contatos = raspar_contatos_srca()
    if not srca_contatos and anterior.get("srca_contatos"):
        print("  -> sem dados agora; mantendo os últimos contatos coletados")
        srca_contatos = anterior["srca_contatos"]
    else:
        print(f"  -> {len(srca_contatos)} campi")

    print("Coletando horário de atendimento presencial do SIC (PGD Teletrabalho)...")
    horario_presencial = raspar_horario_presencial_sic()
    print(f"  -> {len(horario_presencial)} campi com horário regular identificado")
    # Mescla no próprio contato por campus (substring, já que os nomes vêm
    # de fontes diferentes: "Petrolina" bate em "Campus Petrolina (Sede)").
    for contato in srca_contatos:
        nome_campus = (contato.get("campus") or "").lower()
        horario = next((h for chave, h in horario_presencial.items() if chave.lower() in nome_campus), None)
        contato["horario_presencial"] = horario

    print("Coletando atendimento presencial dos setores internos da SRCA (PGD Teletrabalho)...")
    srca_atendimento = raspar_atendimento_presencial_srca()
    if not srca_atendimento and anterior.get("srca_atendimento_presencial"):
        print("  -> sem dados agora; mantendo o último coletado")
        srca_atendimento = anterior["srca_atendimento_presencial"]
    else:
        print(f"  -> {len(srca_atendimento)} setores")

    print("Coletando auxílios e bolsas de permanência (PROAE)...")
    proae_auxilios = raspar_auxilios_proae()
    if not proae_auxilios and anterior.get("proae_auxilios"):
        print("  -> sem dados agora; mantendo os últimos auxílios coletados")
        proae_auxilios = anterior["proae_auxilios"]
    else:
        print(f"  -> {len(proae_auxilios)} auxílios/bolsas")

    print("Coletando contatos por setor (PROAE, PROEN, PROEX)...")
    contatos_setores = {
        "proae": raspar_contato_proae(),
        "proen": raspar_contato_proen(),
        "proex": raspar_contato_proex(),
    }
    for setor, lista in contatos_setores.items():
        if not lista and anterior.get("contatos_setores", {}).get(setor):
            print(f"  -> {setor}: sem dados agora; mantendo os últimos coletados")
            contatos_setores[setor] = anterior["contatos_setores"][setor]
        else:
            print(f"  -> {setor}: {len(lista)} contatos")

    dados = {
        "gerado_em": datetime.now().isoformat(timespec="seconds"),
        "noticias_setores": noticias or anterior.get("noticias_setores", []),
        "ru_cardapio": cardapio,
        "calendario": calendario,
        "colegiado_cecomp": cecomp or anterior.get("colegiado_cecomp", []),
        "itinerario_onibus": itinerario,
        "avisos_siga": avisos_siga,
        "srca_contatos": srca_contatos,
        "srca_atendimento_presencial": srca_atendimento,
        "proae_auxilios": proae_auxilios,
        "contatos_setores": contatos_setores,
    }

    OUTPUT_DIR.mkdir(exist_ok=True)
    OUTPUT_FILE.write_text(json.dumps(dados, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nSalvo em {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
