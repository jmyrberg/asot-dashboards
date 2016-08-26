########################
######## PLOTS #########
########################

# Load packages
library(ggplot2)
library(grid)
library(plyr)
library(dplyr)
library(gridExtra)
library(visNetwork)

# Top 50
top50Plot <- function(data,input_var,n_tracks,min_episode,max_episode,filters) {
  
  df <- data
  
  # Input parameters
  if(input_var=="Artist") {var <- "artist"}
  else if (input_var=="Label") {var <- "label"}
  else if (input_var=='Track') {var <- "title"}
  
  if("totw" %in% filters) {df <- df[df$totw==T,]}
  if("ff" %in% filters) {df <- df[df$ff==T,]}
  if("rc" %in% filters) {df <- df[df$rc==T,]}
  if("tt" %in% filters) {df <- df[df$tt==T,]}
  if("pp" %in% filters) {df <- df[df$pp==T,]}
  if("remix" %in% filters) {df <- df[df$remix==T,]}
  
  # Data processing
  df <- df[(min_episode <= df$episode) & (df$episode <= max_episode),]
  df <- na.omit(count_(df,var))
  df <- df[order(-df[,2]),]
  df <- df[1:n_tracks,]
  colnames(df) <- c("variable","freq")
  df <- transform(df, variable=reorder(variable,freq))
  levels(df$variable) <- paste0(seq(length(df$variable),1,-1),". ",levels(df$variable))
  
  # Plot
  p <- ggplot(df) + 
    geom_bar(aes(x=variable,y=freq),stat="identity",fill="#EC008B",width=0.7) +
    theme_light() + 
    labs(title=NULL, y=NULL, x=NULL) +
    coord_flip() +
    scale_y_continuous(expand=c(0,0)) +
    expand_limits(y=0,x=0) +
    geom_text(aes(x=variable,y=freq,label=freq),hjust=1.3,vjust=0.3,colour="white",size=4) + 
    theme(axis.text.x = element_blank(),
          axis.ticks = element_blank(),
          
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank(),
          
          axis.text.y = element_text(size=12, color="white", hjust=1, margin=margin(0,4,0,0)),
          panel.grid.major.y = element_blank(),
          panel.grid.minor.y = element_blank(),
          axis.ticks.y = element_blank(),
          
          panel.border = element_blank(),
          panel.background = element_rect(fill="#111111",color="#111111"),
          plot.background = element_rect(fill="#111111",color="#111111"),
          
          plot.margin = unit(c(0,5,5,5),"mm")
    )
  print(p)
}
#Rprof(tmp <- tempfile())
#top50Plot(data,"Track",50,1,750,NULL)
#Rprof()
#summaryRprof(tmp)


# Timeline plot
timelinePlot <- function(data,input_var,choices,tltype,acc) {
  
  df <- data
  
  # Input parameters
  if(input_var=="Artist") {var <- "artist"}
  else if (input_var=="Label") {var <- "label"}
  else if (input_var=='Track') {var <- "title"}
  
  if(tltype == "Histogram") {
    if(acc==1) {adj <- 50}
    if(acc==2) {adj <- 25}
    if(acc==3) {adj <- 10}
  } else if(tltype == "Density") {
    if(acc==1) {adj <- 1}
    if(acc==2) {adj <- 0.5}
    if(acc==3) {adj <- 0.25}
  }
  
  # Data processing
  df <- df[,c("episode",var,"date")]
  df <- df[which(df[,var] %in% choices),]
  df[,var] <- factor(df[,var])
  
  max_episode <- max(data$episode)
  brks <- c(1,seq(50,max_episode,50))
  ep2date <- unique(data[which(data$episode %in% brks),c("episode","date")])
  lbls <- paste0(ep2date$episode,"\n",format(ep2date$date,"%m/%Y"))
  
  tmp_names <- lapply(levels(df[,var]), wrapit, width=25)
  levels(df[,var]) <- unlist(tmp_names)
  
  
  # Plot
  p <- ggplot(df)
  if(tltype == "Histogram") {p <- p + 
                                  geom_bar(aes_string(x="episode",fill=var,color=var),alpha=0.6,binwidth=adj) +
                                  facet_grid(reformulate(paste(var,"~.")), scales="fixed")}
  else if(tltype == "Density") {p <- p + 
                                  geom_density(aes_string(x="episode",fill=var,color=var),alpha=0.6,trim=TRUE,adjust=adj,kernel="gaussian") +
                                  facet_grid(reformulate(paste(var,"~.")), scales="free_y")}
  p <- p + 
    geom_hline(aes(yintercept=0),color="#7d7d7d") +
    scale_x_continuous(limits=c(1,max_episode),breaks=brks,labels=lbls) +
    labs(title=NULL,y=NULL,x=NULL) +
    theme(axis.text.x = element_text(size=12, color="white", margin=margin(10,0,0,0)),
          axis.ticks.x = element_blank(),
          panel.grid.major.x = element_line(color="#7d7d7d", linetype=2),
          panel.grid.minor.x = element_blank(),
          
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.grid.minor.y = element_blank(),
          
          legend.position = "none",
          
          strip.background = element_rect(colour="white",fill="#111111"),
          strip.text.y = element_text(size=12, angle=0, color="white", margin=margin(0,10,0,10)),
          
          panel.border = element_blank(),#element_rect(color="white"),
          panel.background = element_rect(fill="#111111",color="#111111"),
          
          plot.background = element_rect(fill="#111111",color="#111111"),
          plot.margin = unit(c(2,10,10,2),"mm")
          )
  print(p)
}
#Rprof(tmp <- tempfile())
#timelinePlot(data,"Artist",c("Armin Van Buuren","Rank1"),"Density",1)
#Rprof()
#summaryRprof(tmp)
#timelinePlot(data,"Artist",c("Armin Van Buuren","Rank1",": Gaia"),"Histogram",2)



