library(tidyverse)

demographics_df1 <- read_csv("data/raw/demographics2.csv", show_col_types = FALSE, locale = locale(grouping_mark = ",")) |>
  select(DBN, Year, `Economic Need Index`)

demographics_df2 <- read_csv("data/raw/demographics3.csv", show_col_types = FALSE, locale = locale(grouping_mark = ",")) |>
  select(DBN, Year, `Economic Need Index`)

demographics_df <- bind_rows(demographics_df1, demographics_df2) |>
  distinct(DBN, Year, .keep_all = TRUE) |>
mutate(
    `Economic Need Index` = as.numeric(str_replace(str_remove(`Economic Need Index`, "%"), ",", "."))
  )

demographics_df |>
  ggplot(aes(x = `Economic Need Index`, fill = Year, color = Year)) +
  geom_density(alpha = 0.3) +
  scale_fill_viridis_d() +
  scale_color_viridis_d() +
  labs(x = "Economic Need Index", y = "Density", fill = "Year", color = "Year") +
  theme_minimal()

ggsave("plots/diagnostics/eni_density_by_year.png")