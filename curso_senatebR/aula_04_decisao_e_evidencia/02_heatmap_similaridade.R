# ============================================================
# Script: 02_heatmap_similaridade.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 4, "a matriz como imagem" (slide 48) -- o momento visual
#          mais forte da oficina. Ordenada por agrupamento hierarquico, a
#          matriz revela blocos -- e os blocos nao coincidem perfeitamente
#          com os partidos. Onde os blocos nao seguem a legenda partidaria
#          esta a proxima pesquisa.
# Inputs: curso_senatebR/dados/sim_mat_2023.rds
#         (de 01_matriz_votacao_nominal.R)
# Outputs: curso_senatebR/figuras/heatmap-similaridade-2023.png
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(dplyr)))
suppressWarnings(suppressPackageStartupMessages(library(tidyr)))
suppressWarnings(suppressPackageStartupMessages(library(ggplot2)))

sim_mat <- readRDS(here::here("curso_senatebR/dados/sim_mat_2023.rds"))

ord <- stats::hclust(stats::as.dist(1 - sim_mat))$order
ordem_codigos <- rownames(sim_mat)[ord]

grafico <- sim_mat |>
  tibble::as_tibble(rownames = "a") |>
  tidyr::pivot_longer(-a, names_to = "b", values_to = "value") |>
  dplyr::mutate(
    a = factor(a, levels = ordem_codigos),
    b = factor(b, levels = ordem_codigos)
  ) |>
  ggplot2::ggplot(ggplot2::aes(a, b, fill = value)) +
  ggplot2::geom_tile() +
  ggplot2::scale_fill_viridis_c(name = "Similaridade") +
  ggplot2::labs(
    title = "Quem vota como quem -- nominais de 2023",
    subtitle = "Ordenado por agrupamento hierárquico (linhas/colunas = CodigoParlamentar)",
    x = NULL, y = NULL
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank()
  )

dir.create(here::here("curso_senatebR/figuras"), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(here::here("curso_senatebR/figuras/heatmap-similaridade-2023.png"), grafico, width = 8, height = 7, dpi = 300)
message("Heatmap salvo em curso_senatebR/figuras/heatmap-similaridade-2023.png")
