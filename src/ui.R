########################
######### INIT #########
########################

# Load packages
library(shiny)
library(shinydashboard)
library(DT)

########################
####### HEADER #########
########################
header <- dashboardHeader(title="A State of Trance")

#########################
####### SIDEBARS ########
#########################

## Top 50 panel
top50Panel <- conditionalPanel("input.sidemenu == 'top50Tab'",
                               hr(),
                               tags$div(HTML(paste(tags$span(style="padding-left:12px; font-size: 16px;","Parameters"), sep = ""))),
                               br(),
                               sliderInput("top50_episode_range","Episode range:", min=1, max=max(data$episode), value=c(1,max(data$episode), step=1)),
                               textOutput("top50RangeText"),
                               tags$head(tags$style("#top50RangeText{padding-left: 12px; font-size: 10px; font-style: italic;}")),
                               br(),
                               checkboxGroupInput("filters", "Filters:",
                                                  c("Tune of the Week" = "totw",
                                                    "Future Favorite" = "ff",
                                                    "ASOT Radio Classic" = "rc",
                                                    "Progressive Pick" = "pp",
                                                    "Remix" = "remix"))
)

## Timeline panel
timelinePanel <- conditionalPanel("input.sidemenu == 'timelineTab'",
                               hr(),
                               tags$div(HTML(paste(tags$span(style="padding-left:12px; font-size: 16px;","Parameters"), sep = ""))),
                               br(),
                               selectInput("input_var","Variable:",choices=c("Artist","Track","Label"),selected="Artist"),
                               uiOutput("timelineVarList"),
                               radioButtons("timelineType", "Timeline type:", choices=c("Density","Histogram"), selected="Density"),
                               sliderInput("timelineAcc","Accuracy:", min=1, max=3, value=1, step=1, ticks=TRUE)
)

## Remix panel
remixPanel <- conditionalPanel("input.sidemenu == 'remixTab'",
                                  hr(),
                                  tags$div(HTML(paste(tags$span(style="padding-left:12px; font-size: 16px;","Parameters"), sep = ""))),
                                  br(),
                                  selectizeInput("remixerFilter","Remixer:", choices=levels(data$artist),selected="Armin Van Buuren", multiple=TRUE, options = list(maxItems=5, placeholder="Choose artists...")),
                                  selectizeInput("remixedFilter","Remixed:", choices=levels(data$artist),selected=NULL, multiple=TRUE, options = list(maxItems=5, placeholder="Choose artists..."),
                                  tags$div(HTML(paste(tags$span(style="padding-left:12px; font-size: 12px;","WIP"), sep = "")))
                                  )
)

## ALL SIDEBARS
sidebars <- dashboardSidebar(
  sidebarMenu(id="sidemenu",
              menuItem("Info", tabName="infoTab", icon=icon("info-circle")),
              menuItem("Dashboards", tabName="dashTab", icon=icon("dashboard"),
                menuSubItem("Top 50", tabName="top50Tab", icon=icon("bar-chart")),
                menuSubItem("Timeline", tabName="timelineTab", icon=icon("area-chart")),
                menuSubItem("Remixes", tabName="remixTab", icon=icon("exchange")),
                menuSubItem("Tracklists (WIP)", tabName="tracklistTab", icon=icon("list-ul")),
                menuSubItem("Summary (WIP)", tabName="summaryTab", icon=icon("th"))
                #tags$head(tags$script(HTML('$(document).ready(function() {$(".treeview-menu").css("display", "block");})')))
              ),
  top50Panel,
  timelinePanel,
  remixPanel,
  hr(),
  tags$div(HTML(paste(tags$span(style="padding-left:12px; font-size: 12px;",HTML("&#169;"),"2016 Jesse Myrberg"), sep = "")))
  )
)

########################
####### TABITEMS #######
########################

