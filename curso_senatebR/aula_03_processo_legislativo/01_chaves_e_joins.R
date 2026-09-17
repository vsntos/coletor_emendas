# ============================================================
# Script: 01_chaves_e_joins.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 3, "a cola da analise" (slide 36) -- nunca junte por nome.
#          "Joao Silva" e "Joao da Silva" sao a mesma pessoa; "4981" e
#          sempre "4981". Toda analise legislativa seria e uma sequencia
#          de joins bem-feitos -- e aqui nascem os erros publicados.
# Inputs: curso_senatebR/dados/senadores_57.rds,
#         curso_senatebR/dados/votacoes_2019_2023.rds
#         (de 01_coleta_responsavel.R, aula 2)
# Outputs: none (script de demonstracao)
# ============================================================

library(dplyr)

senadores <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds")) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))
votacoes <- readRDS(here::here("curso_senatebR/dados/votacoes_2019_2023.rds"))

# 1. a chave e unica? (faca isso SEMPRE antes do join)
chave_duplicada <- senadores |>
  dplyr::count(CodigoParlamentar) |>
  dplyr::filter(n > 1)

message(nrow(chave_duplicada), " codigos duplicados em senadores (esperado: 0)")

# 2. o que sobra de cada lado?
so_em_votacoes <- votacoes |>
  dplyr::anti_join(senadores, by = c("Votos.CodigoParlamentar" = "CodigoParlamentar")) |>
  dplyr::distinct(Votos.CodigoParlamentar)

message(nrow(so_em_votacoes), " codigos de parlamentar aparecem em votacoes mas nao em ",
        "senadores_57 -- suplentes, afastados, legislaturas anteriores (2019-2023 cobre ",
        "duas legislaturas, a 56a e a 57a).")

# 3. junte, e confira o tamanho
base <- votacoes |>
  dplyr::left_join(senadores, by = c("Votos.CodigoParlamentar" = "CodigoParlamentar"))

stopifnot(nrow(base) == nrow(votacoes))
message("Join concluido: ", nrow(base), " linhas (== nrow(votacoes), como esperado).")

# O anti_join e a ferramenta mais subutilizada do R. Ele mostra o que voce
# esta perdendo em silencio -- e no caso do Senado, o que sobra quase
# sempre tem explicacao institucional.
