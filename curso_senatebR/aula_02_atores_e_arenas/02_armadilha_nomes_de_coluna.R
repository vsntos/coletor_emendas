# ============================================================
# Script: 02_armadilha_nomes_de_coluna.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 2, "a armadilha n. 1" (slide 25) -- os nomes de coluna
#          vem do XML da API, nao sao escolha do pacote. O mesmo codigo de
#          parlamentar aparece com tres grafias diferentes dependendo do
#          endpoint: CodigoParlamentar, Votos.CodigoParlamentar,
#          Codigo_Parlamentar. Regra da sala: rode names()/glimpse() antes
#          de qualquer pipeline, sem excecao.
# Inputs: curso_senatebR/dados/senadores_57.rds (de 01_coleta_responsavel.R)
# Outputs: none (script de demonstracao)
# ============================================================

library(senatebR)
library(dplyr)

senadores_bruto <- readRDS(here::here("curso_senatebR/dados/senadores_57.rds"))

# o que chega
message("Antes do rename_with():")
print(names(senadores_bruto)[1:4])
#> "IdentificacaoParlamentar.CodigoParlamentar"
#> "IdentificacaoParlamentar.NomeParlamentar"
#> "IdentificacaoParlamentar.SiglaPartidoParlamentar"
#> "IdentificacaoParlamentar.UfParlamentar"

# tirar o prefixo herdado da hierarquia do XML
senadores <- senadores_bruto |>
  dplyr::rename_with(~ gsub("IdentificacaoParlamentar\\.", "", .x))

message("Depois do rename_with():")
print(names(senadores)[1:4])
#> "CodigoParlamentar"  "NomeParlamentar"
#> "SiglaPartidoParlamentar"  "UfParlamentar"

# e cuidado: cada endpoint usa a sua propria convencao
#   votacoes       -> Votos.CodigoParlamentar
#   pronunciamentos -> Codigo_Parlamentar
#   comissoes      -> CodigoParlamentar
#
# Por isso todo left_join() desta oficina declara by = c("A" = "B")
# explicitamente. Join por nome igual so funciona por sorte.
