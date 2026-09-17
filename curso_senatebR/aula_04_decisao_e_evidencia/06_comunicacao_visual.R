# ============================================================
# Script: 06_comunicacao_visual.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 4, "tres formatos, tres perguntas" (slide 53) -- escolha a
#          geometria a partir da pergunta, nao do repertorio que voce ja
#          domina. ggplot2 para comparacao, geobr para territorio
#          (a representacao no Senado e geografica por construcao: tres
#          por estado), gt para precisao (quando o leitor precisa do
#          numero exato).
# Inputs: curso_senatebR/dados/senadores_57.rds,
#         curso_senatebR/dados/membros_comissoes_57.rds
#         (de 01_coleta_responsavel.R e 04_arenas_comissoes.R, aula 2)
# Outputs: curso_senatebR/figuras/mapa-comissoes-por-uf.png
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(dplyr)))
suppressWarnings(suppressPackageStartupMessages(library(ggplot2)))
suppressWarnings(suppressPackageStartupMessages(library(geobr)))
suppressWarnings(suppressPackageStartupMessages(library(gt)))

senadores <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds")) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))
membros <- readRDS(here::here("curso_senatebR/dados/membros_comissoes_57.rds")) |>
  dplyr::filter(!is.na(IdentificacaoComissao.CodigoComissao))

# ------------------------------------------------------------
# ggplot2 -- COMPARACAO: barras ordenadas para "quem e mais"
# ------------------------------------------------------------
# ja demonstrado em aula_02/03_quem_compoe_o_senado.R e
# aula_02/04_arenas_comissoes.R -- fct_reorder() e o que transforma um
# grafico ruim em um grafico legivel.

# ------------------------------------------------------------
# geobr -- TERRITORIO: a unidade de analise e o estado, nao enfeite
# ------------------------------------------------------------
# Cuidado: mapa de valor absoluto em estado grande engana -- normalize.
# Aqui usamos a MEDIA de comissoes por senador do estado (nao a soma), que
# ja e normalizada pelo numero de senadores daquele estado.
comissoes_por_uf <- membros |>
  dplyr::count(CodigoParlamentar, name = "n_comissoes") |>
  dplyr::left_join(senadores, by = "CodigoParlamentar") |>
  dplyr::filter(!is.na(UfParlamentar)) |>
  dplyr::group_by(UfParlamentar) |>
  dplyr::summarise(media_comissoes = mean(n_comissoes), .groups = "drop")

mapa_uf <- geobr::read_state(showProgress = FALSE) |>
  dplyr::left_join(comissoes_por_uf, by = c("abbrev_state" = "UfParlamentar"))

grafico_mapa <- mapa_uf |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = media_comissoes), color = "white", linewidth = 0.2) +
  ggplot2::scale_fill_viridis_c(name = "Média de\ncomissões\npor senador", na.value = "grey85") +
  ggplot2::labs(
    title = "Participação média em comissões, por UF",
    subtitle = "56ª/57ª legislaturas -- valor normalizado pelo nº de senadores do estado",
    caption = "Fonte: Senado Federal via senatebR + geobr"
  ) +
  ggplot2::theme_void()

dir.create(here::here("curso_senatebR/figuras"), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(here::here("curso_senatebR/figuras/mapa-comissoes-por-uf.png"), grafico_mapa, width = 7, height = 7, dpi = 300)
message("Mapa salvo em curso_senatebR/figuras/mapa-comissoes-por-uf.png")

# ------------------------------------------------------------
# gt -- PRECISAO: quando o leitor precisa do numero exato
# ------------------------------------------------------------
# Tabela nao e grafico que deu errado. E outro instrumento.
tabela_top10 <- membros |>
  dplyr::count(CodigoParlamentar, name = "n_comissoes") |>
  dplyr::left_join(senadores, by = "CodigoParlamentar") |>
  dplyr::arrange(dplyr::desc(n_comissoes)) |>
  dplyr::select(NomeParlamentar, SiglaPartidoParlamentar, UfParlamentar, n_comissoes) |>
  utils::head(10) |>
  gt::gt() |>
  gt::tab_header(title = "Top 10 em participação em comissões") |>
  gt::cols_label(
    NomeParlamentar = "Senador(a)",
    SiglaPartidoParlamentar = "Partido",
    UfParlamentar = "UF",
    n_comissoes = "Nº comissões"
  )

tabela_top10

# Escolha a geometria a partir da pergunta -- nao do repertorio que voce
# ja domina.
