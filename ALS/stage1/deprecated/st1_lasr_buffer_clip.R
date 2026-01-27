# NOTES 
# My fourth attempt to parallelize and third attempt at an array job.
# Another attempt at implementing a buffer. This one reads all the neighborhood files,
# clips them to the target file + buffer, then runs the pipeline over the clipped point cloud
# before, in the end, clipping to the original extent.
# This would work, but its extremely unefficient memory-wise because the whole neighborhood
# needs to be loaded to RAM in the beginning.

library(lasR)
library(lidR)
library(sf)
library(terra)

# -------------------------
# Arguments
# -------------------------
args <- commandArgs(trailingOnly = TRUE)
tile_path <- args[1]

halo_dist <- 25   # meters

# -------------------------
# Read tile index
# -------------------------
tiles <- st_read(
  "/scratch/project_2001208/Jonathan/ALS/stage1/test/tile_index.gpkg",
  quiet = TRUE
)

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
# ?? EXPLICIT POINT CLIPPING (NEW)
# -------------------------
cat("Reading and spatially clipping point cloud...\n")

las <- readLAS(files_to_read, select = "xyzic")

if (is.empty(las)) {
  stop("No points read from input tiles")
}
# -------------------------
# Fix CRS mismatch (IMPORTANT)
# -------------------------
tile_crs <- st_crs(tiles)

if (is.na(st_crs(las))) {
  message("LAS has no CRS ? assigning CRS from tile index")
  st_crs(las) <- tile_crs
} else if (st_crs(las) != tile_crs) {
  message("Reprojecting LAS to tile CRS")
  las <- lidR::lastransform(las, tile_crs)
}

# Clip to core + halo geometry
las <- clip_roi(las, halo_geom)

if (is.empty(las)) {
  stop("No points left after spatial clipping")
}

cat("Points after clipping:", npoints(las), "\n")

# -------------------------
# Output paths
# -------------------------
tile_id <- tools::file_path_sans_ext(basename(tile_path))

out_base <- "/scratch/project_2001208/Jonathan/ALS/stage1/test/output"

dtm_file     <- file.path(out_base, "dtm",     paste0(tile_id, "_DTM.tif"))
dsm_file     <- file.path(out_base, "dsm",     paste0(tile_id, "_DSM.tif"))
chm_file     <- file.path(out_base, "chm",     paste0(tile_id, "_CHM.tif"))
chmfill_file <- file.path(out_base, "chmfill", paste0(tile_id, "_CHM_fill.tif"))

dir.create(dirname(dtm_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(dsm_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(chm_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(chmfill_file), recursive = TRUE, showWarnings = FALSE)

# -------------------------
# lasR pipeline
# -------------------------
set_parallel_strategy(sequential())

del  <- lasR::triangulate(filter = keep_ground())
dtm  <- lasR::rasterize(1, del, ofile = dtm_file)
dsm  <- lasR::rasterize(0.5, "max", ofile = dsm_file)
norm <- lasR::transform_with(del, "-")
chm  <- lasR::rasterize(0.5, "max", ofile = chm_file)
chm_fill <- lasR::pit_fill(chm, ofile = chmfill_file)

pipeline <- del + dtm + dsm + norm + chm + chm_fill

cat("Running lasR pipeline on clipped point cloud...\n")

exec(pipeline, on = las, progress = TRUE)

# -------------------------
# Crop rasters back to core tile
# -------------------------
core_vect <- vect(core)

crop_and_write <- function(path) {
  r  <- rast(path)
  r2 <- crop(r, core_vect)
  writeRaster(r2, path, overwrite = TRUE)
}

crop_and_write(dtm_file)
crop_and_write(dsm_file)
crop_and_write(chm_file)
crop_and_write(chmfill_file)

cat("Finished tile:", tile_id, "\n")
