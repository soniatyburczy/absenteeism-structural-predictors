source("scripts/utils.R")
library(tidyverse)

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")

for (j in 1:10){
  mod <- lm(`% Chronically Absent` ~ poly(`Economic Need Index`, j, raw=TRUE) + 
  `% Poverty` + `% English Language Learners` + 
  `% Students with Disabilities`, data = train_df)
}