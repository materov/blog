library(tidyverse)
library(magrittr)
library(RCurl)
library(leaflet)

url <- getURL("https://raw.githubusercontent.com/materov/blog_data/main/fire_NSK.csv")
fire <- read.csv(text = url)

fire %<>% na.omit()
fire %<>% as_tibble()
fire$DATE_ZVK %<>% as.Date()

fire_geo <-
fire %>% 
#  filter(OBJECT_CATEGORIE %in% c("Многоквартирный жилой дом",
#                                 "Одноквартирный жилой дом")) %>% 
#  filter(DATE_ZVK > "2019-01-01") %>% 
  select(geo_lat, geo_lon) %>% 
  purrr::set_names("lat", "long") 


leaflet(fire_geo) %>%
  setView(lng = 82.9, lat = 55, zoom = 11) %>% 
  addTiles() %>% 
  addMarkers(
  clusterOptions = markerClusterOptions()
) %>% addProviderTiles(providers$Ersi) 
# Wikimedia - светлая тема
# CartoDB - светлая тема
# CartoDB.DarkMatter - темная тема
# Esri - подробно дороги
# Stamen.TonerLines - дороги темным цветом



getColor <- function(fire) {
  sapply(fire$PRIB_TIME, function(PRIB_TIME) {
    if(PRIB_TIME <= 10) {
      "green"
    } else {
      "red"
    } })
}


icons <- awesomeIcons(
  icon = 'ios-flame',
  iconColor = 'black',
  library = 'ion',
  markerColor = getColor(fire)
)

library(htmltools)

leaflet(fire) %>%
  setView(lng = 82.87, lat = 55, zoom = 14) %>% 
  addTiles() %>% 
  addAwesomeMarkers(data = fire %>% 
                      filter(OBJECT_CATEGORIE == "Транспортные средства"),
                    lng = ~geo_lon, lat = ~geo_lat,  
                    label = ~htmlEscape(ADDRES),
                    icon = icons
  )

leaflet() %>%
  setView(lng = 82.87, lat = 55, zoom = 12) %>% 
  addTiles() %>% 
  addCircleMarkers(data = fire, 
                   lng = ~geo_lon, lat = ~geo_lat, 
    radius = 6*log10(fire$SQUARE_LOC),
    stroke = FALSE, fillOpacity = 0.4
  )


leaflet(fire) %>%
  setView(lng = 82.9, lat = 55, zoom = 11) %>% 
  addTiles(options = providerTileOptions(noWrap = TRUE), group="Базовая тема (OpenStreetMap)") %>%
  addProviderTiles("OpenFireMap", group="Пожарно-спасательные подразделения (OpenFireMap)") %>% 
  addProviderTiles("CartoDB.DarkMatter", group="Темная тема (CartoDB)") %>%
  addProviderTiles("Esri.WorldImagery", group="Спутник") %>%  
  addTiles() %>% 
  addAwesomeMarkers(data = fire %>% 
                      filter(OBJECT_CATEGORIE %in% c("Одноквартирный жилой дом", 
                                                     "Многоквартирный жилой дом")), 
             lng = ~geo_lon, lat = ~geo_lat, group = "Жилые дома", 
             icon = icons, 
             label = ~htmlEscape(ADDRES),
    clusterOptions = markerClusterOptions()
  )  %>% 
  addAwesomeMarkers(data = fire %>% 
                      filter(OBJECT_CATEGORIE %in% c("Транспортные средства")), 
             lng = ~geo_lon, lat = ~geo_lat, group = "Транспортные средства", 
             icon = icons, 
             label = ~htmlEscape(ADDRES),
             clusterOptions = markerClusterOptions()
  )  %>% 
  addAwesomeMarkers(data = fire %>% 
                      filter(OBJECT_CATEGORIE %in% c("Надворные постройки")), 
             lng = ~geo_lon, lat = ~geo_lat, group = "Надворные постройки", 
             icon = icons, 
             label = ~htmlEscape(ADDRES),
             clusterOptions = markerClusterOptions()
  )  %>% 
  addLayersControl(overlayGroups = c("Жилые дома", 
                                     "Транспортные средства", 
                                     "Надворные постройки"),
    baseGroups = c("Базовая тема (OpenStreetMap)",
                                  "Пожарно-спасательные подразделения (OpenFireMap)", 
                                  "Темная тема (CartoDB)",
                                  "Спутник"), 
                   options = layersControlOptions(collapsed = FALSE)) %>% 
  hideGroup("Транспортные средства") %>% 
  hideGroup("Надворные постройки")


library(crosstalk)

# подготовка данных
fire_dated <- fire_0
fire_dated$DATE_ZVK %<>% as.Date()

fire_filtered <- fire_dated %>% 
  filter(OBJECT_CATEGORIE %in% c("Одноквартирный жилой дом",
                                 "Многоквартирный жилой дом")) %>% 
  filter(DATE_ZVK >= "2020-01-01") %>% 
  rename(lat = "geo_lat", long = "geo_lon")

shared_fire <- SharedData$new(fire_filtered)

