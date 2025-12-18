import xarray as xr
import pandas as pd
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt # plotting
import numpy as np # plotting
from scipy.stats import pearsonr # correlation

#############################################################
######### #1 MERGE STATION DATA AND METADATA ################
#############################################################
# first we combine the weather station observations with the metadata file

# weather station dir and metadata
STATION_DIR = Path(
    r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\weatherstations\kaisaniemi"
)
meta = pd.read_csv(r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\weatherstations\station_metadata_2.txt", 
                   sep="\t", engine="python")
# rename metadata files to english (sorry finnbros)
meta = meta.rename(columns={
    "Nimi": "station_name",
    "FMISID": "station_id",
    "Lat": "lat",
    "Lon": "lon",
    "Korkeus": "elevation"
})
# filtersort
meta = meta[["station_id", "station_name", "lat", "lon", "elevation"]]
# list station files
files = list(STATION_DIR.glob("*.csv"))
# what the fuck is this
def normalize_columns(df):
    rename_map = {}

    for col in df.columns:
        c = col.lower()

        if "average temperature" in c:
            rename_map[col] = "t2m_avg"
        elif "minimum temperature" in c:
            rename_map[col] = "t2m_min"
        elif "maximum temperature" in c:
            rename_map[col] = "t2m_max"
        elif "wind speed" in c:
            rename_map[col] = "wind_speed"
        elif "precipitation" in c:
            rename_map[col] = "precip"

    return df.rename(columns=rename_map)
# load individual station csv
def load_station_csv(path):
    df = pd.read_csv(path)
    station_name = df["Observation station"].iloc[0]
    match = meta.loc[meta["station_name"] == station_name]
    if match.empty:
        raise ValueError(f"No match found: {station_name}")
    row = match.iloc[0]
    station_id = row["station_id"]
    station_name = row["station_name"]
    lat = row["lat"]
    lon = row["lon"]
    elevation = row["elevation"]

    # time
    df["time"] = pd.to_datetime(
        df["Year"].astype(str) + "-" +
        df["Month"].astype(str).str.zfill(2) + "-" +
        df["Day"].astype(str).str.zfill(2) + " " +
        df["Time [UTC]"].astype(str),
        utc=True,
        errors="coerce"
    )

    df = normalize_columns(df)
    df = df[
        ["time", "t2m_avg", "t2m_min", "t2m_max", "wind_speed", "precip"]
    ]

    # attach metadata
    df["station_id"] = station_id
    df["station_name"] = station_name
    df["lat"] = lat
    df["lon"] = lon
    df["elevation"] = elevation

    return df

# loop through files and load/append
station_dfs = []

for path in files:
    df = load_station_csv(path)
    station_dfs.append(df)

stations = pd.concat(station_dfs, ignore_index=True) # combine all stations
stations.columns # check columns

# mask out non summer data, we only want summer 24/25
mask = (
    (
        (stations["time"] >= "2024-05-01") &
        (stations["time"] <= "2024-09-30 23:59")
    )
    |
    (
        (stations["time"] >= "2025-05-01") &
        (stations["time"] <= "2025-09-30 23:59")
    )
)

stations = stations.loc[mask].copy()

#############################################
##### #2 ERA TILE - STATION ATTRIBUTION #####
#############################################
# we use the combined station files to nearest neighbor match ERA5-land gridpoints with stations
path = r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\ERA\combined\ERA_SUMMER_24_25_HEL.netcdf"
era = xr.open_dataset(path)
#era

# timezone neutral, might be superfluous
stations["time"] = stations["time"].dt.tz_convert("UTC").dt.tz_localize(None)
# rename time column
era = era.rename({"valid_time": "time"})

# unique stations
station_meta = (
    stations[["station_id", "lat", "lon"]]
    .drop_duplicates()
    .set_index("station_id")
)

# find nearest grid point
nearest_points = {
    sid: era.sel(
        latitude=meta.lat,
        longitude=meta.lon,
        method="nearest"
    )
    for sid, meta in station_meta.iterrows()
}

#for sid, ds in nearest_points.items():
#    print(
#        sid,
#        float(ds.latitude.values),
#        float(ds.longitude.values)
#    )

era_vars = ["t2m", "tp", "wind_s", "ssrd"]
era_dfs = []

# turning xarray into df
for sid, ds in nearest_points.items():
    df = (
        ds[era_vars]
        .to_dataframe()
        .reset_index()
        .assign(station_id=sid)
    )
    era_dfs.append(df)

era_df = pd.concat(era_dfs, ignore_index=True)


stations_merged = stations.merge(
    era_df,
    on=["station_id", "time"],
    how="left"
)

stations_merged["t2m_era_c"] = stations_merged["t2m"] - 273.15
stations_merged["tp_era_mm"] = stations_merged["tp"] * 1000
stations_merged["ssrd_era_wm2"] = stations_merged["ssrd"] / 3600

stations_merged[[
    "time",
    "t2m_avg",
    "t2m_era_c",
    "wind_speed",
    "wind_s"
]].head()


#################################
######### #3 PLOTTING ###########
#################################
df = stations_merged.copy() # lets not work on the OG lol

