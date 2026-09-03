# Scraper — UM · UNIVASF Mobile

Coleta dados públicos dos sites oficiais da UNIVASF e gera `output/dados_univasf.json`,
que precisa ser copiado para `assets/data/dados_univasf.json` no projeto Flutter
(o app lê esse arquivo como asset local — ver `lib/data/remote_data_loader.dart`).

## Uso manual

```bash
cd scraper
python -m pip install -r requirements.txt
python run.py
# copiar output/dados_univasf.json para ../assets/data/dados_univasf.json
```

## O que cada fonte coleta

| Fonte | Arquivo | De onde vem |
|---|---|---|
| Notícias (PROAE/PROEX/PROEN) | `sources/setor_noticias.py` | `portais.univasf.edu.br/<setor>/noticias/ultimas-noticias` |
| Cardápio do RU | `sources/ru_cardapio.py` | Busca por tag "Cardápio vigente" + parsing do PDF |
| Calendário acadêmico | `sources/calendario.py` | PDF oficial do calendário (próximos 60 dias) |
| Colegiado CECOMP | `sources/cecomp.py` | `cecomp.univasf.edu.br` (best-effort) |
| Itinerário dos ônibus | `sources/itinerario.py` | **PDF local** em `MATERIAIS/Itinerário PROAE 2026.2.pdf` |

## ⚠️ Limitação conhecida: itinerário dos ônibus

Diferente das outras fontes, o itinerário **não tem uma URL pública estável
identificada ainda** — a PROAE distribui esse PDF diretamente (grupos,
e-mail), sem um link fixo tipo "sempre o mais recente". Por isso
`raspar_itinerario()` lê um arquivo local em `MATERIAIS/`.

**Isso significa que a automação (GitHub Actions) só vai atualizar o
itinerário quando alguém substituir esse PDF manualmente no repositório e
commitar.** Se no futuro a PROAE passar a publicar isso num link fixo (ex.
dentro do site institucional, como já fazem com o cardápio), dá pra trocar
`raspar_itinerario()` para baixar de lá automaticamente, no mesmo padrão de
`ru_cardapio.py`.

## Resiliência a falhas pontuais

`run.py` mantém os dados da rodada anterior quando uma fonte falha ou volta
vazia (ex.: site fora do ar, ou nenhum item marcado como "vigente" no
momento) — nunca sobrescreve um dado bom com um vazio. `scraper/output/` fica
fora do repositório (`.gitignore`) porque é saída intermediária local; o que
é versionado é o **código** do scraper e o `assets/data/dados_univasf.json`
final (esse sim commitado, é o que o app Flutter empacota).

## Automação (GitHub Actions)

Workflow em `.github/workflows/atualizar-dados.yml`, agendado para rodar
1x/dia. Ele instala as dependências, roda `run.py`, copia o resultado para
`assets/data/dados_univasf.json` e commita a mudança de volta no repositório
automaticamente (usando o `GITHUB_TOKEN` padrão do Actions).

**Isso só atualiza o arquivo JSON no repositório — o app Flutter ainda
precisa de um novo build/instalação para embutir a versão mais recente do
asset.** Próximo passo natural (fora do escopo atual): publicar o JSON num
endpoint HTTP estático (ex. GitHub Raw da branch principal) e o app buscar
direto pela rede, eliminando a necessidade de rebuild a cada atualização.
