# ============================================================
# Script: comparacao_materias.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Busca um grupo de comparacao (PLs de um ano que atingiram o
#          mesmo marco processual do PL 2338 -- aprovacao em Plenario) e
#          calcula a posicao/percentil do PL 2338 na distribuicao de
#          numero de emendas desse grupo. Usa a API nova
#          (dadosabertos/processo) para o grupo, e a funcao ja existente
#          de emendas_fetch.R (endpoint legado) para contar emendas de
#          cada materia do grupo.
# Inputs: none (funcoes recebem ano + tipo de deliberacao)
# Outputs: none (define funcoes; cacheia respostas em disco)
# ============================================================

library(httr)
library(jsonlite)
library(dplyr)
library(tibble)
library(purrr)

SENADO_API <- "https://legis.senado.leg.br/dadosabertos"

#' Busca a lista de materias de um ano/sigla que atingiram um determinado
#' siglaTipoDeliberacao (ex. "APROVADA_NO_PLENARIO"), via a API nova
#' dadosabertos/processo.
buscar_cohort_deliberacao <- function(ano, sigla = "PL", tipo_deliberacao = "APROVADA_NO_PLENARIO") {
  url <- paste0(SENADO_API, "/processo")
  resp <- httr::GET(url, query = list(ano = ano, sigla = sigla), httr::add_headers(accept = "application/json"))

  if (httr::status_code(resp) != 200) {
    warning("Falha ao buscar cohort de ", ano, ": HTTP ", httr::status_code(resp))
    return(tibble::tibble())
  }

  parsed <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"), flatten = TRUE)
  if (!is.data.frame(parsed) || nrow(parsed) == 0) return(tibble::tibble())

  parsed %>%
    dplyr::filter(siglaTipoDeliberacao == tipo_deliberacao) %>%
    dplyr::transmute(
      codigo_materia = as.character(codigoMateria),
      identificacao,
      ementa,
      data_apresentacao = dataApresentacao,
      situacao_atual = situacaoAtual
    )
}

#' Para um vetor de codigos de materia, busca (com cache + pacing) o numero
#' de emendas de cada uma via o endpoint legado ja usado em
#' emendas_fetch.R. Retorna uma tibble codigo_materia / n_emendas.
contar_emendas_cohort <- function(codigos, cache_dir = NULL, pause_seconds = 0.5) {
  purrr::map_dfr(codigos, function(codigo) {
    Sys.sleep(pause_seconds)
    df <- tryCatch(
      emendas_para_tibble(codigo, cache_dir = cache_dir),
      error = function(e) {
        warning("Falha ao contar emendas de ", codigo, ": ", conditionMessage(e))
        tibble::tibble()
      }
    )
    tibble::tibble(codigo_materia = codigo, n_emendas = nrow(df))
  })
}

#' Calcula a posicao e o percentil de uma materia dentro de uma
#' distribuicao de n_emendas de um cohort de comparacao.
posicao_no_cohort <- function(cohort_contagens, codigo_alvo) {
  ordenado <- cohort_contagens %>% dplyr::arrange(dplyr::desc(n_emendas))
  posicao <- which(ordenado$codigo_materia == codigo_alvo)
  n_total <- nrow(ordenado)

  if (length(posicao) == 0) {
    warning("Codigo alvo ", codigo_alvo, " nao esta no cohort de comparacao")
    return(NULL)
  }

  list(
    posicao = posicao[1],
    n_total = n_total,
    percentil = round(100 * (1 - (posicao[1] - 1) / n_total), 1),
    n_emendas_alvo = ordenado$n_emendas[posicao[1]]
  )
}
