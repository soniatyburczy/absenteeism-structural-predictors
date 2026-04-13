# Temporal split approach (train: 2013-2016, test: 2017-2018)
# Based on Khushi's structure with split method changed
# See mlr_og.r for random split version for comparison

library(tidyverse)
test_df <- read_csv("data/processed/test.csv")
train_df <- read_csv("data/processed/train.csv")
lin_ord1 <- lm(`% Chronically Absent` ~ `Economic Need Index` + `% Poverty` + 
`% English Language Learners` + `% Students with Disabilities`, data = train_df)
summary(lin_ord1)

# Calculate MSE
pre_test <- predict(lin_ord1, test_df)
mse_test <- mean((test_df$`% Chronically Absent` - pre_test)^2, na.rm=TRUE)
mse_test

# Find Best Model Order
train_mse <- rep(0, 10)
test_mse <- rep(0, 10)
test_r2 <- rep(0, 10)
test_adj_r2 <- rep(0, 10)
train_r2 <- rep(0, 10)
train_adj_r2 <- rep(0, 10)

for (j in 1:10){
  mod <- lm(`% Chronically Absent` ~ poly(`Economic Need Index`, j, raw=TRUE) + 
  `% Poverty` + `% English Language Learners` + 
  `% Students with Disabilities`, data = train_df)
  
  pre_train2 <- predict(mod, train_df)
  train_mse[j] <- mean((train_df$`% Chronically Absent` - pre_train2)^2, na.rm=TRUE)
  
  pre_test2 <- predict(mod, test_df)
  test_mse[j] <- mean((test_df$`% Chronically Absent` - pre_test2)^2, na.rm=TRUE)
  
  # R² on test set
  ss_res_test <- sum((test_df$`% Chronically Absent` - pre_test2)^2, na.rm=TRUE)
  ss_tot_test <- sum((test_df$`% Chronically Absent` - mean(test_df$`% Chronically Absent`, na.rm=TRUE))^2, na.rm=TRUE)
  test_r2[j] <- 1 - ss_res_test/ss_tot_test
  n_test <- sum(!is.na(test_df$`% Chronically Absent`))
  p <- 3 + j
  test_adj_r2[j] <- 1 - (1 - test_r2[j]) * (n_test - 1) / (n_test - p - 1)
  
  # R² on train set
  ss_res_train <- sum((train_df$`% Chronically Absent` - pre_train2)^2, na.rm=TRUE)
  ss_tot_train <- sum((train_df$`% Chronically Absent` - mean(train_df$`% Chronically Absent`, na.rm=TRUE))^2, na.rm=TRUE)
  train_r2[j] <- 1 - ss_res_train/ss_tot_train
  n_train <- sum(!is.na(train_df$`% Chronically Absent`))
  train_adj_r2[j] <- 1 - (1 - train_r2[j]) * (n_train - 1) / (n_train - p - 1)
}

# MSE plot
png("plots/mlr_temporal_split/mse_plot_temporal.png")
matplot(1:10, cbind(train_mse, test_mse), type="b", 
col=c("red","blue"), pch=1,
ylab="Training vs. Test MSE", xlab="Degree of the Polynomials")
legend("topright", legend=c("Train","Test"), col=c("red","blue"), pch=1)
dev.off()

# R² plot (train and test, R² and Adj R²)
png("plots/mlr_temporal_split/r2_plot_temporal.png")
matplot(1:10, cbind(train_r2, train_adj_r2, test_r2, test_adj_r2), type="b",
col=c("red","salmon","darkgreen","purple"), pch=1, lty=1:4,
ylab="R²", xlab="Degree of the Polynomials",
main="Train vs. Test R² and Adjusted R²")
legend("bottomright", 
legend=c("Train R²","Train Adj R²","Test R²","Test Adj R²"), 
col=c("red","salmon","darkgreen","purple"), pch=1, lty=1:4)
dev.off()

# Diagnostic plots
png("plots/mlr_temporal_split/diagnostic_plots_temporal.png")
par(mfrow = c(2,2))
plot(lin_ord1)
dev.off()

# Save linear model results
linear_results <- data.frame(
  model = "linear",
  train_mse = mean((train_df$`% Chronically Absent` - predict(lin_ord1, train_df))^2, na.rm=TRUE),
  test_mse = mse_test,
  r_squared = summary(lin_ord1)$r.squared,
  adj_r_squared = summary(lin_ord1)$adj.r.squared
)
write_csv(linear_results, "data/mlr_temporal_split/linear_results_temporal.csv")

poly_results <- data.frame(
  degree = 1:10,
  train_mse = train_mse,
  test_mse = test_mse,
  train_r2 = train_r2,
  train_adj_r2 = train_adj_r2,
  test_r2 = test_r2,
  test_adj_r2 = test_adj_r2
)
write_csv(poly_results, "data/mlr_temporal_split/poly_results_temporal.csv")