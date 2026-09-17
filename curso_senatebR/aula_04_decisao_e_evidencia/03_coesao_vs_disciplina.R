# ============================================================
# Script: 03_coesao_vs_disciplina.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 4, "a distincao que importa" (slide 49) -- estudo de caso 2
#          do livro. Coesao mede se a bancada votou junto; disciplina mede
#          se votou junto com o lider. Uma bancada pode ser coesa contra a
#          propria lideranca. "Liberado" e "Obstrucao" nao sao orientacao
#          de merito -- mante-los na conta mede outra coisa.
#
#          ~20 requisicoes, 1-2 min. O Sys.sleep(0.5) e o tryCatch() nao
#          sao zelo excessivo: sao o que faz o script terminar.
# Inputs: curso_senatebR/dados/votacoes_2019_2023.rds
#         (de 01_coleta_responsavel.R, aula 2)
# Outputs: curso_senatebR/dados/disciplina_2023.rds
# ============================================================

library(senatebR)
library(dplyr)

# 1. votos individuais
nominais <- readRDS(here::here("curso_senatebR/dados/votacoes_2019_2023.rds")) |>
  dplyr::filter(Ano == "2023", Secreta == "N", Votos.Voto %in% c("Sim", "Não"))

# 2. orientacao do lider -- uma requisicao por data de sessao
datas <- unique(nominais$DataSessao)[1:20]

orientacoes <- lapply(datas, function(d) {
  Sys.sleep(0.5)
  res <- tryCatch(coletar_orientacao_votacao(data_sessao = d), error = function(e) NULL)
  if (!is.null(res) && nrow(res) > 0) res$DataSessao <- d
  res
}) |> dplyr::bind_rows()

message(nrow(orientacoes), " linhas de orientacao de bancada coletadas para ", length(datas), " datas.")

dir.create(here::here("curso_senatebR/dados"), recursive = TRUE, showWarnings = FALSE)
saveRDS(orientacoes, here::here("curso_senatebR/dados/orientacoes_2023.rds"))

# ACHADO (verificado ao vivo em 2026-09-17): o slide junta por
# c("CodigoSessaoVotacao" = "codigo_votacao"), mas essas duas colunas NAO
# compartilham o mesmo espaco de codigos. Exemplo real, mesma data
# (2023-03-28): extrair_votacoes_nominais_por_ano() reporta
# CodigoSessaoVotacao = 6675 para a votacao daquele dia, enquanto
# coletar_orientacao_votacao() reporta codigo_votacao = 8408 para a MESMA
# sessao -- sao duas numeracoes internas diferentes do Senado, nao a mesma
# chave. Juntar como o slide descreve produz 0 linhas. Registrar isso e
# parte do resultado (slide 26 e 31): documentamos aqui para consertar no
# pacote depois, e usamos abaixo um join mais grosseiro (por DATA + PARTIDO,
# em vez de por votacao especifica) que funciona com os dados reais --
# ao custo de nao distinguir duas votacoes do mesmo partido no mesmo dia.
#
# a API tambem devolve o voto em maiusculas (SIM/NAO) e a sigla de partido
# por extenso em alguns casos ("Podemos", "Republica"), diferentes das
# colunas de votos nominais ("Sim"/"Não", "PODE", "REPUBLICANOS") -- mais
# uma armadilha de nomes/valores.
orientacoes_padronizadas <- orientacoes |>
  dplyr::mutate(
    voto = dplyr::if_else(
      toupper(voto) == "SIM", "Sim",
      dplyr::if_else(toupper(voto) %in% c("NAO", "NÃO"), "Não", voto)
    ),
    partido = dplyr::case_when(
      partido == "Podemos" ~ "PODE",
      partido == "Republica" ~ "REPUBLICANOS",
      TRUE ~ toupper(partido)
    )
  ) |>
  dplyr::filter(voto %in% c("Sim", "Não")) # exclui Liberado / Obstrução / bancadas informais

# 3. o senador seguiu a orientacao da propria bancada? (join por
# DataSessao + partido -- a chave por votacao especifica nao e viavel com
# os dados como o pacote os expoe hoje, ver achado acima)
disciplina <- nominais |>
  dplyr::inner_join(
    orientacoes_padronizadas,
    by = c("DataSessao", "Votos.SiglaPartido" = "partido"),
    relationship = "many-to-many"
  ) |>
  dplyr::mutate(seguiu = Votos.Voto == voto) |>
  dplyr::group_by(Votos.SiglaPartido) |>
  dplyr::summarise(disciplina = mean(seguiu), n = dplyr::n(), .groups = "drop") |>
  dplyr::arrange(dplyr::desc(disciplina))

saveRDS(disciplina, here::here("curso_senatebR/dados/disciplina_2023.rds"))
print(disciplina)

message(
  "\nCom apenas ", length(datas), " sessoes de orientacao (amostra) e o join por ",
  "data+partido (ver ACHADO acima), estes numeros sao uma aproximacao -- a comparacao ",
  "coesao (Indice de Rice, aula 1) x disciplina (aqui) fica mais robusta com o universo ",
  "completo de sessoes do ano E com a chave de votacao especifica corrigida no pacote."
)
