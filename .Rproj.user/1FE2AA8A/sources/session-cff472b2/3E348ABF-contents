library(tidyverse)

attendance_df <- read_csv("data/raw/attendance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))
demographics_df <- read_csv("data/raw/demographics2.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))

merged_df <- attendance_df |>
  filter(Year == "2018-19") |>
  inner_join(demographics_df, by = c("DBN", "Year")) |>
  select(-Borough, -District, -`School Name.y`) |>
  rename(`School Name` = `School Name.x`) |>
  mutate(
    across(starts_with("%"), ~ as.numeric(str_replace(str_remove(., "%"), ",", "."))),
    `Economic Need Index` = as.numeric(str_replace(str_remove(`Economic Need Index`, "%"), ",", "."))
  )
merged_df <- merged_df |>
  mutate(
    across(where(is.character) & !c(DBN, `School Name`, `Report Type`, Year), 
          ~ suppressWarnings(as.numeric(str_replace(., ",", "."))))
  )
write_csv(merged_df, "data/processed/2018_2019.csv")
