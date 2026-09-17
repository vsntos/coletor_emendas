# coletor_emendas

Ferramentas para coletar e analisar emendas de projetos de lei do Senado Federal via a API de
Dados Abertos (`legis.senado.leg.br/dadosabertos`).

## Conteúdo

- **`coletor_emendas.R`** — app Shiny original: coleta emendas de um ou mais projetos e extrai
  ementa/justificativa do texto em PDF de cada emenda. Uso interativo, para inspeção detalhada.
- **`app_validacao_dados/`** — validador genérico de dados (CSV/XLSX/JSON), não específico de
  emendas.
- **`R/` + `scripts/`** — pipeline de ranking por número de emendas (nova, 2026-09-17), sem
  processar o texto de cada emenda — só metadados (autor, partido, UF, data), voltada para medir
  volume de emendamento como proxy de interesse parlamentar por uma matéria.
- **`curso_senatebR/`** — material da oficina do pacote `senatebR` (4 aulas + 3 laboratórios),
  organizado em scripts que rodam contra a API real. Ver [`curso_senatebR/README.md`](curso_senatebR/README.md).
- **`exemplos_aplicados/`** — ponte entre a oficina e o pipeline de emendas acima: explica por que
  emendas não é uma das 36 funções do `senatebR` e como o mesmo método se aplica mesmo assim. Ver
  [`exemplos_aplicados/ranking_de_emendas.md`](exemplos_aplicados/ranking_de_emendas.md).

## Pipeline de ranking (scripts/01 a 05)

Caso de uso: PL 2338/2023 (Marco Legal da Inteligência Artificial).

| Script | O que faz |
|---|---|
| `01_lookup_pl2338.R` | Resolve a identificação pública (PL 2338/2023) para o `Codigo` interno do Senado |
| `02_fetch_emendas_pl2338.R` | Busca todas as emendas da matéria (autor, partido, UF, data) |
| `03_ranking_autores_pl2338.R` | Ranking de parlamentares por número de emendas propostas a essa matéria |
| `04_cohort_comparativo.R` | Busca um grupo de comparação (PLs de 2023 que chegaram ao mesmo marco processual) e conta as emendas de cada um |
| `05_ranking_comparativo.R` | Calcula a posição/percentil da matéria dentro do grupo de comparação |

Rodar em ordem, a partir da raiz do projeto (`Rscript scripts/01_lookup_pl2338.R`, depois `02`,
etc.). Os scripts `02` e `04` cacheiam as respostas brutas da API em `data/raw/emendas_cache/`
(um JSON por matéria) — reexecuções não refazem chamadas já feitas.

### Resultado (2026-09-17)

- PL 2338/2023 recebeu **244 emendas** na fase Senado.
- Top autor: **Mecias de Jesus (Republicanos-RR)**, com 41 emendas.
- Comparado a 110 PLs de 2023 que também chegaram a "aprovado em Plenário", o PL 2338 ficou em
  **1º lugar** (percentil 100) — a mediana do grupo foi de apenas 1 emenda por projeto. É um
  outlier claro em volume de emendamento.

## Ressalvas importantes

- **Escopo: só fase Senado.** O PL 2338 já foi remetido à Câmara dos Deputados (dezembro de 2024)
  e não tramita mais no Senado. As emendas apresentadas na Câmara vêm de uma API diferente
  (`dadosabertos.camara.leg.br`) e **não estão incluídas** neste ranking. O número/ranking
  reflete apenas a atividade de emendamento durante a passagem pelo Senado.
- **API legada com aviso de descontinuação.** O endpoint `materia/emendas/{codigo}` usado aqui
  (e em `coletor_emendas.R`) tem um aviso próprio de depreciação (`DataDesativacaoCompleta:
  2026-02-01`, já passada) apontando para o substituto `dadosabertos/processo`. Ainda retorna
  dados reais (testado em 2026-09-17), mas pode parar de funcionar — se isso acontecer, será
  preciso migrar a lógica de `R/emendas_fetch.R` para o novo endpoint.
- **Escolha metodológica do grupo de comparação.** "Interesse parlamentar" aqui é operacionalizado
  como número de emendas entre pares que atingiram o mesmo marco processual (aprovação em
  Plenário) no mesmo ano — uma escolha defensável, não a única possível. Refinamentos por
  comissão/tema (em vez de todo o universo de PLs aprovados em Plenário em 2023) ficam para uma
  iteração futura, se fizer sentido para o uso editorial pretendido.
