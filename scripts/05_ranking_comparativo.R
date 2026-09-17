# ============================================================
# Script: 05_ranking_comparativo.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Calcula a posicao/percentil do PL 2338/2023 dentro do cohort de
#          PLs de 2023 aprovados em Plenario, por numero de emendas -- a
#          medida final de "interesse parlamentar" comparativo.
# Inputs: data/processed/pl2338_info.rds, data/processed/cohort_2023_aprovados_plenario.csv
# Outputs: data/processed/ranking_comparativo_pl2338.csv
# ============================================================

library(readr)
library(dplyr)

source("R/comparacao_materias.R")

info <- readRDS("data/processed/pl2338_info.rds")
cohort <- readr::read_csv("data/processed/cohort_2023_aprovados_plenario.csv", show_col_types = FALSE)

resultado <- posicao_no_cohort(cohort, info$codigo)

if (is.null(resultado)) stop("Nao foi possivel calcular a posicao do PL 2338 no cohort.")

message(
  "PL 2338/2023 recebeu ", resultado$n_emendas_alvo, " emendas, ficando em ",
  resultado$posicao, "º lugar entre ", resultado$n_total,
  " PLs de 2023 aprovados em Plenario (percentil ", resultado$percentil, ")."
)
message(
  "IMPORTANTE: esta comparacao cobre apenas a fase Senado (o PL 2338 ja foi remetido a Camara ",
  "dos Deputados em dez/2024 e nao inclui emendas apresentadas la)."
)

ranking_completo <- cohort %>%
  dplyr::arrange(dplyr::desc(n_emendas)) %>%
  dplyr::mutate(posicao = dplyr::row_number(), eh_pl2338 = codigo_materia == info$codigo)

message("\nTop 10 do cohort por numero de emendas:")
print(head(ranking_completo %>% dplyr::select(posicao, identificacao, n_emendas, eh_pl2338), 10))

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(ranking_completo, "data/processed/ranking_comparativo_pl2338.csv")
message("\nSalvo em data/processed/ranking_comparativo_pl2338.csv")
