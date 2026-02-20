# pred single time point 
library(terra)

static_stack <- rast("//ad.helsinki.fi/home/t/terschan/Desktop/paper1/scripts/DATA/predictorstack/full_stack/pred_stack_10m.tif")
rf_final <- readRDS("//ad.helsinki.fi/home/t/terschan/Desktop/paper1/scripts/DATA/03_model/01_helmi_2000_LAGGED.rds"))
era5 <- rast("era5_temperature.nc")
time(era5)

target_time <- as.POSIXct("2024-07-15 16:00:00", tz = "UTC")
idx <- which(time(era5) == target_time)
era5_slice <- era5[[idx]]
era5_crop <- crop(era5_slice, static_stack)

era5_resampled <- resample(
  era5_crop,
  static_stack,
  method = "bilinear"
)
names(era5_resampled) <- "era5_temp"  # must match training name

pred_stack <- c(static_stack, era5_resampled)

pred_raster <- terra::predict(
  pred_stack,
  rf_final,
  na.rm = FALSE
)

writeRaster(pred_raster, "prediction_2024-07-15_16.tif", overwrite = TRUE)