# Load data
data_path <- "./data/preprocessed/df.csv"
data <- read.csv(data_path,sep=";",encoding='utf8',na.strings="",
                 colClasses = c("integer","Date","integer","integer","factor",
                                "factor","factor","logical","factor","logical",
                                "logical","logical","logical","logical","logical",
                                "logical","character"))

# Scripts shared across sessions
source("plots.R")
source("helpers.R")

