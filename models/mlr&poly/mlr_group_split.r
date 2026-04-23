# Original code by Khushi, minor fixes applied:
# 1. Fixed poly() call - poly(ENI, j) instead of poly(x + y + z, j)
# 2. Added na.rm=TRUE to mean() calls
# 3. Switched to png() saving for plot stability
# 4. Changed to grouped split by DBN to address school-level leakage
# Grouped split approach (set.seed(123), 80/20, grouped by DBN)

library(tidyverse)
library(janitor)
library(dplyr)
library(readr)
library(tidymodels)

# Step 1: Clean and Merge Datasets
attendance_df <- read_csv("data/raw/attendance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))
demographics_df <- read_csv("data/raw/demographics.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))

merged_df <- attendance_df %>%
  filter(Year != "2018-19") %>%
  inner_join(demographics_df, by = c("DBN", "Year")) %>%
  select(-Borough, -District, -`School Name.y`) %>%
  rename(`School Name` = `School Name.x`) %>%
  filter(Grade == "All Grades", `Demographic Variable` == "All Students") %>%
  mutate(
    across(starts_with("%"), ~ as.numeric(gsub("%", "", .))),
    `Economic Need Index` = as.numeric(gsub("%", "", `Economic Need Index`))
  )

merged_df <- na.omit(merged_df)
write_csv(merged_df, "merged.csv")

# Step 2: Grouped Split
set.seed(123)
split_df <- group_initial_split(merged_df, group = DBN, prop = .8)
train_df <- training(split_df)
test_df <- testing(split_df)

# Check distributions
summary(train_df$`% Chronically Absent`)
summary(test_df$`% Chronically Absent`)

# Linear Regression
lin_ord1 <- lm(`% Chronically Absent` ~ `Economic Need Index` + `% Poverty` + 
                 `% English Language Learners` + `% Students with Disabilities`, data = train_df)
summary(lin_ord1)

# Calculate MSE
pre_test <- predict(lin_ord1, test_df)
mse_test <- mean((test_df$`% Chronically Absent` - pre_test)^2, na.rm=TRUE)
mse_test

train_mse <- rep(0, 10)
test_mse <- rep(0, 10)
test_r2 <- rep(0, 10)
test_adj_r2 <- rep(0, 10)

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
png("plots/mlr_grouped_split/mse_plot_grouped.png")
matplot(1:10, cbind(train_mse, test_mse), type="b", 
col=c("red","blue"), pch=1,
ylab="Training vs. Test MSE", xlab="Degree of the Polynomials")
legend("topright", legend=c("Train","Test"), col=c("red","blue"), pch=1)
dev.off()

# R² plot (train and test, R² and Adj R²)
png("plots/mlr_grouped_split/r2_plot_grouped.png")
matplot(1:10, cbind(train_r2, train_adj_r2, test_r2, test_adj_r2), type="b",
col=c("red","salmon","darkgreen","purple"), pch=1, lty=1:4,
ylab="R²", xlab="Degree of the Polynomials",
main="Train vs. Test R² and Adjusted R²")
legend("bottomright", 
legend=c("Train R²","Train Adj R²","Test R²","Test Adj R²"), 
col=c("red","salmon","darkgreen","purple"), pch=1, lty=1:4)
dev.off()

# Diagnostic plots
png("plots/mlr_grouped_split/diagnostic_plots_grouped.png")
par(mfrow = c(2,2))
plot(lin_ord1)
dev.off()

# Save linear model results
pre_train_lin <- predict(lin_ord1, train_df)
train_mse_lin <- mean((train_df$`% Chronically Absent` - pre_train_lin)^2, na.rm=TRUE)

# Test R²
ss_res_test_lin <- sum((test_df$`% Chronically Absent` - pre_test)^2, na.rm=TRUE)
ss_tot_test_lin <- sum((test_df$`% Chronically Absent` - mean(test_df$`% Chronically Absent`, na.rm=TRUE))^2, na.rm=TRUE)
test_r2_lin <- 1 - ss_res_test_lin / ss_tot_test_lin

n_test_lin <- sum(!is.na(test_df$`% Chronically Absent`))
p_lin <- 4
test_adj_r2_lin <- 1 - (1 - test_r2_lin) * (n_test_lin - 1) / (n_test_lin - p_lin - 1)

linear_results <- data.frame(
  model = "linear",
  train_mse = train_mse_lin,
  test_mse = mse_test,
  train_r2 = summary(lin_ord1)$r.squared,
  train_adj_r2 = summary(lin_ord1)$adj.r.squared,
  test_r2 = test_r2_lin,
  test_adj_r2 = test_adj_r2_lin
)
write_csv(linear_results, "data/mlr_grouped_split/linear_results_grouped.csv")
poly_results <- data.frame(
  degree = 1:10,
  train_mse = train_mse,
  test_mse = test_mse,
  train_r2 = train_r2,
  train_adj_r2 = train_adj_r2,
  test_r2 = test_r2,
  test_adj_r2 = test_adj_r2
)
write_csv(poly_results, "data/mlr_grouped_split/poly_results_grouped.csv")