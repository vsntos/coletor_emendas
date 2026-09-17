# ============================================================
# Script: emendas_fetch.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Busca as emendas de uma materia via a API do Senado, sem baixar
#          nem processar o PDF de cada emenda (so precisamos de contagens e
#          metadados de autoria para ranking, nao do texto completo) --
#          reaproveita a logica de parsing de coletor_emendas.R:12-30, sem
#          a etapa de download de PDF (coletor_emendas.R:107-127).
#
#          NOTA: o endpoint materia/emendas/{codigo} tem aviso de
#          descontinuacao no proprio payload da API (DataDesativacaoQ:
#          2026-02-01, ja passada), com substituto em
#          dadosabertos/processo -- ainda retorna dados reais (HTTP 200),
#          confirmado ao vivo em 2026-09-17. Se parar de funcionar, migrar
#          para o endpoint novo.
# Inputs: um codigo de materia do Senado (ver materia_lookup.R)
# Outputs: none (define funcoes; cacheia respostas brutas em disco)
# ============================================================

library(httr)
library(jsonlite)
library(dplyr)
library(tibble)

SENADO_API <- "https://legis.senado.leg.br/dadosabertos"

#' Busca (com cache) o JSON bruto de emendas de uma materia.
buscar_emendas_raw <- function(codigo, cache_dir = NULL, forcar_atualizacao = FALSE) {
  cache_path <- if (!is.null(cache_dir)) file.path(cache_dir, paste0(codigo, ".json")) else NULL

  if (!is.null(cache_path) && file.exists(cache_path) && !forcar_atualizacao) {
    return(jsonlite::fromJSON(cache_path, flatten = TRUE))
  }

  url <- paste0(SENADO_API, "/materia/emendas/", codigo, "?formato=json")
  resp <- httr::GET(url, httr::add_headers(accept = "application/json"))

  if (httr::status_code(resp) != 200) {
    warning("Falha ao buscar emendas do codigo ", codigo, ": HTTP ", httr::status_code(resp))
    return(NULL)
  }

  raw_json <- httr::content(resp, "text", encoding = "UTF-8")

  if (!is.null(cache_path)) {
    dir.create(dirname(cache_path), recursive = TRUE, showWarnings = FALSE)
    writeLines(raw_json, cache_path)
  }

  jsonlite::fromJSON(raw_json, flatten = TRUE)
}

#' Extrai uma tibble com uma linha por emenda: numero, data, autor
#' principal, partido, UF, sem baixar o PDF do texto de cada emenda.
emendas_para_tibble <- function(codigo, cache_dir = NULL, forcar_atualizacao = FALSE) {
  parsed <- buscar_emendas_raw(codigo, cache_dir, forcar_atualizacao)
  if (is.null(parsed)) return(tibble::tibble())

  emendas <- parsed$EmendaMateria$Materia$Emendas$Emenda
  if (is.null(emendas) || length(emendas) == 0) return(tibble::tibble())

  emendas_df <- as.data.frame(emendas)

  `%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a

  # AutoriaEmenda.Autor e uma lista-coluna (1+ autores por emenda) -- pega
  # o autor principal (IndicadorAutorPrincipal == "Sim", ou o primeiro).
  autor_principal <- function(autores) {
    if (is.null(autores) || (is.data.frame(autores) && nrow(autores) == 0)) {
      return(list(nome = NA_character_, partido = NA_character_, uf = NA_character_))
    }
    autores_df <- as.data.frame(autores)
    principal_idx <- which(autores_df$IndicadorAutorPrincipal == "Sim")
    idx <- if (length(principal_idx) > 0) principal_idx[1] else 1
    list(
      nome = autores_df$IdentificacaoParlamentar.NomeParlamentar[idx] %||% autores_df$NomeAutor[idx],
      partido = autores_df$IdentificacaoParlamentar.SiglaPartidoParlamentar[idx] %||% NA_character_,
      uf = autores_df$IdentificacaoParlamentar.UfParlamentar[idx] %||% NA_character_
    )
  }

  autores_extraidos <- lapply(emendas_df$AutoriaEmenda.Autor, autor_principal)

  tibble::tibble(
    codigo_materia = codigo,
    numero_emenda = emendas_df$NumeroEmenda,
    codigo_emenda = emendas_df$CodigoEmenda,
    data_apresentacao = emendas_df$DataApresentacao,
    tipo_emenda = emendas_df$DescricaoTipoEmenda,
    autor_nome = vapply(autores_extraidos, function(x) as.character(x$nome), character(1)),
    autor_partido = vapply(autores_extraidos, function(x) as.character(x$partido), character(1)),
    autor_uf = vapply(autores_extraidos, function(x) as.character(x$uf), character(1))
  )
}
