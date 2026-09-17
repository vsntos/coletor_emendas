# Plan: Organizar curso senatebR (Oficina) neste projeto
**Date:** 2026-09-17
**Status:** COMPLETED

## Context

O usuário forneceu `~/Downloads/senatebR.pptx`, o material de uma oficina de 4 aulas + 3
laboratórios sobre o pacote R `senatebR` (extração de dados abertos do Senado Federal). O pedido:
(1) organizar todos os trechos de código que aparecem nos slides para rodarem de verdade neste
projeto (`coletor_emendas`), (2) organizar os 3 exercícios de laboratório, e (3) incluir o
exercício de ranking de emendas (PL 2338/2023) já construído neste projeto como um dos exemplos
do curso.

O conteúdo foi extraído do pptx (62 slides, via `markitdown`) e mapeado integralmente. Pacote
`senatebR` e todas as dependências do curso (`tidyverse`, `igraph`, `ggraph`, `geobr`, `gt`, etc.)
já estão instalados no ambiente — os scripts serão escritos para rodar de verdade, não como
pseudocódigo.

Decisões já tomadas com o usuário:
- **Labs com gabarito resolvido** (não apenas esqueleto com TODOs) — cada lab vira um script
  funcional que resolve a "trilha obrigatória" descrita no slide.
- **Exemplo de emendas por referência, sem duplicar** — a pasta do curso aponta para
  `R/emendas_fetch.R`, `R/materia_lookup.R`, `R/ranking_autores.R`, `R/comparacao_materias.R` e
  `scripts/01..05_*.R` já existentes na raiz do projeto, em vez de copiar esse código para dentro
  da pasta do curso (single source of truth).

O caso que atravessa a oficina (slide 9) é o **PL 2.630/2020** (regulação de plataformas
digitais, aprovado no Senado em 2020). Esse é o caso usado nos labs 1–3 e nos scripts de
demonstração das aulas 2–4. Como o `senatebR` não tem uma função de busca de matéria por
sigla/número/ano (só recebe `codigo` já resolvido), o script de abertura do curso reaproveita
`R/materia_lookup.R::buscar_codigo_materia()` — já existente neste projeto — para resolver
"PL 2630/2020" → `Codigo`. Isso também reforça organicamente o exemplo de emendas: a mesma lacuna
que motivou aquele pipeline aparece aqui.

## Estrutura de arquivos