# Remix
remixNetPlot <- function(data,remixed,remixer) {
  
  # Filters from input
  remixedFilter <- which(data$artist %in% remixed)
  remixerFilter <- which(data$remixer %in% remixer)
  filter <- union(remixedFilter,remixerFilter)
  
  # Apply filters
  df <- data[filter,c("artist","remixer","title","episode")]
  df <- droplevels(na.omit(df))
  allArtists <- unique(c(levels(df$artist),levels(df$remixer)))
  df$artist <- as.numeric(factor(df$artist,levels=allArtists))
  df$remixer <- as.numeric(factor(df$remixer,levels=allArtists))
  
  remixedID <- which(allArtists %in% remixed)
  remixerID <- which(allArtists %in% remixer)
  bothID <- intersect(remixedID,remixerID)
  remixedID <- setdiff(remixedID,bothID)
  remixerID <- setdiff(remixerID,bothID)
  
  # Remix counts
  remixCounts <- count_(df,c("remixer","artist","title"))
  remixCounts$u <- 1
  remixerRemixCounts <- ddply(remixCounts, .(remixer), summarise, totalFreq=sum(n), uniqueFreq=sum(u))
  remixerRemixCounts <- merge(x=data.frame(id=1:length(allArtists)),y=remixerRemixCounts,by.x="id",by.y="remixer",all.x=TRUE)
  artistRemixCounts <- ddply(remixCounts, .(artist), summarise, totalFreq=sum(n), uniqueFreq=sum(u))
  artistRemixCounts <- merge(x=data.frame(id=1:length(allArtists)),y=artistRemixCounts,by.x="id",by.y="artist",all.x=TRUE)
  
  # Edges and nodes
  edges <- data.frame(from=remixCounts$remixer,
                      to=remixCounts$artist,
                      width=remixCounts$n,
                      title=paste0("Artist: ",allArtists[remixCounts$artist],"<br>Track: ",remixCounts$title,
                                   "<br>Remixer: ",allArtists[remixCounts$remixer],"<br>Number of times played: ",remixCounts$n))
  
  
  nodes <- data.frame(id=1:length(allArtists),
                      label=allArtists)
  nodes$title <- paste0("Artist: ",allArtists,
                        ifelse(!is.na(remixerRemixCounts$totalFreq),paste0("<br>Number of remixes: ",remixerRemixCounts$uniqueFreq),""),
                        ifelse(!is.na(artistRemixCounts$totalFreq),paste0("<br>Number of times remixed:  ",artistRemixCounts$uniqueFreq),""))
  nodes$value <- remixerRemixCounts$totalFreq + artistRemixCounts$totalFreq
  nodes$group <- "Default"
  nodes$group[bothID] <- "Remixed and remixer"
  nodes$group[remixedID] <- "Remixed"
  nodes$group[remixerID] <- "Remixer"
  
  # Network
  fn <- visNetwork(nodes=nodes, edges=edges) %>%
        visPhysics(stabilization=FALSE,
                   solver = "forceAtlas2Based", 
                   forceAtlas2Based = list(gravitationalConstant = -30)) %>%
        visEdges(shadow = FALSE,
                 hoverWidth=0.1,
                 arrows =list(to = list(enabled = TRUE, scaleFactor = 0.25, color="black")),
                 color = list(color="#7d7d7d", highlight = "#EC008B", hover="#ff3aae")) %>%
        visGroups(groupname = "Remixed and remixer", 
                  color = list(background = "#EC008B", border = "white", highlight = "#EC008B", hover="#ff3aae"),
                  font = list(color="white")) %>% 
        visGroups(groupname = "Remixed", 
                  color = list(background = "#EC008B", border = "white", highlight = "#EC008B", hover="#ff3aae"),
                  font = list(color="white")) %>%
        visGroups(groupname = "Remixer", 
                  color = list(background = "#EC008B", border = "white", highlight = "#EC008B", hover="#ff3aae"),
                  font = list(color="white")) %>%
        visGroups(groupname = "Default", 
                  color = list(background = "#009FE3", border = NULL, highlight = "#EC008B", hover="#ff3aae"),
                  font = list(color="white")) %>%
        visInteraction(hover = TRUE, tooltipDelay=0.2) %>%
        visLayout(randomSeed = 123)
  print(fn)
  
}
#remixNetPlot(data,c("Armin Van Buuren","Arisen Flame"),c("Alexander Popov"))
# fix artist labels, add shiny
