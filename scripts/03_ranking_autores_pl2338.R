# ============================================================
# Script: 03_ranking_autores_pl2338.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Ranking de parlamentares por numero de emendas propostas ao
#          PL 2338/2023.
# Inputs: data/processed/emendas_pl2338.csv
# Outputs: data/processed/ranking_autores_pl2338.csv
# ============================================================

library(readr)

source("R/ranking_autores.R")

emendas <- readr::read_csv("data/processed/emendas_pl2338.csv", show_col_types = FALSE)

ranking <- ranquear_autores(emendas)

message("Top 10 parlamentares por numero de emendas ao PL 2338/2023:")
print(head(ranking, 10))

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(ranking, "data/processed/ranking_autores_pl2338.csv")
message("Salvo em data/processed/ranking_autores_pl2338.csv")
