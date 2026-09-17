# Oficina senatebR — código organizado para rodar

Material da oficina "Da pergunta política à evidência legislativa" (4 aulas + 3 laboratórios
sobre o pacote R [`senatebR`](https://github.com/vsntos/senatebR)), extraído dos slides e
reorganizado em scripts que rodam de verdade neste projeto, contra a API real do Senado Federal
— nenhum bloco aqui é pseudocódigo.

**Livro de apoio:** SANTOS, Vinicius. *senatebR: Coletando e Analisando Dados do Senado Federal
Brasileiro*. Disponível em `vsntos.github.io/senatebR-curso`.

## Como rodar

A partir da raiz do projeto (`coletor_emendas/`), nesta ordem:

1. `Rscript curso_senatebR/00_setup.R` — instala dependências e testa a conexão com a API.
2. `Rscript curso_senatebR/01_caso_da_oficina.R` — resolve o caso que atravessa a oficina
   (PL 2.630/2020) para o `Codigo` interno do Senado.
3. Dentro de cada `aula_0N_*/`, os scripts são numerados e devem rodar em ordem — cada um assume
   que o anterior já rodou e salvou seus dados em `curso_senatebR/dados/`.

Os `.rds` gerados ficam em `curso_senatebR/dados/`, os `.png` em `curso_senatebR/figuras/` —
ambos ignorados pelo git (são artefatos derivados, reproduzíveis a partir dos scripts).

## Estrutura (4 aulas, 3 laboratórios)

| Aula | Tema | Laboratório |
|---|---|---|
| 1 · [`aula_01_pergunta_antes_da_ferramenta/`](aula_01_pergunta_antes_da_ferramenta/) | O caso, o mapa do pacote (36 funções, 7 categorias), o jogo completo | — (demonstração, sem lab) |
| 2 · [`aula_02_atores_e_arenas/`](aula_02_atores_e_arenas/) | Coleta responsável, armadilha de nomes de coluna, senadores, comissões | **Lab 1** (20 min) — [gabarito](aula_02_atores_e_arenas/lab1_composicao_e_poder_gabarito.R) |
| 3 · [`aula_03_processo_legislativo/`](aula_03_processo_legislativo/) | Chaves e joins, matérias e tramitação, discursos, agenda/vetos/MPs | **Lab 2** (20 min) — [gabarito](aula_03_processo_legislativo/lab2_tramitacao_do_caso_gabarito.R) |
| 4 · [`aula_04_decisao_e_evidencia/`](aula_04_decisao_e_evidencia/) | Votação nominal, coesão × disciplina, índice de atividade, redes, comunicação visual | **Lab 3** (25 min) — [gabarito](aula_04_decisao_e_evidencia/lab3_similaridade_de_voto_gabarito.R) |

Os labs têm **gabarito resolvido** (não apenas um esqueleto com TODOs) — cada um segue
literalmente a "trilha obrigatória" descrita nos slides, mas com o código completo e testado.

## O caso que atravessa a oficina

**PL 2.630/2020** (regulação de plataformas digitais / "Lei das Fake News"), aprovado pelo Senado
em 2020 e remetido à Câmara dos Deputados a partir dali. `01_caso_da_oficina.R` resolve esse
caso reaproveitando `R/materia_lookup.R::buscar_codigo_materia()` — já existente na raiz deste
projeto — porque **o `senatebR` não tem uma função de busca de matéria por sigla/número/ano**;
todas as suas 36 funções recebem um `Codigo` já resolvido. Essa mesma lacuna reaparece no Lab 2
(o caso não está em `materias_legislatura_atual()`, porque já saiu do Senado) e é resolvida ali
reaproveitando `R/comparacao_materias.R::buscar_cohort_deliberacao()`.

## Exemplo aplicado extra: ranking de emendas

Ver [`exemplos_aplicados/ranking_de_emendas.md`](../exemplos_aplicados/ranking_de_emendas.md).
O pipeline de ranking de emendas do PL 2338/2023, já existente neste projeto antes deste curso
ser organizado, é um segundo estudo de caso real: aplica o mesmo método ("API → JSON → tabela →
indicador → evidência", slide 8) a uma pergunta que nenhuma das 36 funções do `senatebR` cobre
(emendas de uma matéria). Não foi duplicado aqui — os scripts originais continuam em `R/` e
`scripts/` na raiz do projeto.

## Achados ao vivo durante a organização deste material (2026-09-17)

Rodar os slides contra a API real revelou algumas divergências entre o que os slides descrevem e
o comportamento atual do pacote/API — documentadas nos próprios scripts onde aparecem, no
espírito de "honestidade metodológica" da própria oficina (slide 26):

- `dados_comissoes()` retornou 0 linhas no momento do teste
  ([`aula_02/04_arenas_comissoes.R`](aula_02_atores_e_arenas/04_arenas_comissoes.R)).
- `processar_xml_apartes()` rejeita o `CodigoParlamentar` do senador com "Código inválido ou
  muito longo" ([`aula_03/04_discursos.R`](aula_03_processo_legislativo/04_discursos.R)).
- `coletar_autorias_parlamentares()` não retorna pares de coautoria de matéria, apesar do nome —
  a documentação do próprio pacote confirma que ela devolve dados de **comissão**, não de
  autoria de matéria ([`aula_04/05_rede_de_coautoria.R`](aula_04_decisao_e_evidencia/05_rede_de_coautoria.R)).
- `CodigoSessaoVotacao` (de `extrair_votacoes_nominais_por_ano()`) e `codigo_votacao` (de
  `coletar_orientacao_votacao()`) não compartilham o mesmo espaço de códigos, mesmo para a
  mesma sessão/data — o join do slide 49 como descrito produz 0 linhas
  ([`aula_04/03_coesao_vs_disciplina.R`](aula_04_decisao_e_evidencia/03_coesao_vs_disciplina.R)).

Nenhum desses achados invalida o método ensinado — são exatamente o tipo de "o que a API não
entrega" que a Aula 3 pede para registrar como parte do resultado, não para esconder.

## Site do curso (Quarto book)

Este mesmo material também existe como um site navegável — um projeto Quarto do tipo `book`
(`_quarto.yml`), com um capítulo por script (cada `.qmd` só referencia o `.R` correspondente via
`{r, file="..."}`, sem duplicar código — editar o script atualiza o site no próximo render).

```bash
cd curso_senatebR
quarto render          # gera _book/ localmente, para conferir antes de publicar
quarto preview         # abre no navegador com live-reload
```

Para compartilhar com os alunos, publique com a sua própria conta:

```bash
quarto publish gh-pages     # GitHub Pages (precisa de um repositório git com remoto no GitHub)
# ou
quarto publish quarto-pub   # Quarto Pub (só precisa de uma conta gratuita, sem GitHub)
```

`execute: freeze: auto` (no `_quarto.yml`) cacheia os resultados de execução contra a API real —
renders futuros só recomputam um capítulo se o `.R`/`.qmd` fonte dele mudar, o que evita bater na
API do Senado a cada `quarto render`/`quarto publish`.

## Requisitos

R ≥ 4.1, pacotes `senatebR`, `tidyverse`, `lubridate`, `gt`, `igraph`, `ggraph`, `geobr` (todos
instalados via `00_setup.R`), Quarto (para `aula_04_decisao_e_evidencia/relatorio_exemplo.qmd`),
conexão aberta com `legis.senado.leg.br`.
