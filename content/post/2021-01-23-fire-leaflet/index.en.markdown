---
title: Интерактивные карты на Leaflet
author: admin
date: '2021-01-23'
slug: fire-leaflet
categories: ["R"]
tags: ["rstats", "геоданные"]
subtitle: 'построение интерактивных географических HTML-карт'
summary: 'В статье рассказывается, как используя библиотеку `Leaflet` можно создавать HTML-виджеты для интерактивного просмотра пространственных данных.'
authors: 
- admin
lastmod: '2021-01-25'
featured: yes
math: true
image:
  caption: ''
  focal_point: ''
  preview_only: yes
projects: []
---


[Leaflet](https://leafletjs.com/) является одной из самых популярных open-source библиотек на JavaScript для создания интерактивных карт. Соответствующая библиотека [Leaflet for R](https://rstudio.github.io/leaflet/) позволяет легко интегрировать интерактивные карты Leaflet как HTML-виджеты. В продолжение [предыдущей записи](https://materov-blog.netlify.app/post/geodata-fire/) в блоге по работе с геоданными в {{< icon name="r-project" pack="fab" >}}, покажем, как можно быстро разработать интерактивную карту пожаров не прибегая при этом к средствам JavaScript. 

Пример Leaflet карты, иллюстрирующей пожары в Новосибирске за период с начала 2016 года по середину июля 2020 года, показан ниже. Для удобства отображения большого количества маркеров, отмечающих точки, где произошли пожары, смежные маркеры автоматически группируются в кластеры.



<iframe seamless src="BasicMap.html" width="100%" height="600"></iframe>

Мы воспроизведем карту выше, а также рассмотрим некоторые другие особенности Leaflet.

# Исходные данные

Поключим небходимые библиотеки в {{< icon name="r-project" pack="fab" >}}.


```r
library(tidyverse)
library(magrittr)
library(RCurl)

library(leaflet)
```

Загрузим **данные по пожарам в Новосибирске**[^thanks] за последние несколько лет. 

[^thanks]: Автор выражает благодарность [О.С. Малютину](https://www.sibpsa.ru/ntc/management/?ELEMENT_ID=748) за предоставленные данные.


```r
url <- getURL("https://raw.githubusercontent.com/materov/blog_data/main/fire_NSK.csv")
fire <- read.csv(text = url)
fire %<>% as_tibble()

fire
```

```
## # A tibble: 6,379 x 13
##        X NOMER_ZVK DATE_ZVK ADDRES RIDE_TYPE OBJECT_CATEGORIE geo_lon geo_lat
##    <int>     <int> <fct>    <fct>  <fct>     <fct>              <dbl>   <dbl>
##  1     1   1600038 2016-01… ул. М… Тушение … Транспортные ср…    82.9    55.1
##  2     2   1600071 2016-01… ул. Ш… Тушение … Многоквартирный…    83.1    54.9
##  3     3   1600255 2016-01… ул. К… Тушение … Многоквартирный…    83.0    55.0
##  4     4   1600284 2016-01… ул. П… Тушение … Транспортные ср…    83.1    55.0
##  5     5   1600287 2016-01… ул. Н… Тушение … Многоквартирный…    83.0    55.1
##  6     6   1600319 2016-01… ул. Ф… Тушение … Здания производ…    82.9    55.0
##  7     7   1600410 2016-01… ул. В… Тушение … Одноквартирный …    83.0    55.0
##  8     8   1600412 2016-01… мрн. … Тушение … Многоквартирный…    82.9    55.0
##  9     9   1600435 2016-01… ул. Ш… Тушение … Прочие обьекты …    82.9    55.0
## 10    10   1600436 2016-01… ул. С… Тушение … Транспортные ср…    82.9    55.0
## # … with 6,369 more rows, and 5 more variables: PRIB_TIME <int>,
## #   LOC_TIME <int>, LPP_TIME <int>, SQUARE_LOC <dbl>, PERSONNEL <dbl>
```

Основные интересующие нас переменные -- широта и долгота: `geo_lat` и `geo_lon`.


```r
fire_geo <-
fire %>% 
  select(geo_lat, geo_lon) %>% 
  purrr::set_names("lat", "long") 

fire_geo
```

```
## # A tibble: 6,379 x 2
##      lat  long
##    <dbl> <dbl>
##  1  55.1  82.9
##  2  54.9  83.1
##  3  55.0  83.0
##  4  55.0  83.1
##  5  55.1  83.0
##  6  55.0  82.9
##  7  55.0  83.0
##  8  55.0  82.9
##  9  55.0  82.9
## 10  55.0  82.9
## # … with 6,369 more rows
```

# Построение базовой карты

Для построения подложки интерактивной карты необходимо в первую очередь выбрать координаты центра карты и базовое увеличение командой `setView()`.

```r
leaflet(fire_geo) %>%
  setView(lng = 82.9, lat = 55, zoom = 11)  %>% 
  addTiles()
```



<iframe seamless src="ZeroMap.html" width="100%" height="600"></iframe>

# Нанесение данных на карту

## Маркеры

Точки на карте, отвечающие пожарам, можно добавить командой `addMarkers()`. В качестве примера рассмотрим только категорию объектов пожара *Садовый дом, дача*.

```r
fire %>% 
  filter(OBJECT_CATEGORIE == "Садовый дом, дача") %>% 
  select(geo_lat, geo_lon) %>% 
  purrr::set_names("lat", "long") %>% 
  leaflet() %>%
  setView(lng = 82.9, lat = 55, zoom = 11)  %>% 
  addTiles() %>% 
  addMarkers()
```



<iframe seamless src="AddMarkersMap.html" width="100%" height="600"></iframe>

## Кластеры

Для большого количества данных маркеры могут сливаться, поэтому сгруппируем их используя опцию `clusterOptions`.

```r
leaflet(fire_geo) %>%
  setView(lng = 82.9, lat = 55, zoom = 11)  %>% 
  addTiles() %>% 
  addMarkers(
  clusterOptions = markerClusterOptions()
)
```



<iframe seamless src="AddClustersMap.html" width="100%" height="600"></iframe>

По сути, наша карта готова. Тем не менее, ее можно улучшить, рассмотрев дополнительные возможности, предоставляемые Leaflet.

## Слои карт

OpenStreetMap позволяет добавлять на карту различные слои. 

```r
leaflet(fire_geo) %>%
  setView(lng = 82.9, lat = 55, zoom = 11) %>% 
  addProviderTiles(providers$OpenFireMap) %>% 
  addMarkers(
  clusterOptions = markerClusterOptions()
) 
```



<iframe seamless src="AddFireMap.html" width="100%" height="450"></iframe>

Например, актуальным является слой OpenFireMap, который наносит на карту пожарные части, гидранты и пожарные водоемы.
Полный список подключаемых карт содержится в переменной `providers`. 


```r
head(leaflet::providers, 5)
```

```
## $OpenStreetMap
## [1] "OpenStreetMap"
## 
## $OpenStreetMap.Mapnik
## [1] "OpenStreetMap.Mapnik"
## 
## $OpenStreetMap.DE
## [1] "OpenStreetMap.DE"
## 
## $OpenStreetMap.CH
## [1] "OpenStreetMap.CH"
## 
## $OpenStreetMap.France
## [1] "OpenStreetMap.France"
```

Соотнести слои с их названиями можно используя соответствующую [веб-страницу](http://leaflet-extras.github.io/leaflet-providers/preview/index.html).

## Вид и форма маркеров

Маркеры могут быть двух видов: в виде *иконок* и *кругов*. 
Подробно о виде и форме маркеров можно прочесть на [сайте библиотеки Leaflet](https://rstudio.github.io/leaflet/markers.html). Ограничимся только пожарами на транспортных средствах.
Сделаем карту так, чтобы при наведении на маркер всплывал адрес пожара. 

Разделим маркеры на две категории по цвету, соответствующие пожарам:

- обозначим зеленым цветом маркеры, где время прибытия пожарно-спасательных подразделений составило не более 10 минут;
- красные маркеры соответствуют времени прибытия более 10 минут.


```r
# цвет маркеров
getColor <- function(fire) {
  sapply(fire$PRIB_TIME, function(PRIB_TIME) {
    if(PRIB_TIME <= 10) {
      "green"
    } else {
      "red"
    } })
}

# вид маркеров
icons <- awesomeIcons(
  icon      = 'ios-flame',
  iconColor = 'black',
  library   = 'ion',
  markerColor = getColor(fire)
)


library(htmltools)

leaflet() %>%
  setView(lng = 82.86, lat = 55, zoom = 14) %>% 
  addTiles() %>% 
  addAwesomeMarkers(data = fire %>% 
                    filter(OBJECT_CATEGORIE == "Транспортные средства"),
                    lng = ~geo_lon, lat = ~geo_lat,  
                    label = ~htmlEscape(ADDRES),
                    icon = icons
  )
```



<iframe seamless src="AddAwesomeMarkers.html" width="100%" height="600"></iframe>

Как говорилось ранее, маркеры можно представлять и в виде кругов. 
Применим эту возможность для отображения площади пожаров, подобрав при этом радиус окружности маркера так, чтобы он в некотором масштабе соответствовал площади возгорания.

```r
leaflet() %>%
  setView(lng = 82.87, lat = 55, zoom = 12.5) %>% 
  addTiles() %>% 
  addCircleMarkers(data = fire, 
                   lng = ~geo_lon, lat = ~geo_lat, 
    radius = 5*log10(fire$SQUARE_LOC),
    stroke = FALSE, fillOpacity = 0.4
  )
```



<iframe seamless src="SquareMarkers.html" width="100%" height="600"></iframe>

## Интерактиваная легенда

Теперь попробуем соеденить некоторые возможности, которые мы рассмотрели, и создадим карту на которой мы могли бы выбирать темы подложки и основные типы интересующих нас объектов горения с помощью легенды.

{{< spoiler text="**Код визуализирующий карту ниже**" >}}

```r
leaflet() %>%
  setView(lng = 82.9, lat = 55, zoom = 11) %>% 
  addTiles(options = providerTileOptions(noWrap = TRUE), 
           group = "Базовая тема (OpenStreetMap)") %>%
  addProviderTiles("CartoDB.DarkMatter", 
           group = "Темная тема (CartoDB)") %>%
  addProviderTiles("Esri.WorldImagery", 
           group = "Спутник") %>%  
  addTiles() %>% 
  addAwesomeMarkers(data = fire %>% 
                      filter(OBJECT_CATEGORIE %in% c("Одноквартирный жилой дом", 
                                                     "Многоквартирный жилой дом")), 
             lng = ~geo_lon, lat = ~geo_lat, 
             group = "Жилые дома",  
             label = ~htmlEscape(ADDRES),
    clusterOptions = markerClusterOptions()
  )  %>% 
  addAwesomeMarkers(data = fire %>% 
                      filter(OBJECT_CATEGORIE %in% c("Транспортные средства")), 
             lng = ~geo_lon, lat = ~geo_lat, 
             group = "Транспортные средства",
             label = ~htmlEscape(ADDRES),
             clusterOptions = markerClusterOptions()
  )  %>% 
  addAwesomeMarkers(data = fire %>% 
                      filter(OBJECT_CATEGORIE %in% c("Надворные постройки")), 
             lng = ~geo_lon, lat = ~geo_lat, 
             group = "Надворные постройки", 
             label = ~htmlEscape(ADDRES),
             clusterOptions = markerClusterOptions()
  )  %>% 
  addLayersControl(overlayGroups = c("Жилые дома", 
                                     "Транспортные средства", 
                                     "Надворные постройки"),
    baseGroups = c("Базовая тема (OpenStreetMap)", 
                                  "Темная тема (CartoDB)",
                                  "Спутник"), 
    position = c("bottomleft"),
                   options = layersControlOptions(collapsed = FALSE)) %>% 
  hideGroup("Транспортные средства") %>% 
  hideGroup("Надворные постройки")
```

{{< /spoiler >}}



<iframe seamless src="AddLegend.html" width="100%" height="600"></iframe>

## Использование Crosstalk

Предыдущая карта содержит легенду, способную взаимодействовать с картой. 
Несмотря на это, в карте отсутствует динамическая фильтрация данных. Включить ее в полной мере можно, например, с помощью [Shiny](https://shiny.rstudio.com/) -- инструмента создания интерактивных веб-приложений. 

Разработанное в Shiny приложение может запускаться на исполнение с сервера:

- со специального облачного сервера [shinyapps.io](https://www.shinyapps.io/);
- выполняться на локальном сервере пользователя; 
- выполняться на платном сервере Rstudio.

Использование сервера не всегда удобно, и написание приложений в Shiny требует специальных навыков. Другой способ введения интерактивности -- разработка приложений в  [Crosstalk](https://rstudio.github.io/crosstalk/using.html), который обладает меньшими возможностями, но не требует сервера. В качестве примера рассмотрим пожары в одноквартирных и многоквартирных жилых домах в период с 1 января 2020 года.

Подготовим данные и сделаем карту в `crosstalk`.


```r
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
```

```r
# отрисовка карты
bscols(widths = c(2,NA, NA),
       list(
         filter_checkbox("OBJECT_CATEGORIE", "Категория объекта", 
                         shared_fire, ~OBJECT_CATEGORIE, inline = F),
         filter_slider("PRIB_TIME", "Время прибытия", 
                       shared_fire, column = ~PRIB_TIME, step = 1, width = "100%") 
       ),
  leaflet(shared_fire, width = "100%", height = 600) %>% 
    setView(lng = 82.9, lat = 55, zoom = 11) %>%
    addTiles() %>% 
    addMarkers()
)
```



<iframe seamless src="CrosstalkMap.html" width="100%" height="600"></iframe>


# Заключение

Мы коснулись лишь небольшой части тех возможностей, которыми обладает библиотека Leaflet, однако даже те инструменты, обзор которых здесь представлен, позволяют существенно упростить визуализацию информации связанной с планированием предотвращения последствий различных чрезвычайных ситуаций.







