# Fill holes in CHM merger
# Inputs: folder of CHM tiles (or any other raster tiles)
# Outputs: a merged raster 
# -----------------------------------------------------------------------------------------------------------
# careful: NO CRS checking, so unified CRS and resolution/alignment is assumed for the input.

library(terra)

in_file  <- "C:/Users/terschan/Downloads/building_metrics/chmfill/merged_CHM_05m_Hel.tif"
out_file <- "C:/Users/terschan/Downloads/building_metrics/chmfill/merged_CHM_05m_Hel_filled.tif"

chm <- rast(in_file)

# first pass (3x3)
na <- is.na(chm)
chm_filled <- chm
chm_filled[na] <- focal(chm, w = 3, fun = max, na.rm = TRUE)[na]

# second pass (5x5), only if needed
if (global(is.na(chm_filled), "sum")[1] > 0) {
  na <- is.na(chm_filled)
  chm_filled[na] <- focal(chm_filled, w = 5, fun = max, na.rm = TRUE)[na]
}

writeRaster(
  chm_filled,
  out_file,
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = c("TILED=YES", "COMPRESS=LZW", "PREDICTOR=2", "BIGTIFF=YES")
)
