library(tidyverse)

merged <- read_csv("data/processed/merged.csv")
train  <- read_csv("data/processed/train.csv")
tune   <- read_csv("data/processed/tune.csv")
test   <- read_csv("data/processed/test.csv")

row_count_table <- data.frame(
  Stage = c("Total Rows", 
            "Train Set (2013-16)", 
            "Tune Set (2016-17)", 
            "Test Set (2017-18)"),
  Row_Count = c(nrow(merged), 
                nrow(train), 
                nrow(tune), 
                nrow(test)),
  Description = c("Total Rows after cleaning", 
                  "Training data", 
                  "Development year for tuning", 
                  "Final evaluation year"),
  stringsAsFactors = FALSE
)

write.csv(row_count_table, "data/processed/row_counts_summary.csv", row.names = FALSE)
