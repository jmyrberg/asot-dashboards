# Get date range for episode range
get_episode_daterange <- function(data,min_episode,max_episode) {
  
  min_date <- data[data$episode==min_episode,"date"][1]
  max_date <- data[data$episode==max_episode,"date"][1]
  
  return(list(min_date=min_date,max_date=max_date))
  
}

# Splits text in multiple lines
wrapit <- function(text,width=30) {
  wtext <- paste(strwrap(text,width=width),collapse=" \n ")
  return(wtext)
}