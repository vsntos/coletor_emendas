# ============================================================
# Script: 01_matriz_votacao_nominal.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 4, "da tabela longa a matriz" (slide 47) -- quem vota como
#          quem? A decisao critica e a ausencia: AP e MIS sao ausencia;
#          P-NRV e presenca sem voto. Tratar NA como discordancia inventa
#          oposicao que nao existe. Junte pelo codigo, nunca pelo nome --
#          por isso as linhas da matriz sao CodigoParlamentar, e o nome
#          entra so no rotulo do grafico (proximo script).
# Inputs: curso_senatebR/dados/votacoes_2019_2023.rds
#         (de 01_coleta_responsavel.R, aula 2)
# Outputs: curso_senatebR/dados/sim_mat_2023.rds
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(dplyr)))
suppressWarnings(suppressPackageStartupMessages(library(tidyr)))
suppressWarnings(suppressPackageStartupMessages(library(tibble)))

votacoes <- readRDS(here::here("curso_senatebR/dados/votacoes_2019_2023.rds")) |>
  dplyr::filter(Ano == "2023")

# 1. codificar o voto numericamente
mat <- votacoes |>
  dplyr::filter(Secreta == "N", Votos.Voto %in% c("Sim", "Não")) |>
  dplyr::mutate(v = dplyr::if_else(Votos.Voto == "Sim", 1, 0)) |>
  # 2. senador nas linhas, votacao nas colunas
  dplyr::select(Votos.CodigoParlamentar, CodigoSessaoVotacao, v) |>
  tidyr::pivot_wider(names_from = CodigoSessaoVotacao, values_from = v, values_fn = dplyr::first) |>
  tibble::column_to_rownames("Votos.CodigoParlamentar") |>
  as.matrix()

message("Matriz bruta: ", nrow(mat), " senadores x ", ncol(mat), " votacoes nominais de 2023.")
message("Proporcao de celulas ausentes (NA): ", round(mean(is.na(mat)), 3),
        " -- um senador so tem voto registrado nas sessoes em que participou.")

# NOTA METODOLOGICA (esta e a decisao critica do slide 47, aprofundada no
# Lab 3): ausencia (NA apos o pivot) NAO e discordancia. Para esta
# demonstracao -- so para viabilizar o calculo de distancia -- preenchemos
# NA com 0.5 (um ponto neutro entre sim e nao). Isso NAO e uma escolha de
# pesquisa defensavel por si so; e um placeholder documentado. O Lab 3
# pede explicitamente que voce declare e justifique o SEU tratamento de
# ausencia (AP/MIS vs. P-NRV) antes de calcular similaridade.
mat_preenchida <- mat
mat_preenchida[is.na(mat_preenchida)] <- 0.5

# 3. concordancia par a par
dist_mat <- as.matrix(stats::dist(mat_preenchida, method = "manhattan"))
sim_mat <- 1 - dist_mat / ncol(mat_preenchida)

dir.create(here::here("curso_senatebR/dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(sim_mat, here::here("curso_senatebR/dados/sim_mat_2023.rds"))
message("Matriz de similaridade (", nrow(sim_mat), " x ", ncol(sim_mat), ") salva em ",
        here::here("curso_senatebR/dados/sim_mat_2023.rds"))

# values_fn = first resolve o caso de um mesmo senador aparecer duas vezes
# na mesma votacao. Se isso acontece, investigue antes de silenciar.
