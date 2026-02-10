## ------------------------------
## Project configuration
## ------------------------------

# Project root (safe on HPC + local)
root <- normalizePath(".")

paths <- list(
  raw        = file.path(root, "data/raw"),
  processed  = file.path(root, "data/processed"),
  static     = file.path(root, "data/processed/rasters_static"),
  dynamic    = file.path(root, "data/processed/rasters_dynamic"),
  points     = file.path(root, "data/processed/points"),
  models     = file.path(root, "models/rf"),
  preds      = file.path(root, "predictions/10m"),
  logs       = file.path(root, "logs")
)

# Spatial reference
crs_target <- "EPSG:3067"   # ETRS-TM35FIN

# Raster grid
grid_res <- 10              # meters
extent_name <- "helsinki"

# Random Forest defaults
rf_defaults <- list(
  num.trees = 800,
  min.node.size = 10,
  importance = "permutation",
  respect.unordered.factors = "order"
)

# Parallel settings (match SLURM)
n_cores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", 1))
