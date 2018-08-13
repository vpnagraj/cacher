################################
# process function
runit <- function(size, dist) {
  
  
  switch(dist,
         "Gaussian" = rnorm(size),
         "Uniform" = runif(size),
         "Cauchy" = rcauchy(size)
  )
  
  
}