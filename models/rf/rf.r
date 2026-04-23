library(randomForest)
library(tidyverse)

train_df <- read_csv("data/processed/train.csv")
test_df  <- read_csv("data/processed/test.csv")

train_clean <- train_df %>%
  rename(
    chronic_absent = `% Chronically Absent`,
    econ_need      = `Economic Need Index`,
    pct_poverty    = `% Poverty`,
    pct_ell        = `% English Language Learners`,
    pct_swd        = `% Students with Disabilities`
  )

test_clean <- test_df %>%
  rename(
    chronic_absent = `% Chronically Absent`,
    econ_need      = `Economic Need Index`,
    pct_poverty    = `% Poverty`,
    pct_ell        = `% English Language Learners`,
    pct_swd        = `% Students with Disabilities`
  )

rf_model <- randomForest(
  chronic_absent ~ econ_need + pct_poverty + pct_ell + pct_swd,
  data      = train_clean,
  ntree     = 500,
  mtry      = 3,
  nodesize  = 10,
  maxnodes  = 100,
  importance = TRUE,
  na.action = na.omit
)

pre_train_rf <- predict(rf_model, train_clean)
pre_test_rf  <- predict(rf_model, test_clean)

# MSE
train_mse_rf <- mean((train_clean$chronic_absent - pre_train_rf)^2, na.rm = TRUE)
test_mse_rf  <- mean((test_clean$chronic_absent  - pre_test_rf)^2,  na.rm = TRUE)

# R²
ss_res_train_rf <- sum((train_clean$chronic_absent - pre_train_rf)^2, na.rm = TRUE)
ss_tot_train_rf <- sum((train_clean$chronic_absent - mean(train_clean$chronic_absent, na.rm = TRUE))^2, na.rm = TRUE)
train_r2_rf <- 1 - ss_res_train_rf / ss_tot_train_rf

ss_res_test_rf <- sum((test_clean$chronic_absent - pre_test_rf)^2, na.rm = TRUE)
ss_tot_test_rf <- sum((test_clean$chronic_absent - mean(test_clean$chronic_absent, na.rm = TRUE))^2, na.rm = TRUE)
test_r2_rf <- 1 - ss_res_test_rf / ss_tot_test_rf

# Adjusted R²
n_train <- sum(!is.na(train_clean$chronic_absent))
n_test  <- sum(!is.na(test_clean$chronic_absent))
p_rf <- 4

train_adj_r2_rf <- 1 - (1 - train_r2_rf) * (n_train - 1) / (n_train - p_rf - 1)
test_adj_r2_rf  <- 1 - (1 - test_r2_rf)  * (n_test  - 1) / (n_test  - p_rf - 1)

rf_results <- data.frame(
  model        = "random_forest",
  train_mse    = train_mse_rf,
  test_mse     = test_mse_rf,
  train_r2     = train_r2_rf,
  train_adj_r2 = train_adj_r2_rf,
  test_r2      = test_r2_rf,
  test_adj_r2  = test_adj_r2_rf
)

write_csv(rf_results, "data/rf_temporal_split/rf_results_temporal.csv")

png("plots/rf_temporal_split/rf_importance_temporal.png")
varImpPlot(rf_model, main = "RF Variable Importance")
dev.off()

png("plots/rf_temporal_split/rf_error_temporal.png")
plot(rf_model, main = "RF Error vs Number of Trees")
dev.off()

# Train vs Test MSE across ntree values
ntree_vals <- seq(50, 500, by = 50)
train_mse_ntree <- rep(0, length(ntree_vals))
test_mse_ntree  <- rep(0, length(ntree_vals))

for (i in seq_along(ntree_vals)) {
  mod_i <- randomForest(
    chronic_absent ~ econ_need + pct_poverty + pct_ell + pct_swd,
    data      = train_clean,
    ntree     = ntree_vals[i],
    mtry      = 3,
    nodesize  = 10,
    maxnodes  = 100,
    na.action = na.omit
  )
  pre_train_i <- predict(mod_i, train_clean)
  pre_test_i  <- predict(mod_i, test_clean)
  
  train_mse_ntree[i] <- mean((train_clean$chronic_absent - pre_train_i)^2, na.rm = TRUE)
  test_mse_ntree[i]  <- mean((test_clean$chronic_absent  - pre_test_i)^2,  na.rm = TRUE)
}

png("plots/rf_temporal_split/mse_plot_temporal.png")
matplot(ntree_vals, cbind(train_mse_ntree, test_mse_ntree), type = "b",
        col = c("red", "blue"), pch = 1,
        ylab = "MSE", xlab = "Number of Trees",
        main = "Training vs. Test MSE by Number of Trees",
        ylim = c(0, max(test_mse_ntree) * 1.1))  # start at 0
legend("topright", legend = c("Train", "Test"), col = c("red", "blue"), pch = 1)
dev.off()