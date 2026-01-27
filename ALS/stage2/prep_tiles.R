# the purpose of this script is to prepare tiles for a buffering operation
library(lidR)
library(sf)

tiles_dir <- "/scratch/project_2001208/Jonathan/ALS/stage1/test/output/norm/"
out_dir   <- "/scratch/project_2001208/Jonathan/ALS/stage2/"

# Read tiles
ctg <- readLAScatalog(tiles_dir)

# Disable lidR chunking logic
opt_chunk_size(ctg)   <- 0
opt_chunk_buffer(ctg) <- 0

tiles_sf <- st_as_sf(ctg)

# reduce to needed info
tiles_sf <- tiles_sf[, c("geometry", "filename")]

# Deterministic ordering
# IMPORTANT to ensure stable ordering across runs
tiles_sf <- tiles_sf[order(tiles_sf$filename), ]

# Write outputs
gpkg_path <- file.path(out_dir, "tile_index.gpkg")
txt_path  <- file.path(out_dir, "tiles.txt")

st_write(tiles_sf, gpkg_path, delete_dsn = TRUE)

writeLines(tiles_sf$filename, txt_path)

cat("Prepared", nrow(tiles_sf), "tiles\n")
cat("Index:", gpkg_path, "\n")
cat("List: ", txt_path, "\n")

cat("DONE\n")
#softcode array size in slurm batch job
##SBATCH --array=1-$(wc -l < tiles.txt)