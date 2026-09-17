# ============================================================
# Script: 04_arenas_comissoes.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 2, arenas (slide 29) -- olhar so para o plenario nao e
#          suficiente. O Senado e uma arquitetura de atores, arenas e
#          procedimentos: senador -> comissao -> reuniao -> materia ->
#          decisao. O join e o momento em que duas tabelas se tornam uma
#          estrutura institucional.
# Inputs: curso_senatebR/dados/senadores_57.rds (de 01_coleta_responsavel.R)
# Outputs: curso_senatebR/dados/membros_comissoes_57.rds
# ============================================================

library(senatebR)
library(dplyr)

senadores <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds")) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))

# o catalogo de comissoes
# NOTA (verificado ao vivo em 2026-09-17): este endpoint retornou 0 linhas
# no momento em que este script foi escrito -- ilustra ao vivo o ponto do
# slide 26 ("o que a API nao entrega"). Nao trate isso como bug do script:
# confirme com names(comissoes) e nrow(comissoes) antes de assumir dado
# disponivel, e registre a limitacao no seu texto se persistir.
comissoes <- dados_comissoes()

# onde cada ator atua: aceita um vetor de codigos
codigos <- unique(stats::na.omit(senadores$CodigoParlamentar))
membros <- obter_dados_comissoes_parlamentares(codigos)

dir.create(here::here("curso_senatebR/dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(membros, here::here("curso_senatebR/dados/membros_comissoes_57.rds"))

# quantas comissoes por senador?
ranking_comissoes <- membros |>
  dplyr::filter(!is.na(IdentificacaoComissao.CodigoComissao)) |>
  dplyr::count(CodigoParlamentar, name = "n_comissoes") |>
  dplyr::left_join(senadores, by = "CodigoParlamentar") |>
  dplyr::arrange(dplyr::desc(n_comissoes)) |>
  dplyr::select(NomeParlamentar, SiglaPartidoParlamentar, n_comissoes)

print(utils::head(ranking_comissoes, 10))

# e o que se diz la dentro (aula 2 so aponta a funcao -- aprofundado na
# aula 3 com discursos e notas taquigraficas):
#   notas <- extrair_notas_taquigraficas(codigo_reuniao)
#
# Comissao nao e so composicao: e registro de deliberacao.

message(nrow(comissoes), " comissoes no catalogo; ", nrow(membros), " vinculos senador-comissao.")
