# Original code by Khushi, minor fixes applied:
# 1. Fixed poly() call - poly(ENI, j) instead of poly(x + y + z, j)
# 2. Added na.rm=TRUE to mean() calls
# 3. Switched to png() saving for plot stability

# Random split approach (set.seed(123), 80/20)

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

# Step 2: Random Split (Khushi's approach)
set.seed(123)
split_df <- initial_split(merged_df, prop = .8)
train_df <- training(split_df)
test_df <- testing(split_df)

# Linear Regression
lin_ord1 <- lm(`% Chronically Absent` ~ `Economic Need Index` + `% Poverty` + 
                 `% English Language Learners` + `% Students with Disabilities`, data = train_df)
summary(lin_ord1)

# Calculate MSE
pre_test <- predict(lin_ord1, test_df)
mse_test <- mean((test_df$`% Chronically Absent` - pre_test)^2, na.rm=TRUE)
mse_test

# Find Best Polynomial Order (fixed poly call)
train_mse <- rep(0, 10)
test_mse <- rep(0, 10)

for (j in 1:10){
  mod <- lm(`% Chronically Absent` ~ poly(`Economic Need Index`, j, raw=TRUE) + 
              `% Poverty` + `% English Language Learners` + 
              `% Students with Disabilities`, data = train_df)
  pre_train2 <- predict(mod, train_df)
  train_mse[j] <- mean((train_df$`% Chronically Absent` - pre_train2)^2, na.rm=TRUE)
  pre_test2 <- predict(mod, test_df)
  test_mse[j] <- mean((test_df$`% Chronically Absent` - pre_test2)^2, na.rm=TRUE)
}

# MSE plot
png("mse_plot_random.png")
matplot(1:10, cbind(train_mse, test_mse), type="b", 
        col=c("red","blue"), pch=1,
        ylab="Training vs. Test MSE", xlab="Degree of the Polynomials")
legend("topright", legend=c("Train","Test"), col=c("red","blue"), pch=1)
dev.off()

# Diagnostic plots
png("diagnostic_plots_random.png")
par(mfrow = c(2,2))
plot(lin_ord1)
dev.off()