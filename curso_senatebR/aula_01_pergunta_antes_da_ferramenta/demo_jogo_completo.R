# ============================================================
# Script: demo_jogo_completo.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Demonstracao da Aula 1 (slides 13, 15-19) -- "o jogo completo":
#          uma pergunta politica de ponta a ponta em ~20 min, sem
#          laboratorio (a turma ve o formato do resultado antes de
#          aprender a produzi-lo). Pergunta: os partidos realmente votam
#          como blocos? Etapas: coleta -> transformacao -> indicador ->
#          comparacao -> grafico -> interpretacao.
# Inputs: none
# Outputs: curso_senatebR/figuras/coesao-2023.png
# ============================================================

suppressWarnings(suppressPackageStartupMessages(library(senatebR)))
suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))

# ------------------------------------------------------------
# SLIDE 13 -- duas formas de obter a mesma tabela
# ------------------------------------------------------------
# SEM senatebR (o que o pacote esconde -- so um endpoint, sem tratamento
# de erro de rede):
#
#   library(httr); library(xml2)
#   url <- "https://legis.senado.leg.br/dadosabertos/senador/lista/atual"
#   resp <- GET(url)
#   doc  <- read_xml(content(resp, "text"))
#   nos  <- xml_find_all(doc, ".//Parlamentar")
#   dados <- data.frame(
#     codigo  = xml_text(xml_find_all(nos, ".//CodigoParlamentar")),
#     nome    = xml_text(xml_find_all(nos, ".//NomeParlamentar")),
#     partido = xml_text(xml_find_all(nos, ".//SiglaPartido...")),
#     uf      = xml_text(xml_find_all(nos, ".//UfParlamentar"))
#   )
#
# COM senatebR -- uma linha, testada, documentada e citavel, contra ~20
# linhas reescritas a cada projeto:
senadores <- obter_dados_senadores_legislatura(57, 57)

# ------------------------------------------------------------
# ETAPA 1-2 (slide 15) -- COLETA: duas chamadas, dois universos
# ------------------------------------------------------------
# o quê: todas as votacoes nominais do ano
# suppressWarnings: a funcao emite um aviso interno de coercao de tipo por
# registro processado (implementacao do parsing XML do pacote, nao um achado)
votacoes <- suppressWarnings(extrair_votacoes_nominais_por_ano(anos = 2023))

dplyr::glimpse(votacoes)
# Uma linha por senador por votacao: esse e o grao da analise.
# E repare nos nomes: Votos.Voto, nao voto -- eles vem direto do XML.

# ------------------------------------------------------------
# ETAPA 3-5 (slide 16) -- TRANSFORMACAO -> INDICADOR: Indice de Rice
# ------------------------------------------------------------
# rice = |sim - nao| / (sim + nao)
# 1,0 = a bancada votou unida. 0,0 = dividida ao meio.
#
# Secreta == "N" e os dois filter() sao decisoes de pesquisa, nao
# detalhes tecnicos -- por isso ficam declarados aqui, nao escondidos.
rice <- votacoes |>
  dplyr::filter(Secreta == "N", Votos.Voto %in% c("Sim", "Não")) |>
  dplyr::count(CodigoSessaoVotacao, Votos.SiglaPartido, Votos.Voto) |>
  tidyr::pivot_wider(names_from = Votos.Voto, values_from = n, values_fill = 0) |>
  dplyr::rename(sim = "Sim", nao = "Não") |>
  dplyr::filter(sim + nao >= 3) |> # bancadas minimas
  dplyr::mutate(rice = abs(sim - nao) / (sim + nao))

coesao <- rice |>
  dplyr::group_by(Votos.SiglaPartido) |>
  dplyr::summarise(rice_medio = mean(rice), n_votacoes = dplyr::n(), .groups = "drop") |>
  dplyr::filter(n_votacoes >= 20) |>
  dplyr::arrange(dplyr::desc(rice_medio))

# ------------------------------------------------------------
# ETAPA 6-7 (slide 17) -- COMPARACAO -> GRAFICO
# ------------------------------------------------------------
dir.create(here::here("curso_senatebR", "figuras"), recursive = TRUE, showWarnings = FALSE)

grafico_coesao <- coesao |>
  ggplot2::ggplot(ggplot2::aes(x = rice_medio, y = forcats::fct_reorder(Votos.SiglaPartido, rice_medio))) +
  ggplot2::geom_col(fill = "#17543A", width = .7) +
  ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", rice_medio)), hjust = -0.2, size = 4) +
  ggplot2::scale_x_continuous(limits = c(0, 1.05)) +
  ggplot2::labs(
    title = "Partidos votam como blocos?",
    subtitle = "Índice de Rice médio, nominais de 2023",
    x = "Rice médio", y = NULL,
    caption = "Fonte: Senado Federal via senatebR"
  ) +
  ggplot2::theme_minimal(base_size = 13)

ggplot2::ggsave(here::here("curso_senatebR", "figuras", "coesao-2023.png"), grafico_coesao, width = 8, height = 5, dpi = 300)
# Salve sempre em figuras/. O grafico faz parte do produto reproduzivel,
# nao e subproduto da sessao.

# ------------------------------------------------------------
# ETAPA 8 (slide 18) -- INTERPRETACAO
# ------------------------------------------------------------
# O numero responde a primeira pergunta e imediatamente abre mais tres:
#
# 1. Coesao ou consenso? Rice alto numa votacao unanime nao mede
#    disciplina, mede que nao havia disputa -- filtre votacoes competitivas.
# 2. Quais materias? Coesao varia por area tematica; um agregado anual
#    esconde a politica do conteudo.
# 3. So o plenario? Nominais registradas sao a ponta visivel -- decisoes
#    tambem se resolvem em comissao, ou por acordo sem votacao.
#
# Boa analise de dados legislativos produz perguntas melhores, nao pontos
# finais.

print(coesao)
message("Grafico salvo em curso_senatebR/figuras/coesao-2023.png")