# adjusted r squared and RMSE for figure
cols = ["t2m_avg", "t2m_era_c"]
df_hex = df[cols].apply(pd.to_numeric, errors="coerce").dropna()
x = df_hex["t2m_avg"].values
y = df_hex["t2m_era_c"].values
n = len(x)
p = 1  # number of predictors (simple linear comparison)
# correlation and R²
r, _ = pearsonr(x, y)
r2 = r**2
# cdjusted R²
adj_r2 = 1 - (1 - r2) * (n - 1) / (n - p - 1)
# rMSE
rmse = np.sqrt(np.mean((y - x) ** 2))

fig, ax = plt.subplots(figsize=(6, 6))
# background grid
ax.grid(
    True,
    linestyle="--",
    linewidth=0.5,
    alpha=0.3,
    zorder=0
)
# hexbin
hb = ax.hexbin(
    df_hex["t2m_avg"],
    df_hex["t2m_era_c"],
    gridsize=50,
    bins="log",
    mincnt=1,
    cmap="viridis",
    zorder=2
)
# ref line
lims = [
    min(df_hex.min()),
    max(df_hex.max())
]
ax.plot(lims, lims, color="black", linewidth=1.2, zorder=3)
# label & titles
ax.set_xlabel("Field observations (°C)", fontweight="bold")
ax.set_ylabel("ERA5-Land (°C)", fontweight="bold")
ax.set_title("Hourly mean 2 m air temperature")
cb = fig.colorbar(hb, ax=ax) # colorbar
cb.set_label("log10(n)") # legend label
ax.text(
    0.05, 0.95,
    f"Adjusted $R^2$ = {adj_r2:.3f}\nRMSE = {rmse:.2f} °C",
    transform=ax.transAxes,
    verticalalignment="top",
    bbox=dict(boxstyle="round", facecolor="white", alpha=0.8)
) # metrics box

plt.tight_layout()
plt.savefig(
    r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\figures\supplementary\era5_hourly_mean_temp.png",
    dpi=300,
    bbox_inches="tight"
)
plt.show()

##### ERA 5 BIAS VS TEMPERATURE DEPENDENCY #####
df_bias = df.copy()

# force numeric and calculate bias
df_bias["t2m_avg"] = pd.to_numeric(df_bias["t2m_avg"], errors="coerce")
df_bias["t2m_era_c"] = pd.to_numeric(df_bias["t2m_era_c"], errors="coerce")
df_bias = df_bias.dropna()
df_bias["temp_bias"] = df_bias["t2m_era_c"] - df_bias["t2m_avg"]

plt.figure(figsize=(6, 4))
plt.hexbin(
    df_bias["t2m_avg"],
    df_bias["temp_bias"],
    gridsize=40,
    bins="log",
    cmap="viridis",
    mincnt=1
)
plt.axhline(0, color="black", linewidth=1)
plt.xlabel("Field observations (°C)", fontweight="bold")
plt.ylabel("ERA5-Land temperature bias (°C)", fontweight="bold")
plt.title("Temperature dependant bias")
cb = plt.colorbar()
cb.set_label("log10(n)")

plt.tight_layout()
plt.savefig(
    r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\figures\supplementary\era5_hourly_bias.png",
    dpi=300,
    bbox_inches="tight"
)
plt.show()

# SUPERFLUOUS: DAILY MEAN COMPARISON 
# this is vibecoded, basically just to see daily means and have backup. 
df_daybias = df.copy()
df_daily = (
    df.assign(time=pd.to_datetime(df["time"]))
      .set_index("time")[["t2m_avg", "t2m_era_c"]]
      .apply(pd.to_numeric, errors="coerce")
      .dropna()
      .resample("D")
      .mean()
      .dropna()
)
from scipy.stats import pearsonr
import numpy as np

x = df_daily["t2m_avg"].values
y = df_daily["t2m_era_c"].values

n = len(x)
p = 1

r, _ = pearsonr(x, y)
r2 = r**2
adj_r2 = 1 - (1 - r2) * (n - 1) / (n - p - 1)
rmse = np.sqrt(np.mean((y - x) ** 2))
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(6, 6))

# Light background grid
ax.grid(
    True,
    linestyle="--",
    linewidth=0.5,
    alpha=0.3,
    zorder=0
)

# Hexbin
hb = ax.hexbin(
    df_daily["t2m_avg"],
    df_daily["t2m_era_c"],
    gridsize=35,          # slightly lower for daily
    bins="log",
    mincnt=1,
    cmap="viridis",
    zorder=2
)

# 1:1 line
lims = [
    min(df_daily.min()),
    max(df_daily.max())
]
ax.plot(lims, lims, color="black", linewidth=1.2, zorder=3)

# Labels
ax.set_xlabel("FMI weather station (°C)")
ax.set_ylabel("ERA5-Land (°C)")
ax.set_title("Daily mean 2 m air temperature")

# Colorbar
cb = fig.colorbar(hb, ax=ax)
cb.set_label("log10(n)")

# Metrics box
ax.text(
    0.05, 0.95,
    f"Adjusted $R^2$ = {adj_r2:.3f}\nRMSE = {rmse:.2f} °C",
    transform=ax.transAxes,
    va="top",
    bbox=dict(boxstyle="round", facecolor="white", alpha=0.8)
)

plt.tight_layout()
plt.show()
