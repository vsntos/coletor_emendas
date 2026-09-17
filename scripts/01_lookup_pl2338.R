# ============================================================
# Script: 01_lookup_pl2338.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Resolve PL 2338/2023 para o Codigo interno do Senado.
# Inputs: none
# Outputs: data/processed/pl2338_info.rds
# ============================================================

source("R/materia_lookup.R")

info <- buscar_codigo_materia("PL", 2338, 2023)

if (is.null(info)) stop("Nao foi possivel localizar o PL 2338/2023.")

message("Materia encontrada: ", info$identificacao, " (Codigo ", info$codigo, ")")
message("Ementa: ", info$ementa)
message("Autor: ", info$autor)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(info, "data/processed/pl2338_info.rds")
message("Salvo em data/processed/pl2338_info.rds")
