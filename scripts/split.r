install.packages("readr")
library(readr)

merged_data <- read_csv("data/processed/merged.csv")

train <- merged_data[merged_data$Year %in% c("2013-14", "2014-15", "2015-16", "2016-17"), ]
test  <- merged_data[merged_data$Year %in% c("2017-18", "2018-19"), ]

write.csv(train, "data/processed/train.csv", row.names = FALSE)
write.csv(test,  "data/processed/test.csv",  row.names = FALSE)

