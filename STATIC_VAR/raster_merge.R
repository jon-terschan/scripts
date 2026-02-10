
# Merge CHM tiles (or any other raster tiles) into a large raster
# Inputs: folder of CHM tiles (or any other raster tiles)
# Outputs: a merged raster 
# -----------------------------------------------------------------------------------------------------------
# careful: NO CRS checking, so unified CRS and resolution/alignment is assumed for the input.

# --- merge alternative ---
library(terra) 

# ---- paths ----
in_dir   <- "C:/Users/terschan/Downloads/building_metrics/chmfill/"
tag <- "CHM_05m_HEL"   # tag for whatever is the input/output name

out_file <- file.path(in_dir, paste0("merged_", tag, ".tif"))
terraOptions(memfrac = 0.8) # set terra RAM limit aggressively for faster processing

# ---- list & merge ----
raster_files <- list.files(in_dir, pattern="\\.tif$", full.names=TRUE)
merged_raster <- terra::merge(raster_files)

merged_raster <- do.call(terra::merge, lapply(raster_files, terra::rast))

# ---- write output ----
writeRaster(
  merged_raster,
  out_file,
  overwrite = TRUE,
  gdal = c(
    "TILED=YES",
    "COMPRESS=LZW",
    "PREDICTOR=2",  
    "BIGTIFF=YES"
  )
)

