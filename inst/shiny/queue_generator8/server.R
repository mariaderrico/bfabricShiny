# bfabric8

# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# https://github.com/cpanse/bfabricShiny
#

library(bfabricShiny)
library(jsonlite)
library(httr)
library(DT)

# source("C:/Users/christian/__GitHub_clones/R/bfabric_shiny/R/ms_queue.r")
##
shinyServer(function(input, output, session) {

 # TODOO(cp):
getHPLC <- function(){list(VELOS_1='eksigent',
                       VELOS_2='eksigent',
                       G2HD_1='waters',
                       QTRAP_1='eksigent',
                       TSQ_1='eksigent',
                       TSQ_2='eksigent',
                       QEXACTIVE_2='waters',
                       QEXACTIVE_3='easylc',
                       FUSION_1='easylc',
                       FUSION_2='easylc',
                       QEXACTIVEHF_1='waters',
                       QEXACTIVEHF_2='waters',
                       IMSTOF_1='eksigent')}


  getInstrument <- reactive({list(VELOS_1='Xcalibur',
                       VELOS_2='Xcalibur',
                       G2HD_1='MassLynx',
                       QTRAP_1='Xcalibur',
                       TSQ_1='Xcalibur',
                       TSQ_2='Xcalibur',
                       QEXACTIVE_2='Xcalibur',
                       QEXACTIVE_3='Xcalibur',
                       FUSION_1='Xcalibur',
                       FUSION_2='Xcalibur',
                       QEXACTIVEHF_1='Xcalibur',
                       QEXACTIVEHF_2='Xcalibur',
                       IMSTOF_1='TOFWERK')})
  
  
  getInstrumentSuffix <- reactive({list(VELOS_1='RAW',
                                  VELOS_2='RAW',
                                  G2HD_1='wiff',
                                  QTRAP_1='wiff',
                                  TSQ_1='RAW',
                                  TSQ_2='RAW',
                                  QEXACTIVE_2='raw',
                                  QEXACTIVE_3='raw',
                                  FUSION_1='raw',
                                  FUSION_2='raw',
                                  QEXACTIVEHF_1='raw',
                                  QEXACTIVEHF_2='raw',
                                  IMSTOF_1='h5')})
  
  output$area <- renderUI(({
    res.area <- c("Proteomics", "Metabolomics")
    selectInput('area', 'Area:', res.area, multiple = FALSE, selected = res.area[1])
  }))
  
  output$folder <- renderUI(({
      textInput('folder', 'Data Folder Name:', "enter your folder name here", width = NULL, placeholder = NULL)
  }))
  
  output$qctype <- renderUI(({
    selectInput('qctype', 'Type of sample QC:', 
                choices = list("autoQC01" = 1, "autoQC01 and clean" = 2, "autoQC01 and clean every second " = 3), 
                selected = 1)
  }))
  
  output$testmethods <- renderUI(({
    res.testmethods <- 1:5
    selectInput('testmethods', 'Number of methods to test:', res.testmethods, multiple = FALSE, selected = res.testmethods[1])
  }))
  
  output$replicates <- renderUI(({
    res.replicates <- 1:9
    selectInput('replicates', 'Number of injections for each method:', res.replicates, multiple = FALSE, selected = res.replicates[1])
  }))
  
  output$project <- renderUI({
    res.project <- c(NA, 1000, 1959, 2121)
    numericInput('project', 'Project:', value = 1000,  min = 1000, max = 2500, width=100)
  })
  
  output$howoften <- renderUI({
    res.howoften <- 1:8
    selectInput('howoften', 'Insert QC sample every:', res.howoften, multiple = FALSE, selected = res.howoften[1])
  })
  
  output$howmany <- renderUI({
    res.howmany <- 1:5
    selectInput('howmany', 'Number of QC samples inserted:', res.howmany, multiple = FALSE, selected = 1)
  })
  
  output$instrument <- renderUI({
    res.instrument <- names(getInstrument())
    selectInput('instrument', 'Instrument:', res.instrument, multiple = FALSE, selected = res.instrument[1])
  })
  

  output$method <- renderUI(({
    selectInput('method', 'Queue Method:', c('default', 'random', 'blockrandom', 'testing'), multiple = FALSE, selected = 'default')
  }))
  
  output$showcondition <- renderUI(({
        checkboxInput('showcondition', 'Insert condition into sample name:', value = FALSE)
  }))
  
  output$hubify <- renderUI(({
    checkboxInput('hubify', 'hubify', value = TRUE)
  }))
  
  getSample <- reactive({
    if (is.null(input$project)){
      return (NULL)
    }else{
      sampleURL <- paste("http://localhost:5000/projectid/", 
                         input$project, sep='')

     
      res <- as.data.frame(fromJSON(sampleURL))
      message(paste('got', nrow(res), 'samples.'))
      return (res)
    }
    })
  getLogin <- reactive({
    if (is.null(input$project)){
      return (NULL)
    }else{
    res <- as.data.frame(fromJSON(paste("http://localhost:5000/user/", 
                                        input$project, sep='')))
    message(paste('got', nrow(res), 'users.'))
    return (res$user)
    }
  })
  
  getExtracts <- reactive({
    if (is.null(input$project)){
      return (NULL)
    }else{
      extractURL <- paste("http://localhost:5000/extract/", input$project, sep='')
      res <- as.data.frame(fromJSON(extractURL ))
      message (paste('got', nrow(res), 'extracts from url', extractURL))
      res[, "project.id"] <- input$project
      if (!"extract.Condition" %in% names(res)){
        res[, "extract.Condition"] <- "A" #res$sampleid
      }
      res <- res[order(res$extract.id, decreasing = TRUE),]
    }
    return (res)
  })
  
  output$sample <- renderUI({
    res <- getSample()
    if (is.null(res)){
      selectInput('sample', 'Sample:', NULL)
    }else{
      res <- getSample()
      selectInput('sample', 'Sample:', paste(res$sample.id, res$sample.name, sep='-'), multiple = TRUE)
    }
  })
  output$login <- renderUI({
    res <- getLogin()
    if (!is.null(res)){
      selectInput('login', 'Login:', as.character(res), multiple = FALSE)
    }else{
      selectInput('login', 'Login:', NULL)
    }
  })
  output$extract <- renderUI({
    res <- getExtracts()
    if (!is.null(res)){
      selectInput('extract', 'Extract:', res$extract.name, multiple = TRUE, selectize = TRUE)  
      #selectInput('extract', 'Extract:', res$extract.name, multiple = TRUE, size = 50 , selectize=FALSE)  #would require an alphabetic sorting of the extracts prior to populate the list
    }   else{
      selectInput('extract', 'Extract:', NULL)
     
    }
  })
  
  
  getResourcename <- reactive({
    paste("fgcz-queue-generator_p", input$project, "_", input$instrument, "_", format(Sys.time(), "%Y%m%d"), ".csv", sep='')
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      getResourcename()
    },
    content = function(file) {
      write.csv(cat("Bracket Type=4\r\n", file = file, append = FALSE))
      res <- getBfabricContent()
       write.table(res, file = file, 
                  sep=',', row.names = FALSE, 
                  append = TRUE, quote = FALSE, eol='\r\n')
       
       
       ########################## WRITE CSV TO BFABRIC
       fn <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".csv")
       print (fn)
       write.csv(cat("Bracket Type=4\r\n", file = fn, append = FALSE))
       write.table(res, file = fn, 
                   sep=',', row.names = FALSE, 
                   append = TRUE, quote = FALSE, eol='\r\n')
       
       file_content <- base64encode(readBin(fn, "raw", file.info(file)[1, "size"]), 'csv')
  
        rv <- POST("http://localhost:5000/add_resource",
                   body = toJSON(list(base64=file_content, 
                                      projectid=input$project, 
                                      workunitdescription = paste("The spreadsheet contains a ", input$instrument,
                                                                  " queue configuration having ", nrow(res), " rows.",
                                                                  "The resource was generated by using the R package bfabricShiny version ",
                                                                  packageVersion('bfabricShiny'), ".", sep=''),
                                      resourcename = getResourcename())
                               ))
       
       print (rv)
       ########################## WRITE CSV TO BFABRIC
    }
  )
  
  datasetID <- observeEvent(input$bfabricButton, {
    
    S <- getBfabricContent()
    if (nrow(S) > 0){
      rv <- POST(paste("http://localhost:5000/add_resource", 
                       input$project, sep='/'), body = toJSON(getBfabricContent()))
      
      observe({
        session$sendCustomMessage(type = 'testmessage', message = 'try to commit as dataset to bfabric.') 
      })
    }else{
      #session$sendCustomMessage(type = 'testmessage', message = 'not enough lines.') 
    }
    
  })
  
  
  getBfabricContent <- reactive({

    res <- getExtracts()
#    save(res, file='tmpResults.RData', compression_level = )
    	res[, "instrument"] <- input$instrument
#      save(res, file='tmpResults2.RData', compression_level = ) for troubleshooting only
    	
      # TODO(cp): check of extract names are unique
    	idx <- res$extract.name %in% input$extract
#    	write(idx, file = 'idx.txt') for troubleshooting only
#    	selected.order <- input$extract for troubleshooting only
#    	write(selected.order, file = 'iorder.txt') for troubleshooting only

    	    	res <- res[idx, c("extract.name", "extract.id", "extract.Condition")]
    	    	print (res)
    	res <- res[match(input$extract, res$extract.name),]
    	
    	if(any(is.na(res$extract.Condition))){
    	res$extract.Condition[is.na(res$extract.Condition)] <- "A"
    	} else{
    	  
    	}
    	
    	idx.hplc <- getHPLC()[[input$instrument]]
    
    	rv <- generate_queue(x = res, #[idx, c("extract.name", "extract.id", "extract.Condition")], uncomment to get original prior 17.01.2017
                           foldername = input$folder,
                           projectid=input$project,
                           area = input$area,
                           instrument = input$instrument,
                           username = input$login,
                           hplc = idx.hplc,
                           how.often = as.integer(input$howoften),
                           how.many = as.integer(input$howmany),
                           nr.methods = as.integer(input$testmethods),
                           nr.replicates = as.integer(input$replicates),
                           showcondition = input$showcondition,
                           qc.type = as.integer(input$qctype),
                           method = as.character(input$method))
    	
#    	save(rv, file='queue.RData', compression_level = ) for trouble shooting only
#    	rv
    	#cbind(rv, extract.id = res[idx, 'extract.id'])
  })
  
  
  
  output$table <- DT::renderDataTable(DT::datatable({
    #print(paste("extract", input$extract, sep='='))

      if (input$extract != "" && length(input$extract) >= 1){
      getBfabricContent()
    }else{
      #as.data.frame(list(extract.name=NA, sampleid=NA, extract.id=NA))
      as.data.frame(list(output="no data - select extracts first."))
    }
    
    }))

})
