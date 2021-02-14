library(tidyverse)
library(magrittr)

'%!in%' <- function(x,y)!('%in%'(x,y))

library(RCurl)

githubURL <- "https://raw.githubusercontent.com/materov/blog_data/main/data_fire.csv"
fire <- readr::read_csv(githubURL)

fire <-
fire %>% 
  mutate_if(is.character, factor) %>%
  mutate_if(is.numeric, as.integer)

fire

#fire <- readRDS(file="/Users/materov/Dropbox/Work/Analiz Book 2020/!!DATA/data_fire.rda")

# всего 3 случая, удаляем
fire %>% 
  filter(F12 %in% c("Сухая трава (сено, камыш и т.д.)", 
                    "Мусор вне территории жилой зоны и предприятия, организации, учреждения",
                    "Мусор на территории жилой зоны (кроме территории домовладения)")) %>% 
  # место возникновения пожара
  filter(F17 %in% c("Полоса отчуждения, обочина дороги, луг, пустырь",
                    "Прочее место на открытой территории",
                    "Площадка для мусора на территории жилой зоны")) %>% 
  filter(F27 > 0) %>% nrow()

#fire <- fire %>% select(F2, F5, F6, F11, F12, F16, F17, F17A, F18, F19, F22, F27)
fire <- fire %>% select(F5, F6, F12, F17, F17A, F18, F19, F22, F27) %>% 
  # причина пожара
#  filter(F19 %!in% c("причина не указана", 
#                     "Не установлено", 
#                     "Прочие причины, связанные с неосторожным обращением с огнем")) %>% 
  # вид объекта пожара
  filter(F12 %!in% c("Сухая трава (сено, камыш и т.д.)", 
                     "Мусор вне территории жилой зоны и предприятия, организации, учреждения",
                     "Мусор на территории жилой зоны (кроме территории домовладения)")) %>% 
  # место возникновения пожара
  filter(F17 %!in% c("Полоса отчуждения, обочина дороги, луг, пустырь",
                     "Прочее место на открытой территории",
                     "Площадка для мусора на территории жилой зоны")) #%>% 
  # строительная конструкция
#  filter(F17A %!in% c("строительная конструкция не указана",
#                      "Не установлена"))

fire <- fire %>% mutate(
  died_cases = case_when(F27 > 0 ~ "died", 
                         TRUE        ~ "not_died")
)

fire <- fire %>% select(-F27)

fire

fire %>% 
  janitor::tabyl(died_cases) %>%
  janitor::adorn_pct_formatting(digits = 1) %>% 
  purrr::set_names("категория", "количество", "процент")

fire %>%
  mutate(died_date = lubridate::floor_date(F5, unit = "week")) %>%
  count(died_date, died_cases) %>%
  ggplot(aes(died_date, n, color = died_cases)) +
  geom_line(size = 1.5, alpha = 0.7) +
  scale_y_continuous(limits = (c(0, NA))) +
  labs(
    x = NULL, y = "Number of traffic crashes per week",
    color = "Died?"
  ) + silgelib::theme_plex()

#cairo_pdf("/Users/materov/Blog/blogdown blog/content/post/2021-02-14-classification/percent.pdf", width = 9, height = 4)
fire %>%
  mutate(fire_date = lubridate::floor_date(F5, unit = "week")) %>%
  count(fire_date, died_cases) %>%
  group_by(fire_date) %>%
  mutate(percent_died = n / sum(n)) %>%
  ungroup() %>%
  filter(died_cases == "died") %>%
  ggplot(aes(fire_date, percent_died)) +
  geom_line(size = 1, alpha = 0.7, color = "midnightblue") +
  scale_y_continuous(limits = c(0, NA), labels = percent_format()) +
  labs(x = NULL, y = "процент пожаров с гибелью людей\n") + silgelib::theme_plex()
#dev.off()

library(tidymodels)

set.seed(123)
fire_split <- initial_split(fire, strata = died_cases)
fire_train <- training(fire_split)
fire_test <- testing(fire_split)

set.seed(123)
fire_folds <- vfold_cv(fire_train, strata = died_cases)
fire_folds

library(themis)

fire_rec <- recipe(died_cases ~ ., data = fire) %>%
  step_date(F5) %>%
  step_rm(F5) %>%
  step_dummy(all_nominal(), -died_cases) %>%
#  step_other(F12, F16, F17, F17A, F18, F19, threshold = 0.001) %>% 
#  textrecipes::step_clean_levels(F12, F16, F17, F17A, F18, F19) %>% 
  step_downsample(died_cases)

bag_spec <- baguette::bag_tree(min_n = 10) %>%
  set_engine("rpart", times = 30) %>%
  set_mode("classification")

fire_wf <- workflow() %>%
  add_recipe(fire_rec) %>%
  add_model(bag_spec)

fire_wf

doParallel::registerDoParallel()
fire_res <- fit_resamples(
  fire_wf,
  fire_folds,
  control = control_resamples(save_pred = TRUE)
)

collect_metrics(fire_res)

fire_fit <- last_fit(fire_wf, fire_split)
collect_metrics(fire_fit)

fire_imp <- fire_fit$.workflow[[1]] %>%
  pull_workflow_fit()

#cairo_pdf("/Users/materov/Blog/blogdown blog/content/post/2021-02-14-classification/importance.pdf", width = 7, height = 3.1)
fire_imp$fit$imp %>%
  slice_max(value, n = 7) %>%
  ggplot(aes(value, fct_reorder(term, value))) +
  geom_col(alpha = 0.8, fill = "midnightblue") +
  labs(x = NULL, y = NULL) +
  silgelib::theme_plex()
#dev.off()

#cairo_pdf("/Users/materov/Blog/blogdown blog/content/post/2021-02-14-classification/ROC.pdf", width = 5, height = 5)
fire_fit %>% 
  collect_predictions() %>%
  roc_curve(died_cases, .pred_died) %>%
  ggplot(aes(x = 1 - specificity, y = sensitivity)) +
  geom_line(size = 1, color = "midnightblue") +
  geom_abline(
    lty = 2, alpha = 0.5,
    color = "gray50",
    size = 1.2
  ) +
  coord_equal() + silgelib::theme_plex()
#dev.off()

#fire_fit %>%
#  collect_predictions() %>%
#  conf_mat(died_cases, .pred_class) %>%
#  autoplot(type = "heatmap")


