```
curso_senatebR/
├── README.md                                   # mapa do curso, como rodar, citação, ressalvas
├── 00_setup.R                                   # slide 21: instalação + teste de fumaça
├── 01_caso_da_oficina.R                         # slide 9: resolve PL 2630/2020 -> Codigo (via
│                                                 #   R/materia_lookup.R), salva em dados/caso.rds
├── aula_01_pergunta_antes_da_ferramenta/
│   └── demo_jogo_completo.R                     # slides 13, 15-19: sem/com pacote, coleta,
│                                                 #   Índice de Rice, gráfico, interpretação (2023,
│                                                 #   caso genérico do slide, não o PL 2630)
├── aula_02_atores_e_arenas/
│   ├── 01_coleta_responsavel.R                  # slide 24: padrão coleta/análise separados,
│                                                 #   cache em disco, Sys.sleep + tryCatch
│   ├── 02_armadilha_nomes_de_coluna.R           # slide 25: rename_with, 3 grafias do mesmo código
│   ├── 03_quem_compoe_o_senado.R                # slides 27-28: select/count/group_by/summarise
│   ├── 04_arenas_comissoes.R                    # slide 29: dados_comissoes, sobrerrepresentação
│   └── lab1_composicao_e_poder_gabarito.R       # slide 32, resolvido para o caso PL 2630/2020
├── aula_03_processo_legislativo/
│   ├── 01_chaves_e_joins.R                      # slide 36: count(chave)>1, anti_join, stopifnot
│   ├── 02_materias_e_tramitacao.R               # slide 39: materias_legislatura_atual, situações
│   ├── 03_hipotese_ano_eleitoral.R              # slide 40: gráfico ano eleitoral x apresentação
│   ├── 04_discursos.R                           # slide 41: pronunciamentos, Codigo_Parlamentar
│   ├── 05_agenda_vetos_mps.R                    # slide 42: info_agenda, vetos, MPs
│   └── lab2_tramitacao_do_caso_gabarito.R       # slide 43, resolvido para o PL 2630/2020
├── aula_04_decisao_e_evidencia/
│   ├── 01_matriz_votacao_nominal.R              # slide 47: pivot_wider, matriz, dist manhattan
│   ├── 02_heatmap_similaridade.R                # slide 48: hclust + geom_tile
│   ├── 03_coesao_vs_disciplina.R                # slide 49: coletar_orientacao_votacao, disciplina
│   ├── 04_indice_de_atividade.R                 # slide 50: presença+discursos+comissões, z-score
│   ├── 05_rede_de_coautoria.R                   # slide 51: igraph/ggraph, coautorias
│   ├── 06_comunicacao_visual.R                  # slides 53-54: ggplot2 (fct_reorder), geobr, gt
│   ├── relatorio_exemplo.qmd                    # slide 55: 1 .qmd -> html/pdf/revealjs
│   └── lab3_similaridade_de_voto_gabarito.R     # slide 52, resolvido para o PL 2630/2020
├── dados/            # .rds/.csv gerados pelos scripts do curso (git-ignorado, como data/ já é)
└── figuras/          # .png gerados pelos scripts do curso (git-ignorado)

exemplos_aplicados/
└── ranking_de_emendas.md   # ponte para R/ + scripts/01-05 já existentes na raiz: explica por que
                             # emendas não é uma das 36 funções do senatebR (endpoint legado,
                             # cobertura fora da "gramática comum"), mapeia o pipeline existente
                             # no framework do curso (API -> JSON -> tabela -> indicador ->
                             # evidência) e reaproveita o resultado já obtido (ranking de autores +
                             # ranking comparativo do PL 2338/2023) como o "estudo de caso extra"
                             # da oficina.
```

Cada script de aula/lab abre com o mesmo cabeçalho padrão já usado em `scripts/*.R` deste projeto
(`# Script / Author / Date / Purpose / Inputs / Outputs`), cita o número do slide de origem, e
carrega `senatebR` + `tidyverse` no topo. `00_setup.R` e `01_caso_da_oficina.R` rodam uma vez;
os demais assumem que os dados de `01_caso_da_oficina.R` já existem em `curso_senatebR/dados/`.

Correções feitas ao transcrever os slides (a extração via `markitdown` introduziu erros de OCR):
`sc-camel-show-warnings` → `showWarnings`; `"{.col _z"` → `"{.col}_z"`; quebras de linha que
partiram chamadas de função no meio serão reunidas em uma expressão válida. Nenhuma lógica do
curso muda — só a sintaxe é corrigida para o código rodar.

## Verificação

- `Rscript curso_senatebR/00_setup.R` e `01_caso_da_oficina.R` rodam contra a API real do Senado
  (sem mocks) e confirmam que o PL 2630/2020 é resolvido corretamente.
- Rodar ao menos um script por aula contra a API real (priorizando os mais leves: coleta de
  senadores, comissões, matérias) para confirmar que a sintaxe corrigida funciona de ponta a
  ponta e gera os `.rds`/`.png` esperados em `dados/`/`figuras/`.
- Para os blocos mais pesados em requisições (aula 4: `coletar_orientacao_votacao` em loop,
  `coletar_autorias_parlamentares` para redes) — rodar com uma amostra pequena (poucas datas /
  poucos códigos) para confirmar que o código funciona, documentando no próprio script que a
  versão de sala de aula usa o universo completo e leva mais tempo.
- `Rscript scripts/03_ranking_autores_pl2338.R` (já existente) continua funcionando sem alteração
  — a nova pasta `exemplos_aplicados/` não toca nesses arquivos, só os referencia.
- Conferir que `curso_senatebR/dados/` e `curso_senatebR/figuras/` entram no `.gitignore` (mesmo
  padrão que outros artefatos gerados neste projeto).
- Session log em `quality_reports/session_logs/2026-09-17_curso-senatebR.md` registrando decisões
  (uso do PL 2630/2020, gabarito resolvido, referência sem duplicação).
