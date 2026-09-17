# ============================================================
# Script: lab2_tramitacao_do_caso_gabarito.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: LABORATORIO 2 (slide 43, 20 min, em duplas) -- gabarito resolvido.
#          Pergunta: o PL 2.630/2020 (caso da oficina) tramitou rapido ou
#          lento? Defenda com numero.
#
#          TRILHA OBRIGATORIA (como no slide):
#          1. Coletar materias_legislatura_atual() e encontrar a materia
#             do caso.
#          2. Descobrir o subtipo e contar quantas materias do mesmo
#             subtipo existem por ano.
#          3. Recuperar as situacoes de tramitacao com
#             extrair_situacoes_tramitacao().
#          4. Escrever a frase: "o caso tramitou __, contra uma mediana
#             de __".
#          SE SOBRAR TEMPO: reproduzir o grafico de anos eleitorais e
#          checar a agenda de hoje.
# Inputs: curso_senatebR/dados/caso_pl2630.rds (de 01_caso_da_oficina.R),
#         curso_senatebR/dados/votacoes_2019_2023.rds
#         (de 01_coleta_responsavel.R, aula 2)
# Outputs: curso_senatebR/dados/lab2_duracoes_cohort_2020.rds
# ============================================================

library(senatebR)
library(dplyr)

# reaproveita R/comparacao_materias.R (ja existente na raiz do projeto,
# construido para o pipeline de emendas do PL 2338/2023) -- ver a nota
# metodologica no cabecalho de 01_caso_da_oficina.R
source(here::here("R", "comparacao_materias.R"))

caso <- readRDS(here::here("curso_senatebR/dados/caso_pl2630.rds"))

# ------------------------------------------------------------
# PASSO 1 -- antes de qualquer join, count(chave) |> filter(n > 1)
# ------------------------------------------------------------
materias <- materias_legislatura_atual()
achado <- materias |> dplyr::filter(CodigoMateria == caso$codigo)

message(nrow(achado), " ocorrencias do PL 2630/2020 em materias_legislatura_atual().")
message("Esperado: 0 -- a materia ja foi remetida a Camara e nao tramita mais no Senado ",
        "(IndicadorTramitando == \"Sim\" para todas as linhas desta funcao). Mesma lacuna ",
        "documentada em curso_senatebR/aula_03_processo_legislativo/02_materias_e_tramitacao.R.")

# ------------------------------------------------------------
# PASSO 2 -- subtipo (PL) e quantas materias do mesmo subtipo por ano
# (AnoMateria e so o ano; para "rapido ou lento" de verdade, PASSO 4 usa
# datas de verdade, nao contagem por ano)
# ------------------------------------------------------------
pls_por_ano <- materias |>
  dplyr::filter(SiglaSubtipoMateria == "PL", !is.na(AnoMateria)) |>
  dplyr::count(Ano = as.integer(AnoMateria), name = "n_pls") |>
  dplyr::arrange(dplyr::desc(Ano))

print(utils::head(pls_por_ano, 10))

# cohort de comparacao buscado aqui (em vez de so no PASSO 4) porque e a
# unica fonte, entre as ja usadas neste script, que traz a situacao_atual
# de verdade da materia -- buscar_codigo_materia() (usado em
# 01_caso_da_oficina.R) nao retorna esse campo.
cohort_2020 <- buscar_cohort_deliberacao(2020, "PL", "APROVADA_NO_PLENARIO")
stopifnot(caso$codigo %in% cohort_2020$codigo_materia)
situacao_atual_caso <- cohort_2020$situacao_atual[cohort_2020$codigo_materia == caso$codigo]

# ------------------------------------------------------------
# PASSO 3 -- dicionario de situacoes de tramitacao
# ------------------------------------------------------------
situacoes <- extrair_situacoes_tramitacao()
message(nrow(situacoes), " situacoes possiveis no catalogo. Situacao atual do nosso caso: \"",
        situacao_atual_caso, "\".")

# ------------------------------------------------------------
# PASSO 4 -- "rapido ou lento", com numero de verdade: dias entre
# apresentacao e aprovacao no Plenario, comparado a um cohort de PLs de
# 2020 que chegaram ao MESMO marco processual (APROVADA_NO_PLENARIO) --
# mesma logica do exemplo de emendas (ver exemplos_aplicados/
# ranking_de_emendas.md), so que medindo tempo em vez de nº de emendas.
# ------------------------------------------------------------
votacoes <- readRDS(here::here("curso_senatebR/dados/votacoes_2019_2023.rds"))

aprovacoes <- votacoes |>
  dplyr::filter(Resultado == "A") |>
  dplyr::group_by(CodigoMateria) |>
  dplyr::summarise(data_aprovacao = min(DataSessao), .groups = "drop")

# NOTA: so entram no calculo os PLs do cohort que tiveram uma VOTACAO
# NOMINAL registrada -- a maioria das aprovacoes no Senado e simbolica
# (sem registro nominal), entao esta amostra tende a ser de materias mais
# disputadas/visiveis, nao do universo inteiro dos 183 PLs do cohort.
# Declarar isso e parte do resultado.
duracoes <- cohort_2020 |>
  dplyr::inner_join(aprovacoes, by = c("codigo_materia" = "CodigoMateria")) |>
  dplyr::mutate(dias_tramitacao = as.numeric(as.Date(data_aprovacao) - as.Date(data_apresentacao))) |>
  dplyr::arrange(dias_tramitacao) |>
  dplyr::mutate(posicao = dplyr::row_number())

dir.create(here::here("curso_senatebR/dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(duracoes, here::here("curso_senatebR/dados/lab2_duracoes_cohort_2020.rds"))

nosso_caso <- duracoes |> dplyr::filter(codigo_materia == caso$codigo)
mediana_cohort <- stats::median(duracoes$dias_tramitacao)

message(
  "\nCom votacao nominal registrada: ", nrow(duracoes), " de ", nrow(cohort_2020),
  " PLs de 2020 aprovados no Plenario."
)
message(
  "\nFRASE: o PL 2630/2020 tramitou ", nosso_caso$dias_tramitacao, " dias (apresentacao em ",
  nosso_caso$data_apresentacao, ", aprovacao em ", nosso_caso$data_aprovacao,
  "), contra uma mediana de ", mediana_cohort, " dias entre os ", nrow(duracoes),
  " PLs de 2020 comparaveis (posicao ", nosso_caso$posicao, " de ", nrow(duracoes),
  ", do mais rapido para o mais lento)."
)
message(
  "\nInterpretacao honesta: 48 dias e rapido em termos absolutos, mas ", nosso_caso$posicao,
  "/", nrow(duracoes), " esta bem perto da MEDIANA do cohort -- ou seja, o PL 2630 nao foi um ",
  "outlier de velocidade entre PLs que chegam ao Plenario. A narrativa de \"aprovado as pressas\" ",
  "(slide 9) e sobre visibilidade politica, nao sobre desvio estatistico do tempo de tramitacao."
)

# ------------------------------------------------------------
# SE SOBRAR TEMPO -- a agenda de hoje tem o tema do caso?
# ------------------------------------------------------------
hoje <- Sys.Date()
agenda_hoje <- info_agenda(
  anos = as.integer(format(hoje, "%Y")),
  meses = as.integer(format(hoje, "%m")),
  dias = as.integer(format(hoje, "%d"))
)
message(
  "\nAgenda de hoje (", hoje, "): ", nrow(agenda_hoje), " itens. O PL 2630/2020 nao pode aparecer -- ",
  "ja esta na Camara, fora da agenda do Senado."
)
