# load mongolite
library(mongolite)

# establish connection
con <- mongo(db = "low")

# view queue
con$find()

admin <- mongo(db = "admin")
admin$run('{"listDatabases":1}')

while(TRUE) {Sys.sleep(5); print(con$find()[,-4])}