# Exemplo aplicado: ranking de emendas (PL 2338/2023)

Este é o "exemplo extra" da oficina `senatebR` (ver [`curso_senatebR/README.md`](../curso_senatebR/README.md)) — um caso construído *neste mesmo projeto*, antes do curso ter sido organizado, que aplica exatamente o método ensinado nas quatro aulas a uma pergunta que as 36 funções do pacote não cobrem.

## A pergunta

Qual foi o volume de interesse parlamentar — medido em número de emendas — pelo PL 2338/2023 (Marco Legal da Inteligência Artificial), e como ele se compara a outros projetos de lei que passaram pelo mesmo processo em 2023?

## Por que ele não usa o `senatebR`

A oficina é explícita sobre isso (slide 8): o pacote é "uma camada entre a infraestrutura de dados do Senado e a pergunta que o pesquisador quer responder" — não um catálogo fechado. As 36 funções do `senatebR` cobrem senadores, comissões, matérias, votações, discursos, agenda/vetos/MPs e partidos — mas **nenhuma delas retorna emendas de uma matéria**. Esse é exatamente o tipo de lacuna que a Aula 3 nomeia (slide 26, "o que a API não entrega") e que o Lab 2 desta pasta do curso encontra de novo com o próprio caso da oficina (PL 2.630/2020 também não aparece em `materias_legislatura_atual()`, pela mesma razão institucional: já saiu do Senado).

## O pipeline (já existente neste projeto, não duplicado aqui)

| Arquivo | Papel no método da oficina (API → JSON → tabela → indicador → evidência) |
|---|---|
| [`R/materia_lookup.R`](../R/materia_lookup.R) | Resolve "PL 2338/2023" → `Codigo` interno — a mesma função reaproveitada em [`curso_senatebR/01_caso_da_oficina.R`](../curso_senatebR/01_caso_da_oficina.R) para resolver o PL 2.630/2020 |
| [`R/emendas_fetch.R`](../R/emendas_fetch.R) | Coleta (com cache em disco) as emendas da matéria via o endpoint legado `materia/emendas/{codigo}` |
| [`R/ranking_autores.R`](../R/ranking_autores.R) | Transforma a tabela bruta em indicador: ranking de autores por nº de emendas |
| [`R/comparacao_materias.R`](../R/comparacao_materias.R) | Constrói o grupo de comparação (PLs de 2023 que chegaram a `APROVADA_NO_PLENARIO`) e calcula posição/percentil — reaproveitado também em [`curso_senatebR/aula_03_processo_legislativo/lab2_tramitacao_do_caso_gabarito.R`](../curso_senatebR/aula_03_processo_legislativo/lab2_tramitacao_do_caso_gabarito.R) para medir dias de tramitação, não emendas |
| [`scripts/01_lookup_pl2338.R`](../scripts/01_lookup_pl2338.R) … [`scripts/05_ranking_comparativo.R`](../scripts/05_ranking_comparativo.R) | Pipeline executável de ponta a ponta, na ordem |

Rodar (a partir da raiz do projeto): `Rscript scripts/01_lookup_pl2338.R`, depois `02`, `03`, `04`, `05`, em ordem.

## O resultado (obtido antes do curso ser organizado, 2026-09-17)

- **244 emendas** ao PL 2338/2023 na fase Senado.
- Top autor: **Mecias de Jesus (Republicanos-RR)**, com 41 emendas.
- Comparado a 110 PLs de 2023 que também chegaram a "aprovado em Plenário", o PL 2338 ficou em **1º lugar** (percentil 100) — outlier claro; a mediana do grupo foi de apenas 1 emenda por projeto.

Detalhes completos, ressalvas metodológicas (escopo só-Senado, endpoint legado, escolha do grupo de comparação) e os dados brutos estão em [`README.md`](../README.md) e [`data/processed/`](../data/processed/).

## A lição para quem está fazendo o curso

Você não precisa que uma das 36 funções exista para aplicar o método. `buscar_codigo_materia()` e `buscar_cohort_deliberacao()` — construídos aqui para o problema de emendas — são a prova de que "API → JSON → tabela → indicador → evidência" (slide 8) funciona mesmo quando você tem que escrever a chamada `httr`/`jsonlite` você mesmo, exatamente como a Aula 1 mostra "sem `senatebR`" no slide 13. O pacote economiza esse trabalho onde ele já existe; o método é o que você usa onde ele ainda não existe.
