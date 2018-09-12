###############################
# lurk
# load mongodb client and connect to db
library(mongolite)
con <- mongo(url = "mongodb://localhost:27017", db = "low")

# source("process.R")

running <- TRUE

while(running) {
  
  # check queue depth
  queued <- '{"status":"Queued"}'
  qdepth <- con$count(queued)
  
  if (qdepth > 0) {
    
    for (i in 1:qdepth) {
      
      # get job at iterator
      inprocess <- con$find(queued)[i,]
      
      # get id json string for updating db
      idstr <- paste0("{\"id\":\"", inprocess$id, "\"}")
      
      # message
      message(paste0("running job ", inprocess$id))
      
      # set status to running
      con$update(idstr,
                 update = '{"$set":{"status":"Running"}}')
      
      # run the process function
      # res <- runit(size = unlist(inprocess$size), 
      #              dist = unlist(inprocess$distribution))
      
      source("process.R", local = TRUE)
      
      # create file pointer and save cache
      fp <- paste0("cache/", inprocess$id, ".rds")
      saveRDS(res, file = fp)
      
      # set status to completed
      con$update(idstr, 
                 update = '{"$set":{"status":"Completed"}}')
      
      # check queue depth
      qdepth <- con$count(queued)
      
    }
    
  } else {
    
    # print message, write to log, etc
    message("waiting for next job ... ")
    # wait a moment  ...
    Sys.sleep(10)
    # check if there's a new job yet
    qdepth <- con$count(queued)
    
  }
}