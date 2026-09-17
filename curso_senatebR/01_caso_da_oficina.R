# ============================================================
# Script: 01_caso_da_oficina.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Resolve o caso que atravessa toda a oficina (slide 9): o PL
#          2.630/2020 (regulacao de plataformas digitais / "Lei das Fake
#          News"), aprovado pelo Senado em 2020 e travado a partir dali.
#          Os labs 1-3 e os scripts de demonstracao das aulas 2-4 usam o
#          `Codigo` salvo aqui.
#
#          NOTA METODOLOGICA: o senatebR nao tem uma funcao de busca de
#          materia por sigla/numero/ano -- todas as suas 36 funcoes
#          recebem um `Codigo` ja resolvido. Por isso reaproveitamos
#          `R/materia_lookup.R::buscar_codigo_materia()`, ja existente na
#          raiz deste projeto (construido para o pipeline de emendas do
#          PL 2338/2023 -- ver exemplos_aplicados/ranking_de_emendas.md).
#          E a mesma lacuna da API nos dois casos.
# Inputs: none
# Outputs: curso_senatebR/dados/caso_pl2630.rds
# ============================================================

source(here::here("R", "materia_lookup.R"))

info <- buscar_codigo_materia("PL", 2630, 2020)

if (is.null(info)) stop("Nao foi possivel localizar o PL 2630/2020.")

message("Caso da oficina: ", info$identificacao, " (Codigo ", info$codigo, ")")
message("Ementa: ", info$ementa)
message("Autor: ", info$autor)

dir.create(here::here("curso_senatebR", "dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(info, here::here("curso_senatebR", "dados", "caso_pl2630.rds"))
message("Salvo em curso_senatebR/dados/caso_pl2630.rds")
