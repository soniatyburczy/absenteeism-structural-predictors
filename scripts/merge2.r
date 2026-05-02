library(tidyverse)
library(data.table)

attendance_df <- read_csv("data/raw/attendance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))
pr_16 <- read_csv("data/raw/performance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))

percent_cols <- c("ontrack_year1_2013", "graduation_rate_2013", "college_career_rate_2013", 
                  "ontrack_year1_2014", "graduation_rate_2014", "college_career_rate_2014",
                  "ontrack_year1_boro", "graduation_rate_boro", "college_career_rate_boro",
                  "pct_stu_enough_variety_2014", "pct_stu_safe_2014")


merged_df <- attendance_df |>
  rename(
    total_days = `# Total Days`,
    days_absent = `# Days Absent`,
    days_present = `# Days Present`,
    percent_attend = `% Attendance`,
    `20plus_days` = `# Contributing 20+ Total Days`,
    chronic_absent = `# Chronically Absent`,
    percent_chronic = `% Chronically Absent`
  ) |>
  
  
  mutate(
    across(c(total_days, days_absent, days_present, percent_attend, `20plus_days`, chronic_absent, percent_chronic),
           ~ as.numeric(gsub("%", "", .))),
    DBN = as.character(DBN)) |>
  group_by(DBN) |>
  summarise(across(c(total_days, days_absent, days_present, percent_attend, `20plus_days`, chronic_absent, percent_chronic), ~ mean(., na.rm = TRUE))) |>
  inner_join(pr_16 |> mutate(across(all_of(percent_cols), ~ as.numeric(gsub("%", "", .))),
                             dbn = as.character(dbn)),
             by = c("DBN" = "dbn")) |> 
  drop_na()

write_csv(merged_df, "data/processed/merged2.csv")