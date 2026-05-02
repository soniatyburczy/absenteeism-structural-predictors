library(tidyverse)
library(data.table)

attendance_df <- read_csv("data/raw/attendance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))
pr_16 <- read_csv("data/raw/performance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))

percent_cols <- c("ontrack_year1_2013", "graduation_rate_2013", "college_career_rate_2013", 
                  "ontrack_year1_2014", "graduation_rate_2014", "college_career_rate_2014",
                  "ontrack_year1_boro", "graduation_rate_boro", "college_career_rate_boro",
                  "pct_stu_enough_variety_2014", "pct_stu_safe_2014")

pr_16[, (percent_cols) := lapply(.SD, function(x) as.numeric(gsub("%", "", x))), .SDcols = percent_cols]

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
write_csv(merged_df, "data/processed/merged2.csv")

print(nrow(attendance_df))
print(nrow(pr_16))
print(head(attendance_df$DBN))
print(head(pr_16$dbn))
