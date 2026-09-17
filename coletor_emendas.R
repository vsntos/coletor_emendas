# Carregar os pacotes necessários
library(shiny)
library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)
library(pdftools)
library(stringr)

# Função para coletar e combinar dados de emendas para múltiplos códigos de projetos
coletar_emendas <- function(codigos_projetos) {
  obter_dados_emendas <- function(codigo_projeto) {
    url <- paste0("https://legis.senado.leg.br/dadosabertos/materia/emendas/", codigo_projeto, "?formato=json")
    response <- GET(url)
    
    # Verifica se a requisição foi bem-sucedida
    if (status_code(response) != 200) {
      stop("Erro ao acessar os dados do projeto: ", codigo_projeto)
    }
    
    content_json <- content(response, "text", encoding = "UTF-8")
    json_data <- fromJSON(content_json, flatten = TRUE)
    
    emendas <- json_data$EmendaMateria$Materia$Emendas$Emenda
    df_emendas <- as.data.frame(emendas) %>%
      mutate(CodigoProjeto = codigo_projeto)
    
    return(df_emendas)
  }
  
  df_emendas_combined <- tryCatch({
    lapply(codigos_projetos, obter_dados_emendas) %>%
      bind_rows() %>%
      unnest_wider(AutoriaEmenda.Autor, names_sep = "_Autor") %>%
      unnest_wider(TextosEmenda.TextoEmenda, names_sep = "_Texto") %>%
      unnest_wider(Decisoes.Decisao, names_sep = "_Decisao") %>%
      mutate(across(where(is.list), ~ map_chr(., ~ paste(unlist(.), collapse = ", "))))
  }, error = function(e) {
    NULL  # Retorna NULL em caso de erro
  })
  
  return(df_emendas_combined)
}

limpar_texto <- function(texto) {
  texto %>%
    str_squish() %>%
    str_replace_all("\\*|\\-|\\.|\\n", "") %>%
    str_replace_all("\\s+", " ") %>%
    str_replace_all("(?i)(\\bpara verificar as assinaturas, acesse\\b).*", "") %>%
    str_trim()
}

# Funções para extrair ementa e justificativa
extrair_ementa <- function(texto) {
  pos_inicio <- str_locate(texto, "EMENDA Nº")[1, 1]
  ementa <- str_sub(texto, pos_inicio)
  pos_fim <- str_locate(ementa, "JUSTIFICAÇÃO")[1, 1]
  if (!is.na(pos_fim)) {
    ementa <- str_sub(ementa, 1, pos_fim - 1)
  }
  return(str_trim(ementa))
}

extrair_justificativa <- function(texto) {
  pos_inicio <- str_locate(texto, "JUSTIFICAÇÃO")[1, 1]
  justificativa <- str_sub(texto, pos_inicio)
  return(str_trim(justificativa))
}

# Interface do Usuário
ui <- fluidPage(
  titlePanel("Coletor de Emendas"),
  sidebarLayout(
    sidebarPanel(
      textInput("codigos", "Insira os códigos de projetos (separados por vírgula):"),
      actionButton("coletar", "Coletar Emendas"),
      downloadButton("download_data", "Baixar Planilha")
    ),
    mainPanel(
      tableOutput("tabela_emendas"),
      textOutput("mensagem_erro")  # Adiciona um espaço para mensagens de erro
    )
  )
)

# Lógica do Servidor
server <- function(input, output, session) {
  dados_emendas <- reactiveVal(NULL)
  mensagem_erro <- reactiveVal(NULL)  # Para armazenar a mensagem de erro
  
  observeEvent(input$coletar, {
    req(input$codigos)  # Verifica se o input não está vazio
    codigos_projetos <- unlist(strsplit(input$codigos, ",")) %>% trimws()
    
    # Limpa mensagem de erro anterior
    mensagem_erro(NULL)
    
    df_emendas <- coletar_emendas(codigos_projetos)
    
    if (is.null(df_emendas)) {
      mensagem_erro("Não foi possível coletar os dados. Verifique os códigos dos projetos.")
      return()  # Sai da função se a coleta falhar
    }
    
    # Extraindo texto dos PDFs e limpando
    df_emendas$texto <- NA
    for (i in 1:nrow(df_emendas)) {
      url_pdf <- df_emendas$TextosEmenda.TextoEmenda_TextoUrlTexto[i]
      
      # Verifica se a URL é válida
      if (is.na(url_pdf) || url_pdf == "") {
        mensagem_erro(paste("URL inválida para o projeto:", df_emendas$CodigoProjeto[i]))
        next  # Pula para a próxima iteração do loop
      }
      
      pdf_file <- tempfile(fileext = ".pdf")
      download.file(url_pdf, pdf_file, mode = "wb", quiet = TRUE)
      texto_pdf <- pdf_text(pdf_file)
      df_emendas$texto[i] <- paste(texto_pdf, collapse = "\n")
      unlink(pdf_file)
    }
    
    df_emendas$texto_limpo <- limpar_texto(df_emendas$texto)
    df_emendas$ementa_extraida <- sapply(df_emendas$texto_limpo, extrair_ementa)
    df_emendas$justificativa_extraida <- sapply(df_emendas$texto_limpo, extrair_justificativa)
    
    dados_emendas(df_emendas)
  })
  
  output$tabela_emendas <- renderTable({
    req(dados_emendas())
    dados_emendas()
  })
  
  output$download_data <- downloadHandler(
    
    filename = function() {
      paste("emendas_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(dados_emendas(), file, row.names = FALSE)
    }
  )
  
  output$mensagem_erro <- renderText({
    mensagem_erro()
  })
}

# Executar o aplicativo
shinyApp(ui, server)
