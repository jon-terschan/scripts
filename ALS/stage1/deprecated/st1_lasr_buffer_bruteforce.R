# NOTES 
# My sixth attempt to parallelize and fifth attempt at an array job.
# Here, I gave up on trying to get the lasR pipeline to do what I want
# and realized I can just take the merged output and crop it to the core tiles origin destination
# with a second stage operation. This works, however it is not super memory efficient (~8 GB maxRAM) as the 
# merged point cloud at some point needs to be loaded into memory to clip it. 
# Since I only tested on a neighborhood of four, I was scared that a full neighborhood would become very inefficient.

library(lasR)
library(sf)
library(terra)
library(lidR)

# -------------------------
# Arguments
# -------------------------
args <- commandArgs(trailingOnly = TRUE)
tile_path <- args[1]
halo_dist <- 25

# -------------------------
# Read tile index
# -------------------------
tiles <- st_read(
  "/scratch/project_2001208/Jonathan/ALS/stage1/test/tile_index.gpkg",
  quiet = TRUE
)

core <- tiles[tiles$filename == tile_path, ]
stopifnot(nrow(core) == 1)

core_bbox <- st_bbox(core)

# -------------------------
# Find neighbors (halo)
# -------------------------
halo_geom <- st_buffer(core, halo_dist)
sel <- st_intersects(tiles, halo_geom, sparse = FALSE)[,1]
neighbors <- tiles[sel, ]
files_to_read <- neighbors$filename

cat("Core tile:", tile_path, "\n")
cat("Reading", length(files_to_read), "tiles\n")

# -------------------------
# Output paths (TEMP!)
# -------------------------
tile_id <- tools::file_path_sans_ext(basename(tile_path))
out_base <- "/scratch/project_2001208/Jonathan/ALS/stage1/test/output/tmp"

dtm_tmp     <- file.path(out_base, "dtm",     paste0(tile_id, "_DTM_tmp.tif"))
dsm_tmp     <- file.path(out_base, "dsm",     paste0(tile_id, "_DSM_tmp.tif"))
chm_tmp     <- file.path(out_base, "chm",     paste0(tile_id, "_CHM_tmp.tif"))
chmfill_tmp <- file.path(out_base, "chmfill", paste0(tile_id, "_CHM_fill_tmp.tif"))
norm_tmp    <- file.path(out_base, "norm",    paste0(tile_id, "_norm_tmp.laz"))

dir.create(dirname(dtm_tmp), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(dsm_tmp), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(chm_tmp), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(chmfill_tmp), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(norm_tmp), recursive=TRUE, showWarnings=FALSE)

# -------------------------
# lasR pipeline
# -------------------------
set_parallel_strategy(sequential())

# ---- algorithms / stages ----
del        <- lasR::triangulate(filter = keep_ground())

dtm        <- lasR::rasterize(1,   del,   ofile = dtm_tmp)
dsm        <- lasR::rasterize(0.5, "max", ofile = dsm_tmp)

norm       <- lasR::transform_with(del, "-")
write_norm <- lasR::write_las(ofile = norm_tmp)

chm        <- lasR::rasterize(0.5, "max", ofile = chm_tmp)
chmfill    <- lasR::pit_fill(chm, ofile = chmfill_tmp)

# ---- pipeline ----
pipeline <- 
  del +
  dtm +
  dsm +
  norm +
  write_norm +
  chm +
  chmfill

ctg <- readLAScatalog(files_to_read)
opt_chunk_size(ctg)   <- 0
opt_chunk_buffer(ctg) <- halo_dist

exec(pipeline, on = ctg, progress = FALSE)

cat("Stage 1 finished\n")


# -------------------------
# Final output paths
# -------------------------
out_base <- "/scratch/project_2001208/Jonathan/ALS/stage1/test/output"

dtm_file     <- file.path(out_base, "dtm",     paste0(tile_id, "_DTM.tif"))
dsm_file     <- file.path(out_base, "dsm",     paste0(tile_id, "_DSM.tif"))
chm_file     <- file.path(out_base, "chm",     paste0(tile_id, "_CHM.tif"))
chmfill_file <- file.path(out_base, "chmfill", paste0(tile_id, "_CHM_fill.tif"))
norm_file    <- file.path(out_base, "norm",    paste0(tile_id, "_norm.laz"))

dir.create(dirname(dtm_file), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(dsm_file), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(chm_file), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(chmfill_file), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(norm_file), recursive=TRUE, showWarnings=FALSE)

# -------------------------
# Raster clipping
# -------------------------
core_ext <- ext(
  core_bbox["xmin"],
  core_bbox["xmax"],
  core_bbox["ymin"],
  core_bbox["ymax"]
)

writeRaster(crop(rast(dtm_tmp),     core_ext), dtm_file, overwrite=TRUE)
writeRaster(crop(rast(dsm_tmp),     core_ext), dsm_file, overwrite=TRUE)
writeRaster(crop(rast(chm_tmp), core_ext), chm_file, overwrite=TRUE)
writeRaster(crop(rast(chmfill_tmp), core_ext), chmfill_file, overwrite=TRUE)

las <- readLAS(norm_tmp)

las_core <- clip_rectangle(
  las,
  core_bbox["xmin"],
  core_bbox["ymin"],
  core_bbox["xmax"],
  core_bbox["ymax"]
)

writeLAS(las_core, norm_file)

cat("Stage 2 finished\n")
