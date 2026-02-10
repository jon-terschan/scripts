# training data generation split
# output, training data table
source("scripts/00_config.R")

# load and align all static rasters

static_files <- list.files(static, pattern = "\\.tif$", full.names = TRUE)

static_r <- rast(static_files)

# load all sensor locations as tables
# create dynamic predictors (time) and join ERA5 info to it
# extract static predictors to sensor locations and create train data table
