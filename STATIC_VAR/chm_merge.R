
# Merge CHM tiles into a large raster
# Inputs: folder of CHM tiles
# Outputs: a merged CHM raster of the whole area
# -----------------------------------------------------------------------------------------------------------
# 

# --- header ---
library(terra)

chm_dir  <- "C:/Users/terschan/Downloads/building_metrics/chmfill/"
out_dir  <- "C:/Users/terschan/Downloads/building_metrics/chmfill"
out_file <- file.path(out_dir, "CHM_merged.tif")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

target_crs <- "EPSG:3879"

# --- processing ---
# list files
chm_files <- list.files(
  chm_dir,
  pattern = "\\.tif$",
  full.names = TRUE
)

# read files
chm_list <- lapply(chm_files, function(f) {
  cat("Reading:", basename(f), "\n")
  r <- rast(f)
  
  # enforce CRS
  if (is.na(crs(r)) || crs(r) != target_crs) {
    crs(r) <- target_crs
  }
  
  r
})

# merge
cat("Merging tiles! \n")
chm_all <- do.call(merge, chm_list)

# ---- write output ----
writeRaster(
  chm_all,
  out_file,
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = c("COMPRESS=LZW", "TILED=YES")
)
