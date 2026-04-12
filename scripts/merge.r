install.packages("readr")
install.packages("dplyr")
library(dplyr)
library(readr)

attendance_df <- read_csv("attendance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))
demographics_df <- read_csv("demographics.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))

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

write_csv(merged_df, "data/processed/merged.csv")