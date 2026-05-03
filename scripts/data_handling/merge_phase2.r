library(tidyverse)

attendance_df <- read_csv("data/raw/attendance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))
pr_16 <- read_csv("data/raw/performance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))

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
  mutate(across(starts_with("%"), ~ as.numeric(gsub("%", "", .)))) |>
  group_by(DBN) |>
  summarise(across(c(total_days, days_absent, days_present, percent_attend, `20plus_days`, chronic_absent, percent_chronic), mean, na.rm = TRUE)) |>
  inner_join(pr_16, by = c("DBN" = "dbn"))

merged_df <- na.omit(merged_df)
write_csv(merged_df, "data/processed/merged3.csv")