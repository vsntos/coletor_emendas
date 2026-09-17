# ============================================================
# Script: 00_setup.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Instalacao e teste de fumaca do curso senatebR (slide 21 da
#          oficina). Roda uma unica vez, antes de qualquer outro script
#          desta pasta.
# Inputs: none
# Outputs: curso_senatebR/dados/senadores_57.rds
# ============================================================

# 1. o pacote esta no CRAN
# NOTA: requireNamespace(quietly = TRUE) so silencia o aviso de "pacote nao
# encontrado" -- carregar o namespace de um pacote ja instalado ainda pode
# emitir avisos de conflito de importacao (ex.: magrittr::set_names vs
# purrr::set_names dentro do senatebR), entao envolvemos em suppressWarnings()
if (!suppressWarnings(suppressMessages(requireNamespace("senatebR", quietly = TRUE)))) install.packages("senatebR")

# 2. pacotes de apoio da oficina
pacotes_apoio <- c("tidyverse", "lubridate", "gt", "igraph", "ggraph", "geobr")
faltando <- pacotes_apoio[!suppressWarnings(suppressMessages(
  vapply(pacotes_apoio, requireNamespace, logical(1), quietly = TRUE)
))]
if (length(faltando) > 0) install.packages(faltando)

# 3. carregar
suppressWarnings(suppressPackageStartupMessages(library(senatebR)))
suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))

# 4. teste de fumaca: a API responde?
senadores <- obter_dados_senadores_legislatura(57, 57)
dim(senadores)

# 5. guarde ja em disco -- here::here() resolve o caminho a partir da raiz
# do projeto (onde esta coletor_emendas.Rproj), nao do diretorio de
# trabalho atual, entao este script roda igual via Rscript (raiz do
# projeto) ou como capitulo do site Quarto (raiz = curso_senatebR/)
dir.create(here::here("curso_senatebR", "dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(senadores, here::here("curso_senatebR", "dados", "senadores_57.rds"))

message("Setup ok. ", nrow(senadores), " senadores da 57a legislatura salvos em ",
        here::here("curso_senatebR/dados/senadores_57.rds"))

# REQUISITOS
# - R >= 4.1
# - RStudio ou Positron
# - Conexao aberta com legis.senado.leg.br
#
# SE FALHAR: proxy institucional e certificado SSL sao os erros mais comuns.
# Trabalhe sempre dentro de um projeto RStudio, com caminho relativo e script
# versionado -- reprodutibilidade comeca aqui, nao no fim.
