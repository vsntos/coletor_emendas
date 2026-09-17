# Plan: Site Quarto para o curso senatebR (compartilhável com alunos)
**Date:** 2026-09-17
**Status:** APPROVED

## Context

O usuário quer transformar o material já organizado em `curso_senatebR/` (4 aulas + 3 labs,
~21 scripts `.R` verificados contra a API real do Senado) em um site que possa compartilhar com
os alunos. Duas decisões já foram tomadas com o usuário via pergunta de esclarecimento:

- **Hospedagem: Quarto Pub / GitHub Pages.** Eu monto o projeto Quarto pronto para publicar; o
  usuário roda o comando de publicação (`quarto publish`) com a própria conta — não uso o
  Artifact tool do Claude para isso.
- **Profundidade: só código comentado.** Cada página do site mostra o script real (com os
  comentários que já existem nele — propósito, achados ao vivo, decisões metodológicas), não uma
  reconstrução da narrativa completa dos slides.

## Abordagem: Quarto **book**, chunks por `file=`, sem duplicar código

Um projeto Quarto do tipo `book` (não `website` genérico) encaixa bem na estrutura existente:
aulas viram `part:`, cada script vira um capítulo curto, e os 3 labs fecham cada parte
correspondente — o mesmo desenho de "Aula 1..4" já usado em `curso_senatebR/README.md`.

**Decisão central para respeitar "single source of truth" (regra do usuário):** cada capítulo
`.qmd` NÃO copia o código do script para dentro do arquivo. Em vez disso, usa a opção de chunk do
knitr `file = "caminho/para/script.R"`, que lê e executa o `.R` já existente como se fosse o
conteúdo do chunk. Os `.R` em `curso_senatebR/aula_0N_*/` continuam sendo a única fonte do
código — o `.qmd` é só um wrapper fino (título + 1 frase de contexto + o chunk apontando pro
`.R`). Editar o script no futuro atualiza o site automaticamente no próximo render.

### Arquivos a criar

```
curso_senatebR/
├── _quarto.yml                 # project: type: book; execute: freeze: auto
├── index.qmd                   # apresentação do curso (adaptado de README.md já existente)
├── 00-setup.qmd                # wrapper de 00_setup.R
├── 01-caso-da-oficina.qmd      # wrapper de 01_caso_da_oficina.R
├── references.qmd              # como citar (slide 61) + link para o livro-tutorial
├── aula_01_pergunta_antes_da_ferramenta/
│   └── demo.qmd                # wrapper de demo_jogo_completo.R
├── aula_02_atores_e_arenas/
│   ├── 01-coleta-responsavel.qmd   … 04-arenas-comissoes.qmd   (4 wrappers)
│   └── lab1.qmd                    # wrapper de lab1_composicao_e_poder_gabarito.R
├── aula_03_processo_legislativo/
│   ├── 01-chaves-e-joins.qmd … 05-agenda-vetos-mps.qmd (5 wrappers)
│   └── lab2.qmd                    # wrapper de lab2_tramitacao_do_caso_gabarito.R
├── aula_04_decisao_e_evidencia/
│   ├── 01-matriz-votacao-nominal.qmd … 06-comunicacao-visual.qmd (6 wrappers)
│   ├── lab3.qmd                    # wrapper de lab3_similaridade_de_voto_gabarito.R
│   └── relatorio-quarto.qmd        # NÃO executa relatorio_exemplo.qmd (tem format html/pdf/
│                                   #   revealjs próprio, incompatível com o book) -- explica o
│                                   #   template em 1 paragrafo e linka o arquivo fonte
└── exemplo-aplicado-emendas.qmd    # capítulo final: teaser + link para
                                     # ../exemplos_aplicados/ranking_de_emendas.md (não duplica)
```

23 wrappers no total (1 por script existente), cada um com este formato:

```markdown
---
title: "Coleta responsável"
---

Aula 2 · disciplina de projeto (slide 24) — colete uma vez, analise cem.

\`\`\`{r coleta-responsavel, file="01_coleta_responsavel.R"}
\`\`\`
```

O título e a linha de contexto vêm do `Purpose:` já escrito no cabeçalho de cada script — não é
texto novo, só reaproveitado.

### `_quarto.yml` (estrutura)

```yaml
project:
  type: book

book:
  title: "Oficina senatebR"
  subtitle: "Da pergunta política à evidência legislativa"
  author: "Vinicius Santos"
  chapters:
    - index.qmd
    - 00-setup.qmd
    - 01-caso-da-oficina.qmd
    - part: "Aula 1 · A pergunta antes da ferramenta"
      chapters: [aula_01_pergunta_antes_da_ferramenta/demo.qmd]
    - part: "Aula 2 · Atores e arenas"
      chapters: [4 wrappers..., lab1.qmd]
    - part: "Aula 3 · O processo legislativo"
      chapters: [5 wrappers..., lab2.qmd]
    - part: "Aula 4 · Decisão e evidência"
      chapters: [6 wrappers..., lab3.qmd, relatorio-quarto.qmd]
    - exemplo-aplicado-emendas.qmd
    - references.qmd

execute:
  freeze: auto   # cacheia resultados de execucao contra a API real; so re-executa quando o
                 # script/qmd fonte muda -- evita bater na API do Senado a cada render/publish

format:
  html:
    theme: cosmo
    code-fold: false
    toc: true
```

`freeze: auto` é a peça que evita que cada `quarto render`/`quarto publish` futuro (do usuário)
refaça todas as chamadas de API (incluindo o bloco de ~20 requisições de
`03_coesao_vs_disciplina.R` e a coleta de comissões de `04_arenas_comissoes.R`) — só recomputa se
o `.R`/`.qmd` fonte mudar.

### Por que não usar o Artifact tool aqui

O usuário escolheu explicitamente Quarto Pub/GitHub Pages em vez do link do Claude — então o
site fica sob a conta/domínio dele a longo prazo. Não vou publicar nada; o próprio usuário roda
`quarto publish gh-pages` (GitHub Pages) ou `quarto publish quarto-pub` (Quarto Pub) a partir de
`curso_senatebR/` quando estiver pronto para compartilhar.

## Verificação

- `cd curso_senatebR && quarto render` — deve completar sem erro, gerando `_book/` com todas as
  ~28 páginas (23 wrappers + index + setup + caso + exemplo + references), incluindo a execução
  real dos chunks (contra a API do Senado, como os scripts já rodaram individualmente nesta
  sessão).
- Abrir `_book/index.html` no browser embutido para conferir navegação (sidebar com as 4 partes),
  e checar 2-3 páginas de cada aula (incluindo os 3 labs) para confirmar que o código e o output
  aparecem corretamente.
- Confirmar que `curso_senatebR/_book/` e `curso_senatebR/.quarto/` entram no `.gitignore` (são
  build output, não devem ser versionados junto do código-fonte).
- Deixar uma seção curta em `curso_senatebR/README.md` com o comando exato de publicação
  (`quarto publish gh-pages` / `quarto publish quarto-pub`) para o usuário rodar quando quiser.
