# ============================================================
# Script: 02_fetch_emendas_pl2338.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Busca todas as emendas do PL 2338/2023 (fase Senado).
# Inputs: data/processed/pl2338_info.rds
# Outputs: data/processed/emendas_pl2338.csv
# ============================================================

library(readr)

source("R/emendas_fetch.R")

info <- readRDS("data/processed/pl2338_info.rds")

emendas <- emendas_para_tibble(info$codigo, cache_dir = "data/raw/emendas_cache")

message(nrow(emendas), " emendas encontradas para ", info$identificacao)
message("NAs em autor_nome: ", sum(is.na(emendas$autor_nome)))
message(
  "Periodo: ", min(emendas$data_apresentacao, na.rm = TRUE), " a ",
  max(emendas$data_apresentacao, na.rm = TRUE)
)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(emendas, "data/processed/emendas_pl2338.csv")
message("Salvo em data/processed/emendas_pl2338.csv")
