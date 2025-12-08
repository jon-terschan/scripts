import xarray as xr

# import netcdf
era24 = xr.open_dataset(r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\ERA_SUMMER_24.netcdf")
era25 = xr.open_dataset(r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\ERA_SUMMER_25.netcdf")

# concat 24/25 data into one ds and export
era_c = xr.concat([era24, era25], dim="valid_time")
era_c.to_netcdf(r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\ERA_SUMMER_24_25_HEL.netcdf")

# crop CERRA data to same area as ERA5
ds_cerra = xr.open_dataset(r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\CERRA_SUMMER_24_25.netcdf")
cerra_crop = ds_cerra.where(
    (ds_cerra.latitude <= 60.30) &
    (ds_cerra.latitude >= 60.05) &
    (ds_cerra.longitude >= 24.70) &
    (ds_cerra.longitude <= 25.28),
    drop=True
)
cerra_crop.to_netcdf(r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\CERRA_SUMMER_24_25_HEL.netcdf")