## Info
infoTab <- tabItem(tabName="infoTab",
        fluidRow(
          box(title="A State of Trance", width=12, background="black",
              a(href="http://www.astateoftrance.com","A State of Trance")," (often abbreviated as ASOT) is a weekly radio show aired every Thursday at 20:00 (CET) and hosted by music producer and DJ Armin van Buuren."
          ),
          box(title="What is this site about?", width=12, background="black",
              "This is an unofficial website that allows the fans of the show to explore the tracklists of the show. This is done through interactive dashboards, where users may affect the data visualization by changing parameters."
          ),
          box(title="The tracklist data", width=12, background="black",
              "The tracklist data used on this site has been programmatically obtained from the official A State of Trance website. Some episodes with missing a tracklist have been obtained manually.",
                "Simple heuristics have been used for extracting information from the tracklists. Since this site is still a work in progress, some data may be missing or inaccurate."
          )
        )
)

## Top 50
top50Tab <- tabItem(tabName="top50Tab",
                   fluidRow(
                     tags$style(HTML("#shiny-tab-top50Tab .box-header {text-align:center;}")),
                     column(width=4, 
                            box(title="Most played by Artist",width='100%', background="black",height=1264,plotOutput("top50ArtistPlot"))
                     ),
                     column(width=4, 
                            box(title="Most played by Track", width='100%', background="black",height=1264,plotOutput("top50TrackPlot"))
                     ),
                     column(width=4, 
                            box(title="Most played by Label", width='100%', background="black",height=1264,plotOutput("top50LabelPlot"))
                     )
                   )
)

## Timeline
timelineTab <- tabItem(tabName="timelineTab",
                       fluidRow(
                         tags$style(HTML("#shiny-tab-timelineTab .box-header {text-align:center;}")),
                         column(width=12,
                                       box(title="Plays over time", height=800, width='100%', background="black",plotOutput("timelinePlot"))
                                      )
                              )
                      )

## Remix
remixTab <- tabItem(tabName="remixTab",
                    fluidRow(tags$style(HTML("#shiny-tab-remixTab .box-header {text-align:center;}")),
                             box(title="Remixes", width='100%', background="black", height=860,
                                 visNetworkOutput("remixNetPlot", width="100%", height=860))
                             )
                    )

## Tracklists
tracklistTab <- tabItem(tabName="tracklistTab",
                      fluidRow(
                        tags$head(tags$style(HTML("#tracklistTable tr.selected {background-color:'7d7d7d'}"))),
                        column(width=12,
                               box(title="Tracklists", height=800, width='100%', background="black", DT::dataTableOutput("tracklistTable"))
                        )
                      )
)

## Summary
summaryTab <- tabItem(tabName="summaryTab",
                       fluidRow(
                         column(width=12,
                                box(title="Summary", height=800, width='100%', background="black",
                                    "Current totals will be visualized here")
                         )
                       )
)

## ALL TAB ITEMS
tabitems <- tabItems(
  infoTab,
  top50Tab,
  timelineTab,
  remixTab,
  tracklistTab,
  summaryTab
)
  
  
########################
######### BODY #########
########################
body <- dashboardBody(
  
  # Background color
  tags$head(tags$style(HTML('
                            .content-wrapper,
                            .right-side {
                            background-color: #111111;
                            }
                            
                            .skin-purple .main-header .logo {
                            background-color: #009FE3;
                            }
                            
                            .skin-purple .main-header .logo:hover {
                            background-color: #EC008B;
                            }
                            
                            .skin-purple .main-header .navbar {
                            background-color: #009FE3;
                            }
                            
                            .skin-purple .main-header .navbar .sidebar-toggle:hover {
                            color:#f6f6f6;
                            background-color: #EC008B;
                            }
                            
                            .skin-purple .sidebar-menu>li.active>a,.skin-purple .sidebar-menu>li:hover>a {
                            color:#fff;
                            background:#1e282c;
                            border-left-color:#EC008B
                            }
                            '))),
  
  # Tab items
  tabitems
  
)

########################
########## UI ##########
########################
ui <- dashboardPage(
  
  # Theme
  skin="purple",
  
  # Content
  header,
  sidebars,
  body
)