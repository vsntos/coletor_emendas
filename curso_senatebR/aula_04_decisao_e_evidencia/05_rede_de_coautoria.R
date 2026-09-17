# ============================================================
# Script: 05_rede_de_coautoria.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 4, "a ultima virada" (slide 51) -- a rede mostra o que
#          nenhuma tabela mostra: que a cooperacao legislativa tem
#          geografia propria, e ela nao e o mapa dos partidos.
#
#          ACHADO (verificado ao vivo em 2026-09-17): coletar_autorias_
#          parlamentares() NAO retorna pares de coautoria por materia,
#          apesar do nome e de como o slide 27/51 a descreve ("quem
#          apresenta materia com quem"). A documentacao do proprio pacote
#          (?coletar_autorias_parlamentares) diz que ela devolve "Quantidade
#          de materias atribuidas ao parlamentar NA COMISSAO" -- um dado de
#          comissao, nao de autoria de materia. Registrar isso e parte do
#          resultado (slide 26/31).
#
#          Como o pacote nao expoe uma lista de autores por materia entre
#          suas 36 funcoes, esta demonstracao constroi uma rede real e
#          proxima em espirito -- cooparticipacao em comissoes -- a partir
#          de membros_comissoes_57.rds (aula 2). Dois senadores sao
#          conectados se dividem uma comissao; o peso da aresta e o numero
#          de comissoes em comum. E uma rede institucional legitima, so
#          que mede coparticipacao, nao coautoria de projetos.
# Inputs: curso_senatebR/dados/senadores_57.rds,
#         curso_senatebR/dados/membros_comissoes_57.rds
#         (de 01_coleta_responsavel.R e 04_arenas_comissoes.R, aula 2)
# Outputs: curso_senatebR/figuras/rede-coparticipacao-comissoes.png
# ============================================================

library(igraph)
library(ggraph)
library(dplyr)
library(tidyr)

senadores <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds")) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))
membros <- readRDS(here::here("curso_senatebR/dados/membros_comissoes_57.rds")) |>
  dplyr::filter(!is.na(IdentificacaoComissao.CodigoComissao))

# todos os pares de colegas de comissao por comissao (analogo ao
# `combn(CodigoParlamentar, 2)` do slide, so que agrupado por comissao em
# vez de por materia)
pares <- membros |>
  dplyr::group_by(IdentificacaoComissao.CodigoComissao) |>
  dplyr::filter(dplyr::n_distinct(CodigoParlamentar) >= 2) |>
  dplyr::summarise(
    pares = list(as.data.frame(t(utils::combn(unique(CodigoParlamentar), 2)))),
    .groups = "drop"
  ) |>
  tidyr::unnest(pares) |>
  dplyr::rename(autor1 = V1, autor2 = V2) |>
  dplyr::count(autor1, autor2, name = "peso")

g <- igraph::graph_from_data_frame(pares, directed = FALSE)

grafico <- ggraph::ggraph(g, layout = "fr") +
  ggraph::geom_edge_link(ggplot2::aes(width = peso), alpha = .15) +
  ggraph::geom_node_point(size = 2.5, color = "#002B4E") +
  ggplot2::theme_void()

dir.create(here::here("curso_senatebR/figuras"), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(here::here("curso_senatebR/figuras/rede-coparticipacao-comissoes.png"), grafico, width = 8, height = 8, dpi = 300)

message(igraph::vcount(g), " nos, ", igraph::ecount(g), " arestas na rede de coparticipacao em comissoes.")
message("Grafico salvo em curso_senatebR/figuras/rede-coparticipacao-comissoes.png")

# A rede mostra o que nenhuma tabela mostra: que a cooperacao
# institucional tem geografia propria, e ela nao e o mapa dos partidos.
# Para uma rede de coautoria de MATERIAS de verdade, seria preciso um
# endpoint que o senatebR ainda nao cobre -- exatamente o tipo de lacuna
# que motivou o pipeline de emendas deste projeto
# (ver exemplos_aplicados/ranking_de_emendas.md).
