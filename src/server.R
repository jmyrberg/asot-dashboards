########################
######### INIT #########
########################

# Load packages
library(shiny)
library(shinydashboard)
library(DT)

# Run source
source("global.R")


########################
######## SERVER ########
########################
server <- function(input, output) { 
  
  # Top 50
  output$top50RangeText <- renderText({dts <- get_episode_daterange(data,input$top50_episode_range[1],input$top50_episode_range[2])
                                            paste0("Corresponds to ",format(dts$min_date,"%m/%Y")," - ",format(dts$max_date,"%m/%Y"))})
  output$top50ArtistPlot <- renderPlot({top50Plot(data,"Artist",50,input$top50_episode_range[1],input$top50_episode_range[2],input$filters)},height=1200)
  output$top50TrackPlot <- renderPlot({top50Plot(data,"Track",50,input$top50_episode_range[1],input$top50_episode_range[2],input$filters)},height=1200)
  output$top50LabelPlot <- renderPlot({top50Plot(data,"Label",50,input$top50_episode_range[1],input$top50_episode_range[2],input$filters)},height=1200)
  
  # Timeline
  output$timelinePlot <- renderPlot({timelinePlot(data,input$input_var,input$timeline_choices,input$timelineType,input$timelineAcc)}, height=function() 160*length(input$timeline_choices)+64)
  output$timelineVarList <- renderUI({choice_list <- levels(data[,tolower(ifelse(input$input_var=="Track","title",input$input_var))])
                                      if(input$input_var=="Artist") {firstChoice <- "Armin Van Buuren"} 
                                      else if(input$input_var=="Label") {firstChoice <- "Armada"} 
                                      else {firstChoice <- "Serenity"}
                                      selectizeInput("timeline_choices", paste0(input$input_var,":"), choices=choice_list,
                                                     selected=c(firstChoice), multiple=TRUE, options = list(maxItems=5, placeholder="Please start typing..."))})
  
  # Remix
  output$remixNetPlot <- renderVisNetwork(remixNetPlot(data,input$remixedFilter,input$remixerFilter))
  
  # Tracklists
  output$tracklistTable <- DT::renderDataTable(datatable(data[,c("date","episode","enum","artist","title","remixer","label")], 
                                                         options=list(pageLength=25), 
                                                         rownames=FALSE,
                                                         colnames=c("Date","Episode","#","Artist","Track","Remixer","Record label"),
                                                         filter="none") %>%
    formatStyle(c("date","episode","enum","artist","title","remixer","label"), color='white', backgroundColor='#111111')
  )

  
}

# @TODO: 
# - DataTable formatting
# - Heuristics for data preprocessing in Python
# - Folder ordering
# - Default input for Timeline