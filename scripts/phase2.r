library(dplyr)
library(readr)
library(data.table)


# using performance directory for 2016

attendance_df <- read_csv("attendance.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))
pr_16 <- read_csv("performance16.csv", show_col_types = FALSE, locale = locale(grouping_mark = ","))
setDT(attendance_df); setDT(pr_16)


setnames(attendance_df, 
         c("# Total Days", "# Days Absent", "# Days Present", "% Attendance", "# Contributing 20+ Total Days", "# Chronically Absent", "% Chronically Absent"), 
         c("total_days", "days_absent", "days_present", "percent_attend", "20plus_days", "chronic_absent", "percent_chronic"))

cols_to_avg <- c("total_days", "days_absent", "days_present", "percent_attend", "20plus_days", "chronic_absent", "percent_chronic")
attendance_df[, (cols_to_avg) := lapply(.SD, as.numeric), .SDcols = cols_to_avg]

attendance_df <- attendance_df[, lapply(.SD, mean, na.rm = TRUE), 
                               by = DBN, 
                               .SDcols = cols_to_avg]

merged_df <- pr_16[attendance_df, on = .(dbn = DBN), nomatch = NULL]
merged_df = na.omit(merged_df)
head(merged_df,100)

write_csv(merged_df, "data/processed/mergedph2.csv")
