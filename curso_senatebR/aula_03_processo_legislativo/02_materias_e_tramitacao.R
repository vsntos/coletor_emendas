# ============================================================
# Script: 02_materias_e_tramitacao.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 3, matérias (slide 39) -- o que tramita e o que travou?
#          Apresentar um projeto e um ato individual e barato; decidir e
#          coletivo, caro e procedimental. Contar materias mede oferta,
#          nao producao legislativa.
# Inputs: none
# Outputs: curso_senatebR/dados/materias_legislatura_atual.rds
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(senatebR)))
suppressWarnings(suppressPackageStartupMessages(library(dplyr)))

# 1. oferta: o que foi apresentado (e ainda tramita -- ver nota abaixo)
materias <- materias_legislatura_atual()
dir.create(here::here("curso_senatebR/dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(materias, here::here("curso_senatebR/dados/materias_legislatura_atual.rds"))

materias |> dplyr::count(SiglaSubtipoMateria, sort = TRUE) |> utils::head(15) |> print()

# NOTA (verificado ao vivo em 2026-09-17): esta funcao so retorna materias
# com IndicadorTramitando == "Sim". O caso da oficina (PL 2630/2020) NAO
# aparece aqui, porque ja foi remetido a Camara dos Deputados e nao
# tramita mais no Senado -- exatamente a mesma lacuna encontrada no
# pipeline de emendas do PL 2338/2023 (ver
# exemplos_aplicados/ranking_de_emendas.md). O Lab 2 contorna isso
# reaproveitando R/comparacao_materias.R, que usa outro endpoint
# (dadosabertos/processo) para consultar materias por ano independente de
# ainda estarem tramitando.

# 2. sobre o que e (catalogos de referencia -- nao sao dados de uma
#    materia especifica, sao dicionarios para decodificar campos)
temas <- info_materia_temas()
classes <- extrair_classificacoes_materia()

# 3. em que estagio esta (dicionario de situacoes possiveis)
situacoes <- extrair_situacoes_tramitacao()

message(nrow(temas), " temas, ", nrow(classes), " classificacoes, ",
        nrow(situacoes), " situacoes possiveis no catalogo.")

# 4. atencao: AnoMateria e so o ano, nao uma data
por_ano_subtipo <- materias |>
  dplyr::filter(!is.na(AnoMateria)) |>
  dplyr::mutate(Ano = as.integer(AnoMateria)) |>
  dplyr::count(Ano, SiglaSubtipoMateria) |>
  dplyr::arrange(dplyr::desc(Ano))

print(utils::head(por_ano_subtipo, 15))

# Se a sua pergunta e sobre velocidade de tramitacao, o ano nao basta --
# voce precisa das datas da tramitacao, nao da materia. A pergunta que
# organiza tudo: qual evento legislativo estou tentando observar?
# Apresentacao, movimento, aprovacao e promulgacao sao objetos diferentes.
