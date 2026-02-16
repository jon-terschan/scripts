library(terra)

processed_dir <- "processed_tiles"
index_file <- "tiles/tile_inner_index.csv"

tile_index <- read.csv(index_file)

tiles_trimmed <- list()

for (i in 1:nrow(tile_index)) {

  tile_id <- tile_index$tile_id[i]

  tile_file <- file.path(
    processed_dir,
    paste0("svf_tile_", sprintf("%02d", tile_id), ".tif")
  )

  r_tile <- rast(tile_file)

  ext_inner <- ext(
    tile_index$xmin[i],
    tile_index$xmax[i],
    tile_index$ymin[i],
    tile_index$ymax[i]
  )

  r_trim <- crop(r_tile, ext_inner, snap="out")

  tiles_trimmed[[i]] <- r_trim

  cat("Trimmed tile", tile_id, "\n")
}

# Merge without resampling
svf_merged <- do.call(mosaic, c(tiles_trimmed, fun="first"))

writeRaster(
  svf_merged,
  "SVF_merged_final.tif",
  overwrite=TRUE,
  gdal=c("COMPRESS=DEFLATE")
)
