# ============================================================
# Script: 01_coleta_responsavel.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 2, disciplina de projeto (slide 24) -- "colete uma vez,
#          analise cem". Separa coleta de analise em scripts diferentes,
#          com pacing (Sys.sleep) e protecao (tryCatch) em qualquer loop
#          contra a API. A API do Senado nao tem rate limit documentado,
#          mas requisicoes frequentes devolvem HTTP 429 ou 503 -- e um
#          servico publico sem autenticacao, mantido com recurso publico.
# Inputs: none
# Outputs: curso_senatebR/dados/votacoes_2019_2023.rds,
#          curso_senatebR/dados/senadores_57.rds
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(senatebR)))
suppressWarnings(suppressPackageStartupMessages(library(dplyr)))

dir.create(here::here("curso_senatebR", "dados"), recursive = TRUE, showWarnings = FALSE)

# em loop, sempre com pausa e protecao
coletar <- function(ano) {
  Sys.sleep(0.5)
  # suppressWarnings: a funcao emite um aviso interno de coercao de tipo por
  # registro processado (implementacao do parsing XML do pacote, nao um
  # achado -- ver 04_discursos.R para um exemplo de aviso que E um achado)
  tryCatch(suppressWarnings(extrair_votacoes_nominais_por_ano(anos = ano)), error = function(e) NULL)
}

votacoes <- lapply(2019:2023, coletar) |> dplyr::bind_rows()
saveRDS(votacoes, here::here("curso_senatebR", "dados", "votacoes_2019_2023.rds"))
message(nrow(votacoes), " linhas de votacao (2019-2023) salvas.")

# padrao util para 02-analise.R: so baixa se ainda nao existe
caminho <- here::here("curso_senatebR", "dados", "senadores_57.rds")
if (!file.exists(caminho)) {
  saveRDS(obter_dados_senadores_legislatura(57, 57), caminho)
}

# Bonus: com os .rds versionados, seu coautor roda a analise sem depender
# da API estar de pe. Requisicao repetida sem necessidade e desperdicio e
# as vezes bloqueio para a turma inteira.
