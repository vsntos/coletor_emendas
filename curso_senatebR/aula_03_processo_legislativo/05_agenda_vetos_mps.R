# ============================================================
# Script: 05_agenda_vetos_mps.R
# Author: Vinicius Santos
# Date: 2026-09-17
# Purpose: Aula 3, "o Legislativo no presente" (slide 42) -- monitoramento.
#          Veto e decisao legislativa: uma lei aprovada e vetada em parte
#          nao e a lei que o Senado votou. MP e o Executivo legislando:
#          medir producao legislativa sem MPs superestima o Congresso como
#          origem da lei. Estas quatro funcoes deixam de descrever o
#          passado e passam a acompanhar o presente -- o bloco mais util
#          para jornalismo de dados das quatro aulas.
# Inputs: none
# Outputs: none (script de demonstracao)
# ============================================================

library(senatebR)

hoje <- Sys.Date()

# o que esta pautado hoje (info_agenda exige anos/meses/dias explicitos)
agenda <- info_agenda(
  anos = as.integer(format(hoje, "%Y")),
  meses = as.integer(format(hoje, "%m")),
  dias = as.integer(format(hoje, "%d"))
)
message(nrow(agenda), " itens de agenda para hoje (", hoje, ").")

# vetos presidenciais e seus detalhes
vetos <- info_vetos()
message(nrow(vetos), " vetos no catalogo mais recente.")

detalhes <- extrair_detalhes_vetos(urls = utils::head(vetos$Link, 3))
base_vetos <- dados_vetos(urls = utils::head(vetos$Link, 3))
message(nrow(detalhes), " detalhes de veto obtidos (amostra de 3 urls, ",
        "para nao sobrecarregar o servidor de congressonacional.leg.br).")

# o Executivo legislando
mps_ativas <- coletar_medidas_provisorias_em_tramitacao()
mps_fim <- coletar_medidas_provisorias_encerradas(numero_ultima_pagina = 1)
message(nrow(mps_ativas), " MPs em tramitacao; ", nrow(mps_fim),
        " MPs encerradas na primeira pagina do catalogo.")

# Para jornalismo de dados, este e o bloco mais util das quatro aulas: um
# script que roda toda segunda-feira e avisa o que entrou na pauta.
