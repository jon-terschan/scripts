library(lasR)
library(sf)
library(terra)

# -------------------------
# Arguments
# -------------------------
args <- commandArgs(trailingOnly = TRUE)
tile_path <- args[1]

halo_dist <- 25   # meters

# Read tile index
tiles <- st_read(
  "/scratch/project_2001208/Jonathan/ALS/stage1/tile_index.gpkg",
  quiet = TRUE
)

# core tile
core <- tiles[tiles$filename == tile_path, ]
stopifnot(nrow(core) == 1)

# -------------------------
# Find neighbors
# -------------------------
halo_geom <- st_buffer(core, halo_dist)

sel <- st_intersects(tiles, halo_geom, sparse = FALSE)[,1]
neighbors <- tiles[sel, ]

files_to_read <- neighbors$filename

cat("Core tile:\n", tile_path, "\n")
cat("Reading", length(files_to_read), "tiles\n")

# -------------------------
# Output paths
# -------------------------
tile_id <- tools::file_path_sans_ext(basename(tile_path))

out_base <- "/scratch/project_2001208/Jonathan/ALS/stage1/output"

dtm_file <- file.path(out_base, "dtm", paste0(tile_id, "_DTM.tif"))
dsm_file <- file.path(out_base, "dsm", paste0(tile_id, "_DSM.tif"))
chm_file <- file.path(out_base, "chm", paste0(tile_id, "_CHM.tif"))

dir.create(dirname(dtm_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(dsm_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(chm_file), recursive = TRUE, showWarnings = FALSE)

# -------------------------
# lasR pipeline
# -------------------------
set_parallel_strategy(sequential())

del  <- triangulate(filter = keep_ground())
dtm  <- rasterize(1, del, ofile = dtm_file)
dsm  <- rasterize(0.5, "max", ofile = dsm_file)
norm <- transform_with(del, "-")
chm  <- rasterize(0.5, "max", ofile = chm_file)

pipeline <- del + dtm + dsm + norm + chm

exec(pipeline, on = files_to_read, progress = T)

# -------------------------
# Crop to core tile
# -------------------------
core_vect <- vect(core)

crop_and_write <- function(path) {
  r <- rast(path)
  r2 <- crop(r, core_vect)
  writeRaster(r2, path, overwrite = TRUE)
}

crop_and_write(dtm_file)
crop_and_write(dsm_file)
crop_and_write(chm_file)

cat("Finished tile:", tile_id, "\n")
