# ============================================================
# Script: lab3_similaridade_de_voto_gabarito.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: LABORATORIO 3 (slide 52, 25 min, em duplas) -- gabarito resolvido.
#          Pergunta: quem votou como quem -- e o partido explica?
#
#          TRILHA OBRIGATORIA (como no slide):
#          1. Montar a matriz senador x votacao a partir das nominais ja
#             coletadas (curso_senatebR/aula_04/01_matriz_votacao_nominal.R).
#             AP e MIS sao ausencia; P-NRV e presenca sem voto -- decida a
#             regra e escreva no script (aqui, ausencia -> 0.5, ver nota).
#          2. Calcular a similaridade par a par e declarar o tratamento de
#             ausencias. Linhas da matriz sao codigos, nao nomes.
#          3. Ordenar por agrupamento e desenhar o heatmap
#             (curso_senatebR/aula_04/02_heatmap_similaridade.R ja faz isso).
#          SE SOBRAR TEMPO:
#          - Comparar similaridade media dentro e entre partidos.
#          - Refazer so com votacoes competitivas (margem < 70%).
#          - Encontrar os tres senadores mais atipicos na propria bancada.
# Inputs: curso_senatebR/dados/sim_mat_2023.rds,
#         curso_senatebR/dados/senadores_57.rds,
#         curso_senatebR/dados/votacoes_2019_2023.rds
# Outputs: curso_senatebR/dados/lab3_atipicos.rds
# ============================================================

library(dplyr)
library(tidyr)
library(tibble)

# Passos 1-3 (matriz, similaridade, heatmap) ja estao resolvidos em
# curso_senatebR/aula_04_decisao_e_evidencia/01_matriz_votacao_nominal.R e
# 02_heatmap_similaridade.R -- reaproveitamos o resultado aqui em vez de
# duplicar o codigo (mesmo tratamento de ausencia: NA -> 0.5, documentado
# la como um placeholder, nao uma escolha de pesquisa final).
sim_mat <- readRDS(here::here("curso_senatebR/dados/sim_mat_2023.rds"))

senadores <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds")) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x)) |>
  dplyr::distinct(CodigoParlamentar, .keep_all = TRUE)

sim_long <- sim_mat |>
  tibble::as_tibble(rownames = "codigo_a") |>
  tidyr::pivot_longer(-codigo_a, names_to = "codigo_b", values_to = "similaridade") |>
  dplyr::filter(codigo_a != codigo_b) |>
  dplyr::left_join(senadores |> dplyr::select(CodigoParlamentar, partido_a = SiglaPartidoParlamentar),
    by = c("codigo_a" = "CodigoParlamentar")
  ) |>
  dplyr::left_join(senadores |> dplyr::select(CodigoParlamentar, partido_b = SiglaPartidoParlamentar),
    by = c("codigo_b" = "CodigoParlamentar")
  )

# ------------------------------------------------------------
# SE SOBRAR TEMPO (1) -- similaridade media dentro vs. entre partidos
# ------------------------------------------------------------
comparacao_partido <- sim_long |>
  dplyr::filter(!is.na(partido_a), !is.na(partido_b)) |>
  dplyr::mutate(mesmo_partido = partido_a == partido_b) |>
  dplyr::group_by(mesmo_partido) |>
  dplyr::summarise(similaridade_media = mean(similaridade), n_pares = dplyr::n(), .groups = "drop")

print(comparacao_partido)
message(
  "\nSe a similaridade 'dentro do partido' for bem maior que 'entre partidos', o partido explica ",
  "boa parte do padrao de voto. Se as duas forem parecidas, o partido explica pouco -- e o bloco ",
  "do heatmap (aula 4, script 02) provavelmente segue outra coisa (regiao, comissao, governo x ",
  "oposicao)."
)

# ------------------------------------------------------------
# SE SOBRAR TEMPO (2) -- so votacoes competitivas (margem < 70%)
# ------------------------------------------------------------
votacoes <- readRDS(here::here("curso_senatebR/dados/votacoes_2019_2023.rds")) |>
  dplyr::filter(Ano == "2023", Secreta == "N", Votos.Voto %in% c("Sim", "Não"))

margens <- votacoes |>
  dplyr::count(CodigoSessaoVotacao, Votos.Voto) |>
  tidyr::pivot_wider(names_from = Votos.Voto, values_from = n, values_fill = 0) |>
  dplyr::rename(sim = "Sim", nao = "Não") |>
  dplyr::mutate(margem = pmax(sim, nao) / (sim + nao))

votacoes_competitivas <- margens |> dplyr::filter(margem < 0.70) |> dplyr::pull(CodigoSessaoVotacao)
message(
  "\n", length(votacoes_competitivas), " de ", nrow(margens),
  " votacoes nominais de 2023 sao competitivas (margem < 70%)."
)

if (length(votacoes_competitivas) >= 5) {
  mat_competitiva <- votacoes |>
    dplyr::filter(CodigoSessaoVotacao %in% votacoes_competitivas) |>
    dplyr::mutate(v = dplyr::if_else(Votos.Voto == "Sim", 1, 0)) |>
    dplyr::select(Votos.CodigoParlamentar, CodigoSessaoVotacao, v) |>
    tidyr::pivot_wider(names_from = CodigoSessaoVotacao, values_from = v, values_fn = dplyr::first) |>
    tibble::column_to_rownames("Votos.CodigoParlamentar") |>
    as.matrix()
  mat_competitiva[is.na(mat_competitiva)] <- 0.5
  sim_mat_competitiva <- 1 - as.matrix(stats::dist(mat_competitiva, method = "manhattan")) / ncol(mat_competitiva)
  message("Matriz de similaridade so com votacoes competitivas: ", nrow(sim_mat_competitiva),
          " senadores x ", length(votacoes_competitivas), " votacoes.")
} else {
  message("Poucas votacoes competitivas na amostra para recalcular a matriz com robustez.")
}

# ------------------------------------------------------------
# SE SOBRAR TEMPO (3) -- os tres senadores mais atipicos na propria bancada
# ------------------------------------------------------------
atipicos <- sim_long |>
  dplyr::filter(!is.na(partido_a), partido_a == partido_b) |>
  dplyr::group_by(codigo_a) |>
  dplyr::summarise(similaridade_media_bancada = mean(similaridade), .groups = "drop") |>
  dplyr::left_join(senadores, by = c("codigo_a" = "CodigoParlamentar")) |>
  dplyr::arrange(similaridade_media_bancada) |>
  dplyr::select(NomeParlamentar, SiglaPartidoParlamentar, similaridade_media_bancada)

dir.create(here::here("curso_senatebR/dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(atipicos, here::here("curso_senatebR/dados/lab3_atipicos.rds"))

message("\nOs 3 senadores mais atipicos dentro da propria bancada (nominais de 2023):")
print(utils::head(atipicos, 3))

# CHECKPOINT (10 min): "Os dados de votacao nominal de 2023 sugerem que a
# bancada explica [muito/pouco] do padrao de voto -- a similaridade media
# dentro do partido foi de [X], contra [Y] entre partidos diferentes."
