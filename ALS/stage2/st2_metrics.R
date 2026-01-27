# -------------------------
# Stage 2 RASTERIZE CANOPY METRICS
# -------------------------

library(lidR)
library(terra)

# -------------------------
# Args
# -------------------------
args <- commandArgs(trailingOnly = TRUE)
norm_file <- args[1]

tile_id <- tools::file_path_sans_ext(basename(norm_file))
cat("Processing tile:", tile_id, "\n")

# -------------------------
# Params
# -------------------------
res             <- 5
canopy_height   <- 2
z_min           <- 0.2
pai_k           <- 0.5
vci_bins        <- c(0, 2, 5, 10, 15, 20, Inf)
min_points_cell <- 3
upper_canopy_height <- 10  # meters

# -------------------------
# Read LAS
# -------------------------
las <- readLAS(norm_file)

names(las@data)
summary(las@data$ScanAngleRank)
# -------------------------
# Support raster (returns per cell)
# -------------------------
n_returns <- grid_metrics(
  las,
  ~ length(Z),
  res = res
)
n_returns <- rast(n_returns)

# -------------------------
# Canopy Cover (%)
# -------------------------
cc_fun <- function(z) {
  z <- z[z > z_min]
  if (length(z) < min_points_cell) return(NA_real_)
  sum(z > canopy_height) / length(z)
}

cc <- grid_metrics(
  las,
  ~ cc_fun(Z),
  res = res
)
cc <- rast(cc)

# NA ? 0 only where LiDAR support exists
zero_cc <- cc * 0
cc <- cover(cc, zero_cc)
cc <- mask(cc, n_returns > 0)

# -------------------------
# VCI (Shannon entropy)
# -------------------------
vci_fun <- function(z) {
  z <- z[z > z_min]
  if (length(z) < min_points_cell) return(NA_real_)
  bins <- cut(z, breaks = vci_bins, include.lowest = TRUE)
  p <- prop.table(table(bins))
  -sum(p * log(p))
}

vci <- grid_metrics(
  las,
  ~ vci_fun(Z),
  res = res
)
vci <- rast(vci)

# -------------------------
# PAI (gap fraction, classic)
# -------------------------
pai_fun <- function(z) {
  z <- z[z > z_min]
  if (length(z) < min_points_cell) return(NA_real_)
  gf <- sum(z < canopy_height) / length(z)
  if (gf <= 0) return(NA_real_)
  -log(gf) / pai_k
}

pai <- grid_metrics(
  las,
  ~ pai_fun(Z),
  res = res
)
pai <- rast(pai)

# -------------------------
# Canopy Closure (angle-weighted)
# -------------------------

closure_fun <- function(z, ang) {
  keep <- z > canopy_height & z > z_min
  if (sum(keep) < min_points_cell) return(NA_real_)

  # clamp extreme scan angles (recommended)
  theta_all  <- pmin(abs(ang), 15) * pi / 180
  theta_keep <- pmin(abs(ang[keep]), 15) * pi / 180

  w_all  <- 1 / cos(theta_all)
  w_keep <- 1 / cos(theta_keep)

  sum(w_keep) / sum(w_all)
}

closure <- grid_metrics(
  las,
  ~ closure_fun(Z, ScanAngleRank),
  res = res
)

closure <- rast(closure)

# Mask to supported cells
closure <- mask(closure, n_returns > 0)


# -------------------------
# Upper canopy cover
# -------------------------

ucc_fun <- function(z) {
  z <- z[z > z_min]
  if (length(z) < min_points_cell) return(NA_real_)
  sum(z > upper_canopy_height) / length(z)
}


ucc <- grid_metrics(
  las,
  ~ ucc_fun(Z),
  res = res
)

ucc <- rast(ucc)

ucc <- mask(ucc, n_returns > 0)

# -------------------------
# Output paths
# -------------------------
out_base <- "/scratch/project_2001208/Jonathan/ALS/stage2/output"

cc_file  <- file.path(out_base, "cc",  paste0(tile_id, "_CC_", res, "m.tif"))
vci_file <- file.path(out_base, "vci", paste0(tile_id, "_VCI_", res, "m.tif"))
pai_file <- file.path(out_base, "pai", paste0(tile_id, "_PAI_", res, "m.tif"))
n_file   <- file.path(out_base, "n_returns", paste0(tile_id, "_N_", res, "m.tif"))
closure_file <- file.path(out_base, "closure", paste0(tile_id, "_CLOS_", res, "m.tif"))
ucc_file <- file.path(out_base, "ucc", paste0(tile_id, "_UCC_", res, "m.tif"))

dir.create(dirname(ucc_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(closure_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(cc_file),  recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(vci_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(pai_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(n_file),   recursive = TRUE, showWarnings = FALSE)

# -------------------------
# Write rasters
# -------------------------
writeRaster(cc,  cc_file,  overwrite = TRUE)
writeRaster(vci, vci_file, overwrite = TRUE)
writeRaster(pai, pai_file, overwrite = TRUE)
writeRaster(n_returns, n_file, overwrite = TRUE)
writeRaster(closure, closure_file, overwrite = TRUE)
writeRaster(ucc, ucc_file, overwrite = TRUE)

cat("Stage 2 finished:", tile_id, "\n")
