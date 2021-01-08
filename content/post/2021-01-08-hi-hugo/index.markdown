---
title: Использование глубокого обучения для анализа временных рядов
author: admin
date: '2021-01-08'
slug: hi-hugo
categories: ["R", "Deep Learning"]
tags: ["R Markdown", "time series"]
subtitle: 'использование интеграции Python GluonTS Deep Learning Library в язык программирования R для прогнозирования временных рядов'
summary: 'Мы покажем некоторые примеры использования глубокого обучения для прогнозирования временных рядов на примере экспериментальной библиотеки `modeltime.gluonts`'
authors: []
lastmod: '2021-01-08T18:02:43+07:00'
featured: yes
image:
  caption: ''
  focal_point: ''
  preview_only: yes
projects: []
---

В настоящий момент существует множество различных способов для прогнозирования временных рядов методами машинного обучения, включая методы **Deep Learning**. Пример такого рода [построения моделей](https://www.tensorflow.org/tutorials/structured_data/time_series) сверточных и рекуррентных нейронных сетей (CNN и RNN) на основе **Deep Learning** опубликован на сайте руководства фреймвока [Keras](https://www.google.com).

Наша цель - разобраться с экспериментальной библиотекой [modeltime.gluonts](https://github.com/business-science/modeltime.gluonts) на примере временных рядов...


# Установка библиотеки





![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png)


```r
summary(iris)
```

```
##   Sepal.Length    Sepal.Width     Petal.Length    Petal.Width   
##  Min.   :4.300   Min.   :2.000   Min.   :1.000   Min.   :0.100  
##  1st Qu.:5.100   1st Qu.:2.800   1st Qu.:1.600   1st Qu.:0.300  
##  Median :5.800   Median :3.000   Median :4.350   Median :1.300  
##  Mean   :5.843   Mean   :3.057   Mean   :3.758   Mean   :1.199  
##  3rd Qu.:6.400   3rd Qu.:3.300   3rd Qu.:5.100   3rd Qu.:1.800  
##  Max.   :7.900   Max.   :4.400   Max.   :6.900   Max.   :2.500  
##        Species  
##  setosa    :50  
##  versicolor:50  
##  virginica :50  
##                 
##                 
## 
```

{{% alert note %}}
Пример поста на R, сделанного R Markdown.

{{% /alert %}}






