library(terra)

bldg <- vect("C:/Users/terschan/Downloads/building_metrics/bldgs_helsinki.gpkg")
dtm_all <- rast("C:/Users/terschan/Downloads/topo_metrics/topometrics/DTM_10m_Helsinki.tif")
out_dir <- "C:/Users/terschan/Downloads/building_metrics/"

# Enforce CRS consistency
bldg <- project(bldg, crs(dtm_all))

template_1m <- rast(
  ext(dtm_all),
  resolution = 1,
  crs = crs(dtm_all)
)


bldg_1m <- rasterize(
  bldg,
  template_1m,
  field = 1,
  background = 0
)
bldg_frac_10m <- aggregate(
  bldg_1m,
  fact = 10,
  fun = mean,
  na.rm = TRUE
)

bldg_frac_mean_50m <- focal(
  bldg_frac_10m,
  w = 5,
  fun = mean,
  na.rm = TRUE
)

bldg_bin <- bldg_frac_10m > 0
bldg_src <- ifel(bldg_bin, 1, NA)

dist_building <- distance(bldg_src)
dist_building <- clamp(dist_building, 0, 1000)

plot(bldg_frac_10m)
plot(bldg_frac_mean_50m)
plot(dist_building)

#

writeRaster(
  bldg_frac_10m,
  file.path(out_dir, "BLDG_FRAC_10m.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = "COMPRESS=LZW"
)

writeRaster(
  bldg_frac_mean_50m,
  file.path(out_dir, "BLDG_FRAC_MEAN_50m.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = "COMPRESS=LZW"
)

writeRaster(
  dist_building,
  file.path(out_dir, "BLDG_DIST.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = "COMPRESS=LZW"
)

