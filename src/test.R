# Restart
rm(list=ls())
#.rs.restartR()

# Set working directory
setwd("D:/Koodaus/EclipseWS/ASOT/src/")

# Run scripts
source("global.R")
source("ui.R")
source("server.R")

# Run app
runApp()
