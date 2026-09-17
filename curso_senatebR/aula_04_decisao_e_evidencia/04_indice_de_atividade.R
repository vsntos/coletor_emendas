# ============================================================
# Script: 04_indice_de_atividade.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 4, "cruzando tres fontes" (slide 50) -- estudo de caso 1
#          do livro. Presenca em votacoes + volume de discursos + numero
#          de comissoes, cada um em sua propria escala, combinados via
#          z-score num indice de atividade. Tres chaves diferentes num
#          unico pipeline: CodigoParlamentar, codigo_senador,
#          Codigo_Parlamentar -- e por isso a aula 2 inteira foi sobre
#          nomes de coluna.
#
#          Demo com uma amostra de 15 senadores (mesma amostra de
#          04_discursos.R, aula 3) -- em sala, escale para todos os 245
#          codigos fora do horario de pico.
# Inputs: curso_senatebR/dados/senadores_57.rds,
#         curso_senatebR/dados/membros_comissoes_57.rds
#         (de 01_coleta_responsavel.R e 04_arenas_comissoes.R, aula 2)
# Outputs: curso_senatebR/dados/indice_atividade.rds
# ============================================================

library(senatebR)
library(dplyr)

senadores <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds")) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))
membros <- readRDS(here::here("curso_senatebR/dados/membros_comissoes_57.rds"))

codigos_amostra <- unique(stats::na.omit(senadores$CodigoParlamentar))[1:15]

# presenca em votacoes
presenca <- coletar_votacoes_multiplos(codigos_senadores = codigos_amostra, anos = 2023) |>
  dplyr::mutate(presente = !votacoes_SiglaDescricaoVoto %in% c("AP", "MIS")) |>
  dplyr::group_by(codigo_senador) |>
  dplyr::summarise(taxa_presenca = mean(presente, na.rm = TRUE), .groups = "drop")

# volume de discursos e n. de comissoes
pronunciamentos <- extrair_pronunciamentos_multi(codigos_parlamentares = codigos_amostra, anos = 2023)
n_discursos <- pronunciamentos |> dplyr::count(Codigo_Parlamentar, name = "n_discursos")
n_comissoes <- membros |>
  dplyr::filter(!is.na(IdentificacaoComissao.CodigoComissao), CodigoParlamentar %in% codigos_amostra) |>
  dplyr::count(CodigoParlamentar, name = "n_comissoes")

# z-score de cada dimensao e soma
# as.vector() em torno de scale() nao e detalhe: scale() devolve matriz, e
# a matriz quebra o mutate() silenciosamente.
indice <- senadores |>
  dplyr::filter(CodigoParlamentar %in% codigos_amostra) |>
  dplyr::left_join(presenca, by = c("CodigoParlamentar" = "codigo_senador")) |>
  dplyr::left_join(n_discursos, by = c("CodigoParlamentar" = "Codigo_Parlamentar")) |>
  dplyr::left_join(n_comissoes, by = "CodigoParlamentar") |>
  dplyr::mutate(dplyr::across(c(taxa_presenca, n_discursos, n_comissoes),
    ~ as.vector(scale(tidyr::replace_na(.x, 0))), .names = "{.col}_z"
  )) |>
  dplyr::mutate(indice = taxa_presenca_z + n_discursos_z + n_comissoes_z) |>
  dplyr::arrange(dplyr::desc(indice))

dir.create(here::here("curso_senatebR/dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(indice, here::here("curso_senatebR/dados/indice_atividade.rds"))

print(indice |> dplyr::select(NomeParlamentar, taxa_presenca, n_discursos, n_comissoes, indice))

# Critique o indice. Somar tres z-scores assume que as dimensoes pesam
# igual e que "atividade" e uma coisa so. Nenhuma das duas premissas e
# obvia -- diga isso antes que o revisor diga.
