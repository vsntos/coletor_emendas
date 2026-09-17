# ============================================================
# Script: 04_cohort_comparativo.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Busca o grupo de comparacao (PLs de 2023 que atingiram
#          APROVADA_NO_PLENARIO, o mesmo marco do PL 2338) e conta as
#          emendas de cada um. ~110 chamadas de API, com pacing e cache em
#          disco -- pode levar alguns minutos.
# Inputs: data/processed/pl2338_info.rds
# Outputs: data/processed/cohort_2023_aprovados_plenario.csv
# ============================================================

library(readr)
library(dplyr)

source("R/comparacao_materias.R")
source("R/emendas_fetch.R")

info <- readRDS("data/processed/pl2338_info.rds")

message("Buscando cohort de PLs de 2023 aprovados em Plenario...")
cohort <- buscar_cohort_deliberacao(2023, "PL", "APROVADA_NO_PLENARIO")
message("  ", nrow(cohort), " materias no cohort (esperado: ~110)")

if (!(info$codigo %in% cohort$codigo_materia)) {
  stop("PL 2338 (codigo ", info$codigo, ") nao esta no cohort -- verifique o criterio de filtro.")
}

message("Contando emendas de cada materia do cohort (pacing 0.5s/chamada, pode levar alguns minutos)...")
contagens <- contar_emendas_cohort(cohort$codigo_materia, cache_dir = "data/raw/emendas_cache")

cohort_completo <- cohort %>%
  dplyr::left_join(contagens, by = "codigo_materia")

message("  Contagem concluida. Resumo:")
print(summary(cohort_completo$n_emendas))

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(cohort_completo, "data/processed/cohort_2023_aprovados_plenario.csv")
message("Salvo em data/processed/cohort_2023_aprovados_plenario.csv")
