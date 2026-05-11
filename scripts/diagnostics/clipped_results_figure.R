library(tidyverse)

xgb_orig <- read_csv("data/model_data/xgb/xgb_results.csv") %>% mutate(type = "Unclipped")
xgb_clip <- read_csv("data/model_data/xgb/xgb_clipped.csv") %>% mutate(type = "Clipped")
rf_orig <- read_csv("data/model_data/rf/rf_results.csv") %>% mutate(type = "Unclipped")
rf_clip <- read_csv("data/model_data/rf/rf_clipped_results.csv") %>% mutate(type = "Clipped")

comparison_df <- bind_rows(xgb_orig, xgb_clip, rf_orig, rf_clip) %>%
  filter(split %in% c("tune", "test")) %>%
  mutate(model_group = str_extract(model, "^[a-z]+"))

ggplot(comparison_df, aes(x = split, y = rmse, group = type, color = type)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  facet_wrap(~model_group) +
  theme_minimal() +
  labs(
    title = "Clipping Impact Error Analysis",
    x = "Data Split",
    y = "RMSE",
    color = "Data Method"
  ) +
  scale_color_manual(values = c("Unclipped" = "#E41A1C", "Clipped" = "#377EB8"))

ggsave("plots/diagnostics/clipping_error_analysis_comparison.png", width = 8, height = 5)

#R^2 Stuff

r2_comparison <- bind_rows(xgb_orig, xgb_clip, rf_orig, rf_clip) %>%
  filter(split == "test") %>%
  mutate(
    model_id = if_else(str_detect(model, "xgb"), "XGBoost", "Random Forest")
  ) %>%
  select(model_id, type, r2) %>% 
  pivot_wider(names_from = type, values_from = r2) %>%
  mutate(
    r2_drop = Unclipped - Clipped,
    pct_variance_lost = (r2_drop / Unclipped) * 100
  )

print(r2_comparison)

ggplot(r2_comparison %>% pivot_longer(cols = c(Unclipped, Clipped), names_to = "Method", values_to = "R_Squared"), 
       aes(x = model_id, y = R_Squared, fill = Method)) +
  geom_col(position = "dodge") +
  theme_minimal() +
  scale_fill_manual(values = c("Unclipped" = "#E41A1C", "Clipped" = "#377EB8")) +
  labs(title = "R-Squared Comparison",
       y = "R-Squared")
