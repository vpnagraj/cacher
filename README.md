# `cacher`

This repository includes a trivial Shiny app for asynchronous job submission / retrieval. The app submits a job to a queue (managed by a running Mongo DB) ... in the meantime, a script (see `lurker.R`) is running is a separate R process, watching the DB for new jobs. When a job (or jobs) appear in the queue, this script executes an arbitary process function (or functions) with the parameters stored in the DB.

To run this example, make sure you have a Mongo DB installed:

<https://docs.mongodb.com/manual/installation/>

The DB should be running at `mongodb://localhost:27017`

R package dependencies include `shiny` (for the web app) and `mongolite` (for the R Mongo DB client).

```
install.packages("shiny")
install.packages("mongolite")
```

You'll also need the [shinyqueue](https://github.com/databio/shinyDepot) package installed.
