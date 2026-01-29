library(terra)

# ---- paths ----
chm_dir  <- "C:/Users/terschan/Downloads/building_metrics/chmfill/"
out_dir  <- "C:/Users/terschan/Downloads/building_metrics/chmfill"
out_file <- file.path(out_dir, "CHM_merged.tif")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- target CRS ----
target_crs <- "EPSG:3879"

# ---- list tiles ----
chm_files <- list.files(
  chm_dir,
  pattern = "\\.tif$",
  full.names = TRUE
)

# ---- read tiles ----
chm_list <- lapply(chm_files, function(f) {
  cat("Reading:", basename(f), "\n")
  r <- rast(f)
  
  # enforce CRS if missing / wrong
  if (is.na(crs(r)) || crs(r) != target_crs) {
    crs(r) <- target_crs
  }
  
  r
})

# ---- merge ----
cat("Merging tiles...\n")
chm_all <- do.call(merge, chm_list)

# sanity checks
print(res(chm_all))
print(crs(chm_all))
print(ncell(chm_all))

# ---- write output ----
writeRaster(
  chm_all,
  out_file,
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = c("COMPRESS=LZW", "TILED=YES")
)

cat("Merged CHM written to:\n", out_file, "\n")
