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
pre_test = predict(lin_ord1,test_df)

# Find Best Model Order
train_mse = rep(0,10)
test_mse = rep(0,10)

for (j in 1:10){
  mod <- lm(`% Chronically Absent` ~ poly(`Economic Need Index`, j, raw=TRUE) + 
              `% Poverty` + `% English Language Learners` + 
              `% Students with Disabilities`, data = train_df)
  pre_train2 <- predict(mod, train_df)
  train_mse[j] <- mean((train_df$`% Chronically Absent` - pre_train2)^2, na.rm=TRUE)
  pre_test2 <- predict(mod, test_df)
  test_mse[j] <- mean((test_df$`% Chronically Absent` - pre_test2)^2, na.rm=TRUE)
}

plot(1:10, train_mse, type="b", col="red",
     ylim=range(c(train_mse, test_mse), na.rm=TRUE),
     ylab="Training vs. Test MSE", xlab="Degree of the Polynomials")
lines(1:10, test_mse, type="b", col="blue")

# MSE plot
png("mse_plot.png")
matplot(1:10, cbind(train_mse, test_mse), type="b", 
        col=c("red","blue"), pch=1,
        ylab="Training vs. Test MSE", xlab="Degree of the Polynomials")
legend("topright", legend=c("Train","Test"), col=c("red","blue"), pch=1)
dev.off()

# Diagnostic plots
png("diagnostic_plots.png")
par(mfrow = c(2,2))
plot(lin_ord1)
dev.off()