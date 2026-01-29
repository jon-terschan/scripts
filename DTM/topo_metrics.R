library(terra)

target_crs <- "EPSG:3879"

in_dir  <- "C:/Users/terschan/Downloads/topo_metrics/DTM"
out_dir <- "C:/Users/terschan/Downloads/topo_metrics/"

###################################
####### MERGE DTM #################
###################################
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

xyz_files <- list.files(in_dir, pattern = "\\.xyz$", full.names = TRUE)

cat("Reading", length(xyz_files), "XYZ tiles\n")

dtm_list <- lapply(xyz_files, function(f) {
  cat("  reading:", basename(f), "\n")
  xyz <- read.table(f)
  colnames(xyz) <- c("x", "y", "z")
  r <- rast(xyz, type = "xyz")
  crs(r) <- target_crs
  r
})

cat("Merging tiles...\n")
dtm_all <- do.call(merge, dtm_list)
res(dtm_all)     # should be 10 10
crs(dtm_all)     # EPSG:3857
ncell(dtm_all)

dtm_file <- file.path(out_dir, "topometrics/DTM_10m_Helsinki.tif") # merge DTM

writeRaster(
  dtm_all,
  dtm_file,
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = c("COMPRESS=LZW")
) 

###################################
####### WATER HANDLING ############
###################################
# CREATE GRID TEMPLATE
template_1m <- rast(
  ext(dtm_all),
  resolution = 1,
  crs = crs(dtm_all)
)

# CREATE OCEAN FRACTION MASK
ocean_poly <- vect("C:/Users/terschan/Downloads/topo_metrics/lc_sea_hel.gpkg")
ocean_1m <- rasterize(
  ocean_poly,
  template_1m,
  field = 1,
  background = 0
)
ocean_frac_10m <- aggregate(
  ocean_1m,
  fact = 10,
  fun = mean,
  na.rm = TRUE
)
writeRaster(
  ocean_frac_10m,
  file.path(out_dir, "watermask/OCEAN_FRAC_10m_Helsinki.tif"),
  overwrite = TRUE
)

# CREATE INLAND WATER BODY MASK
river_poly <- vect("C:/Users/terschan/Downloads/topo_metrics/lc_water_hel.gpkg")
water_1m  <- rasterize(river_poly, template_1m, field = 1, background = 0)
water_frac_10m <- aggregate(
  water_1m,
  fact = 10,
  fun = mean,
  na.rm = TRUE
)
writeRaster(
  water_frac_10m,
  file.path(out_dir, "watermask/WATER_FRAC_10m_Helsinki.tif"),
  overwrite = TRUE
)

# CREATE WATER AND OCEAN DISTANCE MAPS
river_bin  <- water_frac_10m  > 0
ocean_bin  <- ocean_frac_10m  > 0

river_src <- ifel(river_bin, 1, NA)
ocean_src <- ifel(ocean_bin, 1, NA)

dist_river <- distance(river_src) # euc dist
dist_ocean <- distance(ocean_src) # euclidian dist

dist_river <- clamp(dist_river, 0, 500) # cap effect size
dist_ocean <- clamp(dist_ocean, 0, 3000) # cap effect distance

writeRaster(
  dist_river,
  file.path(out_dir, "watermask/WATER_DIST_10m_Helsinki.tif"),
  overwrite = TRUE
)
writeRaster(
  dist_ocean,
  file.path(out_dir, "watermask/OCEAN_DIST_10m_Helsinki.tif"),
  overwrite = TRUE
)

###################################
####### TOPO METRICS ##############
###################################
cat("Computing slope & aspect...\n")

slope  <- terrain(dtm_all, "slope", unit = "degrees")
aspect <- terrain(dtm_all, "aspect", unit = "degrees")

# Aspect encoding for microclimate
eastness  <- sin(aspect * pi / 180)
southness <- -cos(aspect * pi / 180)

cat("Computing ruggedness (3x3 SD)...\n")
rugged <- focal(dtm_all, w = 3, fun = sd, na.rm = TRUE)

# masking, bit superfluous because DTM covers more
# than helsinki, whereas the mask does not 
#slope     <- mask(slope, ocean_mask, inverse = TRUE)
#eastness  <- mask(eastness, ocean_mask, inverse = TRUE)
#southness <- mask(southness, ocean_mask, inverse = TRUE)
#rugged    <- mask(rugged, ocean_mask, inverse = TRUE)

writeRaster(
  slope,
  file.path(out_dir, "topometrics/SLOPE_10m_Helsinki.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = "COMPRESS=LZW"
)

writeRaster(
  eastness,
  file.path(out_dir, "topometrics/EASTNESS_10m_Helsinki.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = "COMPRESS=LZW"
)

writeRaster(
  southness,
  file.path(out_dir, "topometrics/SOUTHNESS_10m_Helsinki.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = "COMPRESS=LZW"
)

writeRaster(
  rugged,
  file.path(out_dir, "topometrics/RUGGEDNESS_10m_Helsinki.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = "COMPRESS=LZW"
)
