# load mongolite
library(mongolite)

# establish connection
con <- mongo(db = "low2")

while(TRUE) {Sys.sleep(5); print(con$find()[,-4])}
