rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2, na.rm = TRUE))
}

mse <- function(actual, predicted) {
  mean((actual - predicted)^2, na.rm=TRUE)
}

r2 <- function(actual, predicted) {
  ss_res <- sum((actual - predicted)^2, na.rm = TRUE)
  ss_tot <- sum((actual - mean(actual, na.rm = TRUE))^2, na.rm = TRUE)
  1 - (ss_res / ss_tot)
}

adj_r2 <- function(actual, predicted, p) {
  n <- length(actual)
  r2_val <- r2(actual, predicted)
  1 - (1 - r2_val) * (n - 1) / (n - p - 1)
}

evaluate_splits <- function(model, splits, n_predictors, model_name) {
  purrr::map_dfr(names(splits), function(name) {
    df     <- splits[[name]]
    preds  <- predict(model, df)
    actual <- df$`% Chronically Absent`
    data.frame(
      model  = model_name,
      split  = name,
      mse    = mse(actual, preds),
      rmse   = rmse(actual, preds),
      r2     = r2(actual, preds),
      adj_r2 = adj_r2(actual, preds, n_predictors)
    )
  })
}