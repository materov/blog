library(widyr)
library(tidygraph)
library(tidyverse)
library(gapminder)
library(unvotes)
library(tidytext)
library(ggraph)


# UN votes correlation with Russia ----------------------------------------

un_votes %>%
  mutate(vote = as.numeric(vote)) %>%
  pairwise_cor(country, rcid, vote, sort = TRUE) %>% 
  filter(item1 == "Russian Federation") %>% 
  top_n(30, abs(correlation)) %>% 
  ggplot(aes(correlation, reorder(item2, correlation))) +
  geom_col() +
  labs(y = "") + hrbrthemes::theme_ipsum()


# UN votes correlation ----------------------------------------------------

un_votes %>%
  mutate(vote = as.numeric(vote)) %>%
  pairwise_cor(country, rcid, vote, sort = TRUE) %>% 
  filter(item1 %in% c("Russian Federation", "United States of America")) %>% 
  group_by(item1) %>% 
  top_n(20, abs(correlation)) %>% 
  mutate(item2 = reorder_within(item2, correlation, item1)) %>% 
  ggplot(aes(correlation, item2, fill = item1)) +
  geom_col() +
  facet_wrap(~item1, scales = "free_y") +
  scale_y_reordered() +
  labs(x = "correlation", y = "", title = "Сходство по голосованию в ООН") + 
  hrbrthemes::theme_ipsum() + 
#  ggsci::scale_fill_aaas() +
  theme(legend.position = "none") 


# Gapminder clusters ------------------------------------------------------

clusters <- gapminder %>% 
  widely_kmeans(country, year, lifeExp, k = 6) 

gapminder %>% 
  inner_join(clusters, by = "country") %>% 
  ggplot(aes(year, lifeExp, group = country)) +
  geom_line() +
  facet_wrap(~ cluster)


# UN vote graph -----------------------------------------------------------

un_counts <- un_votes %>% 
  count(country, sort = T) %>% 
  filter(n > 3000)

set.seed(2020)

un_votes_gpaph <-
un_votes %>%
  mutate(vote = as.numeric(vote)) %>%
  pairwise_cor(country, rcid, vote, sort = TRUE, upper = FALSE) %>% 
  head(1000) %>% 
  as_tbl_graph() %>% 
  inner_join(un_counts, by = c(name = "country")) 

#un_votes_gpaph %>% filter(name == "France")

un_votes_gpaph %>% 
  ggraph(layout = "fr") +
  geom_edge_link(aes(edge_alpha = correlation)) +
  geom_node_point(aes(size = n, color = n), alpha = 0.7) +
  geom_node_text(aes(label = name), check_overlap = T,
                 vjust = 1, hjust = 1, size = 3) +
  theme(legend.position = "none") + theme_void() +
  viridis::scale_color_viridis(direction = -1, option = "inferno") +
  labs(title = "     UN votes, n > 3000 sessions, top 1000 different correlations",
       color = "number \nof sessions     ",
       size = "number \nof sessions     ")








# David Robinson’s example ------------------------------------------------

word_counts <- hacker_new_words %>% 
  count(word, sort = T)

hacker_new_words %>% 
  pairwise_cor(word, post_id, sort = T) %>% 
  head(300) %>% 
  as_tbl_graph() %>% 
  inner_join(word_counts, by = c(name = "word")) %>% 
  ggraph(layout = "fr") +
  geom_edge_link(aes(edge_alpha = correlation)) +
  geom_node_point(aes(size = n)) +
  geom_node_text(aes(label = name), check_overlap = T,
                 vjust = 1, hjust = 1, size = 3) +
  theme(legend.position = "none")
















