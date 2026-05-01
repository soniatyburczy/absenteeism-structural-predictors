source("scripts/utils.R")
library(tidyverse)

train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")

lin_ord1 <- lm(`% Chronically Absent` ~ `Economic Need Index` + `% Poverty` + 
`% English Language Learners` + `% Students with Disabilities`, data = train_df)
summary(lin_ord1)

tune_preds <- predict(lin_ord1, tune_df)
test_preds <- predict(lin_ord1, test_df)

# Calculate MSE / RMSE
tune_mse <- mse(tune_df$`% Chronically Absent`, tune_preds)
tune_rmse <- rmse(tune_df$`% Chronically Absent`, tune_preds)

test_mse <- mse(test_df$`% Chronically Absent`, test_preds)
test_rmse <- rmse(test_df$`% Chronically Absent`, test_preds)

# Calculate R^2 / Adjusted R^2
tune_r2 <- r2(tune_df$`% Chronically Absent`, tune_preds)
tune_adj_r2 <- adj_r2(tune_df$`% Chronically Absent`, tune_preds, 4)

test_r2 <- r2(test_df$`% Chronically Absent`, test_preds)
test_adj_r2 <- adj_r2(test_df$`% Chronically Absent`, test_preds, 4)

linear_results <- data.frame(
  model = "linear",
  split = c("train", "tune", "test"),
  mse = c(train_mse, tune_mse, test_mse),
  rmse  = c(train_rmse, tune_rmse, test_rmse),
  r2    = c(train_r2, tune_r2, test_r2),
  adj_r2 = c(train_adj_r2, tune_adj_r2, test_adj_r2)
)