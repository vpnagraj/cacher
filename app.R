library(shiny)
library(mongolite)

# what is the name of the db for the jobs
db_url <- "mongodb://localhost:27017"
db_name <- "low"

# where do the caches live?
cacheDir <- "cache/"

# establish connection to jobdb
con <- shinyDepot::connect(db_url = db_url, db_name = db_name)

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

    shinyDepot::hash()

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
  
  query <- shinyDepot::parse_query()
  
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
  
  # retrieve job
  shinyDepot::retrieve(db_url = db_url, db_name = db_name)
  
  output$distPlot <- renderPlot({
    
    req(dat$status == "Completed")
    
    hist(dat$rdist)
    
  })
  
  output$badquery <- renderText({
    
    req(dat$bad)
    
    dat$bad
    
  })
  
  output$qmessage <- renderText({
    
    req(dat$status == "Queued" | dat$status == "Running")
    
    dat$status
    
  })

}

shinyApp(ui = ui, server = server)