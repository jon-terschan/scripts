# -------------------------
# lasr stage 1 pipeline
# -------------------------
# INPUT: .las or .laz files of laser scanning data
# OUTPUT: DTM, DSM, CHM, CHM (pitfilled), and normalized point cloud (.laz)
# DEPENDENCIES: Alphabetically ordered file list (prep_tiles.R output).
# AUTHOR: Jonathan Terschanski
# -------------------------
# NOTES
# -------------------------
# Seventh and final attempt to parallelize and fifth attempt at an array job.
# Here, I realized that I could use lasR wildcard (*) mechanics to output everything
# in individual tiles, and then just find the correct tile (core tile) from the output
# and move it to a separate output file. This makes it much more memory effective.
# Everything is processed sequentially but with spatial context, so no edge artifacts.
# In the end, there is a bit of data dump in the form of the tmp folder.
# I guess I could write a second batch script to clean it up - I think doing it in the 
# batch job of this one will destroy everything as each individual script will execute the cleanup 
# and destroy folder dependencies.

# -------------------------
# PACKAGE DEPENDENCIES
# -------------------------
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

# -------------------------
# BUFFER AND NEIGHBORHOOD 
# -------------------------
# identifies the neighborhood tiles by a quick spatial query using the buffer coordinates
halo_geom <- st_buffer(core, halo_dist)
sel <- st_intersects(tiles, halo_geom, sparse = FALSE)[,1]
neighbors <- tiles[sel, ]
files_to_read <- neighbors$filename

# some text output
cat("Core tile:", tile_path, "\n")
cat("Reading", length(files_to_read), "tiles\n")

# -------------------------
# LASR PIPELINE
# -------------------------
# define tile id and temp folder
tile_id <- tools::file_path_sans_ext(basename(tile_path))
tmp_base <- file.path(
  "/scratch/project_2001208/Jonathan/ALS/stage1/test/output/tmp",
  tile_id
)

# lasr pipeline objects, lasr doesnt like to have them called in the actual pipeline
dtm_tmp     <- file.path(tmp_base, "dtm",     "*_DTM_tmp.tif")
dsm_tmp     <- file.path(tmp_base, "dsm",     "*_DSM_tmp.tif")
chm_tmp     <- file.path(tmp_base, "chm",     "*_CHM_tmp.tif")
chmfill_tmp <- file.path(tmp_base, "chmfill", "*_CHM_fill_tmp.tif")
norm_tmp    <- file.path(tmp_base, "norm",    "*_norm_tmp.laz")

# create temp output directories
dir.create(dirname(dtm_tmp), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(dsm_tmp), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(chm_tmp), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(chmfill_tmp), recursive=TRUE, showWarnings=FALSE)
dir.create(dirname(norm_tmp), recursive=TRUE, showWarnings=FALSE)

# -------------------------
# lasR pipeline
# -------------------------
# ----  pipeline stages ----
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

# ---- las catalog settings----
ctg <- readLAScatalog(files_to_read)   # reader
opt_chunk_size(ctg)   <- 0             # disable chunking, every chunk = 1 file
opt_chunk_buffer(ctg) <- halo_dist     # buffer size = halo size
opt_progress(ctg)     <- FALSE         # disable progress bar

# ---- execute pipeline ----
exec(pipeline, on = ctg, progress = FALSE)

cat("Stage 1 (pipeline) finished\n")

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
# Stage 2: keep only core tile outputs
# -------------------------
copy_core <- function(tmp_dir, suffix, final_file) {
  core_tmp <- file.path(tmp_dir, paste0(tile_id, suffix))
  if (!file.exists(core_tmp)) {
    stop("Missing core file: ", core_tmp)
  }
  file.copy(core_tmp, final_file, overwrite = TRUE)
}

# ---- copy core tile to final output folder ----
copy_core(file.path(tmp_base, "dtm"),     "_DTM_tmp.tif",      dtm_file)
copy_core(file.path(tmp_base, "dsm"),     "_DSM_tmp.tif",      dsm_file)
copy_core(file.path(tmp_base, "chm"),     "_CHM_tmp.tif",      chm_file)
copy_core(file.path(tmp_base, "chmfill"), "_CHM_fill_tmp.tif", chmfill_file)
copy_core(file.path(tmp_base, "norm"),    "_norm_tmp.laz",     norm_file)

cat("Stage 2 finished (core tile extracted)\n")