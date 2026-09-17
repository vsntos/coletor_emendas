# ============================================================
# Script: ranking_autores.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Ranqueia parlamentares por numero de emendas propostas a uma
#          materia especifica.
# Inputs: uma tibble no formato de emendas_para_tibble() (emendas_fetch.R)
# Outputs: none (define funcoes)
# ============================================================

library(dplyr)

#' Ranking de autores por numero de emendas propostas.
ranquear_autores <- function(emendas_df) {
  if (nrow(emendas_df) == 0) return(tibble::tibble())

  emendas_df %>%
    dplyr::filter(!is.na(autor_nome)) %>%
    dplyr::count(autor_nome, autor_partido, autor_uf, name = "n_emendas", sort = TRUE) %>%
    dplyr::mutate(posicao = dplyr::row_number())
}
