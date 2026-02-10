# training data generation split
# output, training data table
source("scripts/00_config.R")

##############################################################
# ----- CONVERT CLF FORMAT TO LONG, AGGREGATE TO HOURLY  ----- 
##############################################################
library(readr)
library(dplyr)
library(tidyr)
library(lubridate)

# folder with CSVs
csv_dir <- "//ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/11.25/processed/4_finetuning/output"

files <- list.files(
  csv_dir,
  pattern = "\\.csv$",
  full.names = TRUE
)

# empty list to collect results
out <- vector("list", length(files))

for (i in seq_along(files)) {
  f <- files[i]
  # numeric sensor ID only
  sensor_id <- sub("^[^_]+_([0-9]+).*", "\\1", basename(f)) # absurd regex to extract the numeric part (sensor id)
  df <- read_csv(f, show_col_types = FALSE) # read csv
  # ensure OOS exists
  if (!"OOS" %in% names(df)) {  # might have forgotten it somewhere
    df$OOS <- 0
  }

  df_hourly <- df %>%
    pivot_longer(
      cols = starts_with("t"),
      names_to = "sensor_channel",
      values_to = "temp"
    ) %>%
    mutate(
      time = as.POSIXct(datetime, tz = "UTC"),
      sensor_id = sensor_id
    ) %>%
    select(-datetime) %>%
    mutate(
      time = lubridate::floor_date(time, "hour")
    ) %>%
    group_by(sensor_id, sensor_channel, time) %>%
    summarise(
      temp = mean(temp, na.rm = TRUE),
      SMC  = mean(SMC,  na.rm = TRUE),
      OOS  = as.integer(any(OOS == 1)),
      .groups = "drop"
    ) %>%
    mutate(
      temp = ifelse(is.nan(temp), NA_real_, temp)
    )

  out[[i]] <- df_hourly
}

df_all_hourly <- bind_rows(out)
#glimpse(df_all_hourly) #check integrity

saveRDS(df_all_hourly, file = "//ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/df_all_hourly.rds")

# post long transform cleanup
df_all_hourly <- readRDS("//ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/df_all_hourly.rds")
df_t3_summer <- df_all_hourly %>%
  filter(
    sensor_channel == "t3",
    OOS == 0,
    !is.na(temp),
    yday(time) >= 140,   # May 20
    yday(time) <= 253    # Sep 10
  )
saveRDS(df_t3_summer, file = "//ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/train_summer.rds")

glimpse(df_t3_summer)

##############################################################
# ----- JOIN TRAINING DATA WITH SPATIAL INDEX FILE ----------- 
##############################################################
library(sf)
library(dplyr)

# target CRS
target_crs <- 3879  # ETRS-TM35FIN

# read original and current tile indeces
gpk1 <- st_read(
  "//ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/helmo_map/helmostatus_11.25.gpkg",
  quiet = TRUE
) %>%
  st_transform(target_crs) %>%
  transmute(
    sensor_id = as.character(SERIAL),
    geom
  )

gpk2 <- st_read(
  "//ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/helmo_map/helmostatus_original.gpkg",
  quiet = TRUE
) %>%
  st_transform(target_crs) %>%
  transmute(
    sensor_id = as.character(SERIAL),
    geom
  )

# combine indices with pref for the newer one (but fill missing sensors from gpkg2)
stations <- bind_rows(
  gpk1,
  gpk2 %>%
    filter(!sensor_id %in% gpk1$sensor_id)
)

# join train data with spatial index
df_train <- df_t3_summer %>%
  left_join(
    stations %>% select(sensor_id, geom),
    by = "sensor_id"
  )

# convert to sf object for spatial index and later spatial joins with rasters
df_train_sf <- st_as_sf(
  df_train,
  sf_column_name = "geom",
  crs = 3879
)

st_write(df_train_sf,
  "//ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/stations_training.gpkg",
  delete_dsn = TRUE
)

##############################################################
# ----- LOAD AND ALIGN ALL STATIC RASTERS  ----- 
##############################################################
library(sf)

stations <- st_read(
  "//ad.helsinki.fi/home/t/terschan/Desktop/paper1/data/stations_training.gpkg",
  quiet = TRUE
)

st_crs(stations)   # sanity check

# load and align all static rasters
static_files <- list.files(static, pattern = "\\.tif$", full.names = TRUE)
static_r <- rast(static_files)
# load all sensor locations as tables

##############################################################
# ----- + ERA5 HANDLING OF DYNAMIC PREDICTORS  ----- 
##############################################################


##############################################################
# ----- + EXTRACT ALL OTHER STATIC PREDICTORS FROM LOCATIONS
##############################################################
# extract static predictors to sensor locations and create train data table
