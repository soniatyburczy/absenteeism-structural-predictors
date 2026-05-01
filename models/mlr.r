source("scripts/utils.R")
library(tidyverse)

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")

lin_ord1 <- lm(`% Chronically Absent` ~ `Economic Need Index` + `% Poverty` + 
`% English Language Learners` + `% Students with Disabilities`, data = train_df)
summary(lin_ord1)

train_preds <- predict(lin_ord1, train_df)
tune_preds <- predict(lin_ord1, tune_df)
test_preds <- predict(lin_ord1, test_df)

splits <- list(train = train_df, tune = tune_df, test = test_df)
linear_results <- evaluate_splits(lin_ord1, splits, 4, "linear")

write_csv(linear_results, "data/model_data/mlr_results.csv")