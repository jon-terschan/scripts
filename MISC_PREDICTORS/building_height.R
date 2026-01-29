library(terra)

target_crs <- "EPSG:3879"

# ---- paths ----
chm_file  <- "C:/Users/terschan/Downloads/building_metrics/chmfill/CHM_merged.tif"
bldg_file <- "C:/Users/terschan/Downloads/building_metrics/bldgs_helsinki.gpkg"
out_dir   <- "C:/Users/terschan/Downloads/building_metrics"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- load CHM ----
chm <- rast(chm_file)

# enforce CRS if needed
if (is.na(crs(chm)) || crs(chm) != target_crs) {
  crs(chm) <- target_crs
}

# ---- load buildings ----
bldg <- vect(bldg_file)
bldg <- project(bldg, target_crs)

# ---- crop buildings to CHM extent (+ buffer for safety) ----
bldg <- crop(bldg, ext(chm) + 5)

# ---- small buffer to catch roof overhangs / alignment ----
bldg_buf <- buffer(bldg, width = 1)

# ---- rasterize building mask at CHM resolution ----
bldg_mask <- rasterize(
  bldg_buf,
  chm,
  field = 1,
  background = NA
)

# ---- mask CHM to buildings only ----
chm_bldg <- mask(chm, bldg_mask)

# ---- aggregate to 10 m ----
fact_10m <- round(10 / res(chm)[1])  # should be 20 for 0.5 m

# Max height (optional but often useful)
bldg_max_10m <- aggregate(
  chm_bldg,
  fact = fact_10m,
  fun = max,
  na.rm = TRUE
)

# 95th percentile height
bldg_h95_10m <- aggregate(
  chm_bldg,
  fact = fact_10m,
  fun = function(x) {
    if (all(is.na(x))) return(NA)
    quantile(x, probs = 0.95, na.rm = TRUE)
  }
)

# ---- write outputs ----
writeRaster(
  bldg_h95_10m,
  file.path(out_dir, "BLDG_HEIGHT_95Q_10m_Helsinki.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = c("COMPRESS=LZW", "TILED=YES")
)

writeRaster(
  bldg_max_10m,
  file.path(out_dir, "BLDG_HEIGHT_MAX_10m_Helsinki.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = c("COMPRESS=LZW", "TILED=YES")
)

# ---- quick sanity plots ----
plot(chm)
plot(bldg_mask)
plot(bldg_h95_10m)
