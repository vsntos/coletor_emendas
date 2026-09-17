# ============================================================
# Script: 03_hipotese_ano_eleitoral.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 3, hipotese testavel (slide 40) -- o calendario eleitoral
#          organiza a producao legislativa? Hipotese institucional: em ano
#          eleitoral, parlamentares apresentam mais projetos porque
#          apresentacao e sinalizacao barata para o eleitor. Estudo de
#          caso 3 do livro-tutorial.
# Inputs: curso_senatebR/dados/materias_legislatura_atual.rds
#         (de 02_materias_e_tramitacao.R)
# Outputs: curso_senatebR/figuras/materias-ano-eleitoral.png
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(lubridate)))
suppressWarnings(suppressPackageStartupMessages(library(dplyr)))
suppressWarnings(suppressPackageStartupMessages(library(ggplot2)))

materias <- readRDS(here::here("curso_senatebR/dados/materias_legislatura_atual.rds"))

por_ano <- materias |>
  dplyr::filter(!is.na(AnoMateria)) |>
  dplyr::mutate(
    Ano = as.integer(AnoMateria),
    # municipais: multiplos de 4 · gerais: multiplos de 4 + 2
    ano_eleitoral = (Ano %% 4 == 2) | (Ano %% 4 == 0)
  ) |>
  dplyr::count(Ano, ano_eleitoral)

grafico <- por_ano |>
  ggplot2::ggplot(ggplot2::aes(x = Ano, y = n, fill = ano_eleitoral)) +
  ggplot2::geom_col() +
  ggplot2::scale_fill_manual(
    values = c("FALSE" = "#5ba4cf", "TRUE" = "#e76f51"),
    labels = c("Não eleitoral", "Eleitoral")
  ) +
  ggplot2::labs(
    title = "Matérias apresentadas por ano",
    subtitle = "Anos eleitorais em destaque",
    x = NULL, y = "Quantidade", fill = NULL
  ) +
  ggplot2::theme_minimal()

dir.create(here::here("curso_senatebR/figuras"), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(here::here("curso_senatebR/figuras/materias-ano-eleitoral.png"), grafico, width = 9, height = 5, dpi = 300)

print(por_ano |> dplyr::arrange(dplyr::desc(Ano)) |> utils::head(10))

# O erro classico: a legislatura atual esta incompleta -- o ultimo ano da
# serie sempre parece uma queda, e nao e. (Esta base tambem so cobre
# materias que AINDA tramitam -- ver nota em 02_materias_e_tramitacao.R --
# entao anos antigos aqui tendem a estar sub-representados: materias
# velhas em geral ja saem da lista de "tramitando".)
#
# Este grafico nao prova a hipotese. Ele torna a hipotese discutivel --
# que e tudo o que um grafico deveria fazer.
