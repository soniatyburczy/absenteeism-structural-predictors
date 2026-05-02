library(tidyverse)

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