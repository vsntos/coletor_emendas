# ============================================================
# Script: materia_lookup.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Resolve a identificacao publica de um projeto de lei (sigla +
#          numero + ano, ex. "PL 2338/2023") para o Codigo interno do
#          Senado, necessario para consultar emendas.
# Inputs: none (funcoes recebem sigla/numero/ano)
# Outputs: none (define funcoes)
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(httr)))
suppressWarnings(suppressPackageStartupMessages(library(jsonlite)))

SENADO_API <- "https://legis.senado.leg.br/dadosabertos"

#' Busca o Codigo interno do Senado para uma materia, a partir da sua
#' identificacao publica (ex.: sigla="PL", numero=2338, ano=2023).
#' Retorna NULL se nao encontrar nenhuma correspondencia.
buscar_codigo_materia <- function(sigla, numero, ano) {
  url <- paste0(SENADO_API, "/materia/pesquisa/lista")
  resp <- httr::GET(
    url,
    query = list(sigla = sigla, numero = numero, ano = ano),
    httr::add_headers(accept = "application/json")
  )

  if (httr::status_code(resp) != 200) {
    warning("Falha na busca de materia (", sigla, " ", numero, "/", ano, "): HTTP ", httr::status_code(resp))
    return(NULL)
  }

  parsed <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"), flatten = TRUE)
  materias <- parsed$PesquisaBasicaMateria$Materias$Materia

  if (is.null(materias) || nrow(as.data.frame(materias)) == 0) {
    warning("Nenhuma materia encontrada para ", sigla, " ", numero, "/", ano)
    return(NULL)
  }

  materias <- as.data.frame(materias)
  list(
    codigo = materias$Codigo[1],
    identificacao = materias$DescricaoIdentificacao[1],
    ementa = materias$Ementa[1],
    autor = materias$Autor[1]
  )
}
