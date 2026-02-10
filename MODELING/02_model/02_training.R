# training table input
# baseline model creation
source("scripts/00_config.R")


predictors <- setdiff(
  names(df),
  c("temp", "time", "fold", "id")
)

rf <- ranger(
  formula = temp ~ .,
  data = df[, c("temp", predictors)],
  num.trees = 800,
  mtry = floor(sqrt(length(predictors))),
  min.node.size = 10,
  importance = "permutation",
  respect.unordered.factors = "order"
)
