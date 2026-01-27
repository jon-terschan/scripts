#install.packages("lasR", repos = "https://r-lidar.r-universe.dev")
library(lasR)
packageVersion("lasR")


source_folder = "\\\\ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/11.25/ALS/ALS_test"
setwd(source_folder)

# define individual pipeline steps

del = triangulate(filter = keep_ground())

norm = transform_with(del, "-")

dtm = rasterize(1, del, ofile = "DTM.tif")

dsm <- rasterize(0.5, "max", ofile = "DSM.tif")

chm = rasterize(0.5, "max", ofile = "CHM.tif")

chm_fill = pit_fill(chm, ofile = "CHM_fill.tif")

write_norm = write_las("normalized/*_norm.laz")

pipeline = 
  del + # delauny triangulation of ground points
  dtm + # rasterize DTM based on del
  dsm + # rasterize DSM based on maxheight points
  norm + # normalize point cloud
  write_norm + # write output laz
  chm + # calculate DSM on normalized point cloud (CHM)
  chm_fill # pitfill on CHM

exec(pipeline, on = source_folder, progress = T)
  

getwd()