# отрисовка карты
bscols(widths = c(2,NA, NA),
       list(
         filter_checkbox("OBJECT_CATEGORIE", "Объект горения", shared_fire, ~OBJECT_CATEGORIE, inline = F),
         filter_slider("PRIB_TIME", "Время прибытия", shared_fire, column = ~PRIB_TIME, step = 1, width = "100%") 
       ),
  leaflet(shared_fire, width = "100%", height = 600) %>% 
    setView(lng = 82.9, lat = 55, zoom = 11) %>%
    addTiles() %>% 
    addMarkers()
)


#--

CrosstalkMap <-
  # отрисовка карты
  bscols(widths = c(2,NA, NA),
         list(
           filter_checkbox("OBJECT_CATEGORIE", "Объект горения", 
                           shared_fire, ~OBJECT_CATEGORIE, inline = F),
           filter_slider("PRIB_TIME", "Время прибытия", 
                         shared_fire, column = ~PRIB_TIME, step = 1, width = "100%") 
         ),
         leaflet(shared_fire, width = "100%", height = 600) %>% 
           setView(lng = 82.9, lat = 55, zoom = 11) %>%
           addTiles() %>% 
           addMarkers()
  )
htmltools::save_html(CrosstalkMap, "CrosstalkMap.html")
saveWidget(CrosstalkMap, "CrosstalkMap.html")

###

bscols(widths = c(2,NA),
       list(
         filter_checkbox("OBJECT_CATEGORIE", "Категория", shared_fire, ~OBJECT_CATEGORIE, inline = F)
       ),
  leaflet(data = shared_fire, 
          width = "100%", height = 600) %>%
    setView(lng = 82.9, lat = 55, zoom = 11) %>%
    addTiles() %>% addMarkers(lng = ~long, lat = ~lat,
      clusterOptions = markerClusterOptions())
  )


####

library(crosstalk)
library(leaflet)
library(DT)

# Wrap data frame in SharedData
sd <- SharedData$new(quakes[sample(nrow(quakes), 100),])

# Create a filter input


# Use SharedData like a dataframe with Crosstalk-enabled widgets
bscols(filter_slider("mag", "Magnitude", sd, column=~mag, step=0.1, width=250),
  leaflet(sd) %>% addTiles() %>% addMarkers(),
  datatable(sd, extensions="Scroller", style="bootstrap", class="compact", width="100%",
            options=list(deferRender=TRUE, scrollY=300, scroller=TRUE))
)

shared_quakes <- SharedData$new(quakes[sample(nrow(quakes), 100),])
bscols(
  leaflet(shared_quakes, width = "100%", height = 300) %>%
    addTiles() %>%
    addMarkers(),
  d3scatter(shared_quakes, ~depth, ~mag, width = "100%", height = 300)
)


library(plotly)
# devtools::install_github("rstudio/leaflet#346")
library(leaflet)
library(crosstalk)
library(htmltools)

# leaflet should respect these "global" highlight() options
options(opacityDim = 0.5)

sd <- highlight_key(quakes)

p <- plot_ly(sd, x = ~depth, y = ~mag) %>% 
  add_markers(alpha = 0.5) %>%
  highlight("plotly_selected", dynamic = TRUE)

map <- leaflet(sd) %>% 
  addTiles() %>% 
  addCircles()

bscols(p, map)

###


leaflet(fire_geo) %>%
  setView(lng = 82.9, lat = 55, zoom = 11) %>% 
  addTiles() %>% 
  addMarkers(
    clusterOptions = markerClusterOptions()
  )




bscols(
  leaflet(shared_fire) %>% addTiles() %>% addMarkers(),
  DT::datatable(shared_fire, extensions="Scroller", style="bootstrap", class="compact", width="100%",
            options=list(deferRender=TRUE, scrollY=300, scroller=TRUE))
)


leaflet(fire_geo) %>%
  setView(lng = 82.9, lat = 55, zoom = 11) %>% 
  addTiles() %>% 
  addMarkers(
    clusterOptions = markerClusterOptions()
  )



bscols(widths = c(2,NA),
       list(
         filter_checkbox("cyl", "Cylinders", shared_mtcars, ~cyl, inline = TRUE)
       ),
       d3scatter(shared_mtcars, ~wt, ~mpg, ~factor(cyl), width="100%", height=250)
)

bscols(
  leaflet(shared_fire, width = "100%", height = 500) %>%
    addTiles() %>%
    addMarkers())

shared_mtcars <- SharedData$new(mtcars)







leaflet() %>%
  addTiles(group = "OpenStreetMap") %>%
  addProviderTiles("Stamen.Toner", group = "Toner by Stamen") %>%
  addMarkers(runif(20, -75, -74), runif(20, 41, 42), group = "Markers") %>%
  addLayersControl(
    baseGroups = c("OpenStreetMap", "Toner by Stamen"),
    overlayGroups = c("Markers")
  )

leaflet(quakes) %>% addTiles() %>% addMarkers(
  clusterOptions = markerClusterOptions(iconCreateFunction=JS("function (cluster) {    
                                                              var childCount = cluster.getChildCount(); 
                                                              var c = ' marker-cluster-';  
                                                              if (childCount < 100) {  
                                                              c += 'large';  
                                                              } else if (childCount < 1000) {  
                                                              c += 'medium';  
                                                              } else { 
                                                              c += 'small';  
                                                              }    
                                                              return new L.DivIcon({ html: '<div><span>' + childCount + '</span></div>', className: 'marker-cluster' + c, iconSize: new L.Point(40, 40) });
                                                              
                                                              }"))
)
