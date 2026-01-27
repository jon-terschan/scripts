#install.packages("lasR", repos = "https://r-lidar.r-universe.dev")
library(lasR)

# ===== Paths =====
input_dir  <- "/scratch/project_2001208/Jonathan/ALS/stage1/test/tiles"
dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- "/scratch/project_2001208/Jonathan/ALS/stage1/test/output"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dtm_dir <- file.path(output_dir, "dtm")
dsm_dir <- file.path(output_dir, "dsm")
chm_dir <- file.path(output_dir, "chm")
norm_dir <- file.path(output_dir, "normalized")

dir.create(dtm_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(dsm_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(chm_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(norm_dir, recursive = TRUE, showWarnings = FALSE)

# ===== Parallel strategy =====
set_parallel_strategy(concurrent_files(16))  # match Slurm cpus

# ===== Pipeline steps =====
# define individual pipeline steps

del = triangulate(filter = keep_ground())

norm = transform_with(del, "-")

dtm = rasterize(1, del, ofile = file.path(dtm_dir, "DTM.tif"))

dsm <- rasterize(0.5, "max", ofile = file.path(dsm_dir, "DSM.tif"))

chm = rasterize(0.5, "max", ofile = file.path(chm_dir, "CHM.tif"))

chm_fill = pit_fill(chm, ofile = file.path(chm_dir, "CHM_fill.tif"))

write_norm = write_las(file.path(norm_dir, "/*_norm.laz"))

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
exec(pipeline, on = input_dir, progress = T)
