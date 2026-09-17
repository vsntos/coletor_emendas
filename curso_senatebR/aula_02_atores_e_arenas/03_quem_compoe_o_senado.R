# ============================================================
# Script: 03_quem_compoe_o_senado.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 2, "construindo juntos" (slide 28) -- quatro verbos
#          resolvem a maior parte das perguntas descritivas sobre atores:
#          select, count, group_by, summarise.
# Inputs: curso_senatebR/dados/senadores_57.rds (de 01_coleta_responsavel.R)
# Outputs: none (script de demonstracao)
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(senatebR)))
suppressWarnings(suppressPackageStartupMessages(library(dplyr)))

senadores <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds")) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))

# 1. o que temos em maos
senadores |> dplyr::glimpse()

# 2. selecionar o essencial
base <- senadores |>
  dplyr::select(NomeParlamentar, SexoParlamentar, SiglaPartidoParlamentar, UfParlamentar)

# 3. agrupar e contar
base |> dplyr::count(SiglaPartidoParlamentar, sort = TRUE)

# 4. do bruto ao indicador
proporcao_sexo <- base |>
  dplyr::count(SexoParlamentar) |>
  dplyr::mutate(prop = n / sum(n))

print(proporcao_sexo)
#>   SexoParlamentar     n  prop
#> 1 Feminino           10 0.123
#> 2 Masculino          71 0.877

# O total de uma legislatura nao e 81 fixo: suplencias e afastamentos
# inflam a contagem. Decida se sua unidade e a cadeira ou a pessoa, e use
# processar_xml_mandatos() para defender a escolha.
#
# Exercicio (fica para o Lab 1): refazer isso sozinho e comparar duas
# legislaturas -- (55, 55) e (57, 57). Mesma consulta, argumento
# diferente, e de repente voce tem uma serie.
