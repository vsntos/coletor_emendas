# ============================================================
# Script: lab1_composicao_e_poder_gabarito.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: LABORATORIO 1 (slide 32, 20 min) -- gabarito resolvido.
#          Pergunta: quem compos o Senado que decidiu o caso da oficina
#          (PL 2.630/2020) e onde esse poder se concentra?
#
#          TRILHA OBRIGATORIA (como no slide):
#          1. Coletar a composicao da legislatura e limpar os nomes.
#          2. Salvar em dados/ -- nao coletar de novo pelo resto do lab.
#          3. Montar a bancada por partido e a proporcao por sexo.
#          4. Produzir um grafico que voce mostraria numa reuniao.
#          SE SOBRAR TEMPO: juntar com comissoes e checar sobrerrepresentacao.
# Inputs: curso_senatebR/dados/caso_pl2630.rds (de 01_caso_da_oficina.R)
# Outputs: curso_senatebR/dados/lab1_bancada_57.rds,
#          curso_senatebR/figuras/lab1-bancada-partido.png
# ============================================================

library(senatebR)
library(tidyverse)

caso <- readRDS(here::here("curso_senatebR/dados/caso_pl2630.rds"))
message("Caso: ", caso$identificacao, " -- aprovado no Senado em 2020, na 56a legislatura.")

# ------------------------------------------------------------
# PASSO 1 -- coletar e limpar (comece pelo names(); metade dos problemas
# e prefixo de coluna)
# ------------------------------------------------------------
senadores <- obter_dados_senadores_legislatura(56, 56) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))

names(senadores)[1:4]

# ------------------------------------------------------------
# PASSO 2 -- salvar em dados/ (nao coletar de novo)
# ------------------------------------------------------------
dir.create(here::here("curso_senatebR/dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(senadores, here::here("curso_senatebR/dados/lab1_bancada_57.rds"))

# ------------------------------------------------------------
# PASSO 3 -- bancada por partido e proporcao por sexo
# ------------------------------------------------------------
bancada_partido <- senadores |>
  dplyr::filter(!is.na(SiglaPartidoParlamentar)) |>
  dplyr::count(SiglaPartidoParlamentar, sort = TRUE)

proporcao_sexo <- senadores |>
  dplyr::count(SexoParlamentar) |>
  dplyr::mutate(prop = n / sum(n))

print(bancada_partido)
print(proporcao_sexo)

# ------------------------------------------------------------
# PASSO 4 -- grafico para uma reuniao
# ------------------------------------------------------------
dir.create(here::here("curso_senatebR/figuras"), recursive = TRUE, showWarnings = FALSE)

grafico_bancada <- bancada_partido |>
  dplyr::slice_max(n, n = 15) |>
  ggplot2::ggplot(ggplot2::aes(x = n, y = forcats::fct_reorder(SiglaPartidoParlamentar, n))) +
  ggplot2::geom_col(fill = "#1E2761") +
  ggplot2::geom_text(ggplot2::aes(label = n), hjust = -0.3, size = 3.5) +
  ggplot2::labs(
    title = "Composição partidária, 56ª legislatura",
    subtitle = "Senado que decidiu o PL 2.630/2020 (regulação de plataformas digitais)",
    x = "Nº de vínculos (titulares + suplentes)", y = NULL,
    caption = "Fonte: Senado Federal via senatebR"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(here::here("curso_senatebR/figuras/lab1-bancada-partido.png"), grafico_bancada, width = 8, height = 6, dpi = 300)

# ------------------------------------------------------------
# SE SOBRAR TEMPO -- sobrerrepresentacao em comissao vs. plenario
# sobrerrepresentacao = participacao na comissao / participacao no plenario
# ------------------------------------------------------------
codigos <- unique(stats::na.omit(senadores$CodigoParlamentar))
membros <- obter_dados_comissoes_parlamentares(codigos) |>
  dplyr::filter(!is.na(IdentificacaoComissao.CodigoComissao)) |>
  dplyr::left_join(senadores, by = "CodigoParlamentar")

participacao_plenario <- senadores |>
  dplyr::filter(!is.na(SiglaPartidoParlamentar)) |>
  dplyr::count(SiglaPartidoParlamentar) |>
  dplyr::mutate(prop_plenario = n / sum(n))

participacao_comissoes <- membros |>
  dplyr::filter(!is.na(SiglaPartidoParlamentar)) |>
  dplyr::count(SiglaPartidoParlamentar) |>
  dplyr::mutate(prop_comissoes = n / sum(n))

sobrerrepresentacao <- participacao_comissoes |>
  dplyr::select(SiglaPartidoParlamentar, prop_comissoes) |>
  dplyr::inner_join(
    participacao_plenario |> dplyr::select(SiglaPartidoParlamentar, prop_plenario),
    by = "SiglaPartidoParlamentar"
  ) |>
  dplyr::mutate(razao = prop_comissoes / prop_plenario) |>
  dplyr::arrange(dplyr::desc(razao))

message("\nPartidos mais sobrerrepresentados em comissoes (razao > 1 = mais peso em comissao que no plenario):")
print(utils::head(sobrerrepresentacao, 10))
