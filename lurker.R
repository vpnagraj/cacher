###############################
# lurk

# what is the name of the db for the jobs
db_url <- "mongodb://localhost:27017"
db_name <- "low2"

# where do the caches live?
cache_dir <- "cache/"

# establish connection to jobdb
con <- shinyqueue::connect(db_url = db_url, db_name = db_name)

# write process function(s)

runit <- function(size, dist) {
  
  Sys.sleep(15)
  
  switch(dist,
         "Gaussian" = rnorm(size),
         "Uniform" = runif(size),
         "Cauchy" = rcauchy(size)
  )
  
}

cache_it <- function() {
  
  dat <- runit(size = unlist(input$size),
                 dist = unlist(input$dist))
  
  return(dat)
  
}


shinyqueue::lurk(process = list("cacher" = cache_it()), 
                 con = con,
                 cache_dir = cache_dir)
