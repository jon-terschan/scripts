# NOTES 
# My second attempt to parallelize and first attempt at an array job.
# From here on, I decided to stick with array jobs. At this point I thought I
# was dealing with an embarrassingly parallel task, but although the majority of the operations 
# in the pipeline run independent, the triangulation requires spatial context from the neighboring tiles
# to avoid edge affects.
# So this thing works fine and is memory efficient, but it will cause edge effects. 

#install.packages("lasR", repos = "https://r-lidar.r-universe.dev")
library(lasR)

# ===== Paths =====
args <- commandArgs(trailingOnly = TRUE) 
tile <- args[1]

input_dir <- "/scratch/project_2001208/Jonathan/ALS/stage1/test/tiles" 
input_tile <- file.path(input_dir, tile)

output_dir <- "/scratch/project_2001208/Jonathan/ALS/stage1/test/output"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dtm_dir <- file.path(output_dir, "dtm")
dsm_dir <- file.path(output_dir, "dsm")
chm_dir <- file.path(output_dir, "chm")
norm_dir <- file.path(output_dir, "normalized")
chmfill_dir <- file.path(output_dir, "chm_fill")

dir.create(dtm_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(dsm_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(chm_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(norm_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(chmfill_dir, recursive = TRUE, showWarnings = FALSE)

tile_id <- tools::file_path_sans_ext(basename(tile))

# ===== Parallel strategy =====
# no multithreading
set_parallel_strategy(sequential())

# ===== Pipeline steps =====
# define individual pipeline steps

del = triangulate(filter = keep_ground())

norm = transform_with(del, "-")

dtm = rasterize(1, del, ofile = file.path(dtm_dir,  paste0(tile_id, "_DTM.tif")))

dsm <- rasterize(0.5, "max", ofile = file.path(dsm_dir, paste0(tile_id, "_DSM.tif")))

chm = rasterize(0.5, "max", ofile = file.path(chm_dir, paste0(tile_id, "_CHM.tif")))

chm_fill = pit_fill(chm, ofile = file.path(chmfill_dir, paste0(tile_id, "_CHM_fill.tif")))

write_norm = write_las(file.path(norm_dir, paste0(tile_id, "_norm.laz")))

# ===== Pipeline =====
pipeline = 
  del + # delauny triangulation of ground points
  dtm + # rasterize DTM based on del
  dsm + # rasterize DSM based on maxheight points
  norm + # normalize point cloud
  write_norm + # write output laz
  chm + # calculate DSM on normalized point cloud (CHM)
  chm_fill # pitfill on CHM

# ===== Execute =====
exec(pipeline, on = input_tile, progress = T)
