library(shiny)
library(mongolite)

# what is the name of the db for the jobs
jobdb <- "low"

# where do the caches live?
cacheDir <- "cache/"

# establish connection to jobdb
con <- mongo(url = "mongodb://localhost:27017", db=jobdb)

ui <- fluidPage(
  
  navbarPage(title = "Cache",
             
             tabPanel("Run",
                      
                      tags$head(
                        tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
                        # javascript for redirect to results view
                        tags$script("Shiny.addCustomMessageHandler('redirect', 
                             function(result_url) {window.location = result_url;});")
                      ),        
                      
                      shinyjs::useShinyjs(),
                      
                      fluidRow(
                        selectInput("dist", "Distribution", choices = c("Gaussian", "Uniform", "Cauchy")),
                        sliderInput("size", "Size", min = 1e3, max = 1e5, value = 1e4),
                        actionButton("run", "Run DIST")
                      )
             ),
             tabPanel("Results",
                      
                      fluidRow(
                        textOutput("badquery"),
                        textOutput("qmessage"),
                        plotOutput("distPlot")
                      )
             ),
             id = "mainmenu",
             selected = "Results"))

server <- function(input, output, session) {
  
  keyphrase <- eventReactive(input$run, {
    
    paste0(sample(c(LETTERS,1:9), 15), collapse = "")
    
  })
  
  result_url <- reactive({
    
    baseurl <- session$clientData$url_hostname
    port <- session$clientData$url_port
    pathname <- session$clientData$url_pathname
    
    # logic to remove phantom : when running at port 80
    if (port == 80) {
      
      link <- paste0("http://", baseurl, port, pathname, "?key=", keyphrase())
      
    } else {
      
      link <- paste0("http://", baseurl, ":", port, pathname, "?key=", keyphrase())
      
    }
    
    result_url <- paste0("<a href = '", link, "' target = 'blank'>", link, "</a>")
    
    list(link = link,
         result_url = result_url)
    
  })
  
  query <- reactive({
    
    parseQueryString(session$clientData$url_search)
    
  })
  
  
  observeEvent(input$run, {
    
    # get keyphrase generated
    id <- keyphrase()
    
    jobspecs <- 
      list(
        id = id,
        status = "Queued",
        size = input$size,
        datapath = list("/tmp/foo/bar/", "/tmp/foo/baz/"),
        distribution = input$dist,
        time_queued = Sys.time(),
        time_run = NA
      )
    
    # insert row in mongodb
    con$insert(jobspecs)
    
    # show the message about redirect
    showModal(modalDialog(
      title = "Results",
      HTML(paste0("You are about to be re-directed to your results:<br>",
                  result_url()$result_url)
      )
    ))
    
    Sys.sleep(3)
    
    # initiate redirect
    session$sendCustomMessage(type = "redirect", result_url()$link)
    
  })
  
  observe({
    
    if(length(query()) == 0) {
      
      updateNavbarPage(session, "mainmenu",
                       selected = "Run")
    }
  })
  
  # set  up reactive value object to store values from observer
  dat <- reactiveValues()

  observe({
    
    # is there a query and is it in the job db?
    if(length(query()) != 0 & any(query() %in% con$find()$id)) {
      
      # construct id query string for job db
      idstr <- paste0("{\"id\":\"", query(), "\"}")
      
      # is the job done? 
      if(con$find(query = idstr)$status == "Completed") {
        
        dat$status <- "Completed"
        
        # read data
        dat$rdist <- readRDS(file = paste0(cacheDir, query(), ".rds"))
        
        # focus on results tab
        updateNavbarPage(session, "mainmenu",
                         selected = "Results")
        
        # is the job queued
      } else if(con$find(query = idstr)$status == "Queued") { 
        
        # set result object to "queued
        dat$status <- "Queued"
        
        # force refresh every X seconds
        invalidateLater(5000, session)
        
      }
      
      # and if the query is bad ... say so
    } else if (length(query() != 0)) {
      
      dat$bad <- "bad query"
      
    }
    
  })
  
  output$distPlot <- renderPlot({
    
    req(dat$status == "Completed")
    
    hist(dat$rdist)
    
  })
  
  output$badquery <- renderText({
    
    req(dat$bad)
    
    dat$bad
    
  })
  
  output$qmessage <- renderText({
    
    req(dat$status == "Queued")
    
    dat$status
    
  })

}

shinyApp(ui = ui, server = server)