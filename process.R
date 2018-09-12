################################
# process function
runit <- function(size, dist) {
  
  Sys.sleep(30)
  
  switch(dist,
         "Gaussian" = rnorm(size),
         "Uniform" = runif(size),
         "Cauchy" = rcauchy(size)
  )
  
}

res <- runit(size = unlist(inprocess$size), 
             dist = unlist(inprocess$distribution))

res <- res^2