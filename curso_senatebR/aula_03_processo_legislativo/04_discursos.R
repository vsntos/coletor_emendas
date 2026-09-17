# ============================================================
# Script: 04_discursos.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 3, "o Legislativo como texto" (slide 41) -- voto e escasso,
#          palavra nao. Tres perguntas que so o texto responde: sobre o
#          que um parlamentar fala, com que frequencia, e com quem disputa
#          a palavra.
# Inputs: curso_senatebR/dados/senadores_57.rds (de 01_coleta_responsavel.R,
#         aula 2)
# Outputs: none (script de demonstracao)
# ============================================================

library(senatebR)
library(dplyr)

senadores <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds")) |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))

# Demo com uma amostra de 15 senadores (a chamada completa com 245 codigos
# e realista para uma analise, mas pesada demais para uma demonstracao ao
# vivo -- em sala, comece pequeno e so escale depois de ver o formato).
codigos_amostra <- unique(stats::na.omit(senadores$CodigoParlamentar))[1:15]

# pronunciamentos de varios senadores num ano
pronunciamentos <- extrair_pronunciamentos_multi(codigos_parlamentares = codigos_amostra, anos = 2023)

# atencao: aqui a chave e Codigo_Parlamentar (com sublinhado)
volume <- pronunciamentos |>
  dplyr::count(Codigo_Parlamentar, name = "n_discursos") |>
  dplyr::left_join(senadores, by = c("Codigo_Parlamentar" = "CodigoParlamentar")) |>
  dplyr::arrange(dplyr::desc(n_discursos)) |>
  dplyr::select(NomeParlamentar, SiglaPartidoParlamentar, n_discursos)

print(volume)

# discursos de um parlamentar especifico (exige data_inicio/data_fim) --
# usamos quem mais discursou na amostra, para garantir um resultado nao
# vazio na demonstracao
codigo_top <- senadores$CodigoParlamentar[senadores$NomeParlamentar == volume$NomeParlamentar[1]][1]
discursos <- extrair_discursos(
  codigo_senador = codigo_top,
  data_inicio = "20230201",
  data_fim = "20231231"
)
message(nrow(discursos), " discursos individuais encontrados para ", volume$NomeParlamentar[1], " em 2023.")

# e quem interrompe quem em plenario
# NOTA (verificado ao vivo em 2026-09-17): processar_xml_apartes() nao
# aceita o CodigoParlamentar do senador -- rejeita com "Código inválido ou
# muito longo" para todos os codigos testados aqui. E uma medida de
# conflito "raramente usada" (slide 41); nao investigamos mais fundo o
# formato de codigo que a funcao espera internamente. Documentar isso e
# parte do resultado (slide 26: honestidade metodologica).
apartes <- processar_xml_apartes(codigos = codigos_amostra)
message(nrow(apartes), " apartes registrados para a amostra.")

# Volume de discurso e uma medida de esforco de representacao -- e
# frequentemente diverge do comportamento em votacao. E ai que fica
# interessante.
#
# Analise de texto (frequencia, topicos, sentimento) e um campo inteiro.
# Esta oficina para na coleta e na contagem -- o livro segue adiante no
# capitulo 7.
