library(tidyverse)
# Contains all scripts to create plots / graphs: run needed segment, not entire script

## Poly ##
poly_results <- read_csv("data/model_data/poly_results.csv")

# RMSE
poly_results |>
  mutate(degree = as.integer(str_remove(model, "poly_"))) |>
  ggplot(aes(x = degree, y = rmse, color = split)) +
  geom_line() + geom_point() +
  scale_x_continuous(breaks = 1:10) +
  scale_y_continuous(limits = c(10, NA)) +
  labs(x = "Polynomial Degree", y = "RMSE",
       title = "Train vs Test RMSE by Polynomial Degree") +
  theme_minimal()
ggsave("plots/poly_plots/RMSE.png")

# MSE
poly_results |>
  mutate(degree = as.integer(str_remove(model, "poly_"))) |>
  ggplot(aes(x = degree, y = mse, color = split)) +
  geom_line() + geom_point() +
  scale_x_continuous(breaks = 1:10) +
  labs(x = "Polynomial Degree", y = "MSE",
       title = "Train vs Test MSE by Polynomial Degree") +
  theme_minimal()
ggsave("plots/poly_plots/MSE.png")

# R^2 & Adjusted R^2
poly_results |>
  mutate(degree = as.integer(str_remove(model, "poly_"))) |>
  pivot_longer(cols = c(r2, adj_r2), names_to = "metric", values_to = "value") |>
  ggplot(aes(x = degree, y = value, color = split, linetype = metric)) +
  geom_line() + geom_point() +
  scale_x_continuous(breaks = 1:10) +
  scale_y_continuous(limits = c(0.3, 0.8)) +
  labs(x = "Polynomial Degree", y = "R²",
       title = "Train vs Test R² by Polynomial Degree",
       linetype = "Metric") +
  scale_linetype_manual(values = c("r2" = "solid", "adj_r2" = "dashed"),
                        labels = c("r2" = "R²", "adj_r2" = "Adj R²")) +
  theme_minimal()
ggsave("plots/poly_plots/r2_combined.png")

## Density Plot ##
train_df <- read_csv("data/processed/train.csv")
tune_df <- read_csv("data/processed/tune.csv")
test_df <- read_csv("data/processed/test.csv")

predictors <- c("Economic Need Index", "% Poverty", 
                "% English Language Learners", "% Students with Disabilities")

bind_rows(
  train_df |> mutate(split = "train"),
  tune_df  |> mutate(split = "tune"),
  test_df  |> mutate(split = "test")
) |>
pivot_longer(cols = all_of(predictors), names_to = "variable", values_to = "value") |>
  ggplot(aes(x = value, fill = split, color = split)) +
  geom_density(alpha = 0.3) +
  facet_wrap(~variable, scales = "free") +
  theme_minimal()
ggsave("plots/diagnostics/density_plot.png")
