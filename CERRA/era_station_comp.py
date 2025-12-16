import xarray as xr
import pandas as pd
from pathlib import Path

STATION_DIR = Path(
    r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\weatherstations\kaisaniemi"
)
meta = pd.read_csv(r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\weatherstations\station_metadata_2.txt", 
                   sep="\t", engine="python")

# rename metadata files to english
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
        raise ValueError(f"No metadata match for station: {station_name}")

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

# AT THIS POINT I MERGED STATIONS AND METADATA, NEXT STEP IS ERA MATCHING AND MERGING
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

stations_may_sep = stations.loc[mask].copy()
stations_may_sep.head()

###########################
##### ERA DATA MERGER #####
###########################
import numpy as np

path = r"\\ad.helsinki.fi\home\t\terschan\Desktop\paper1\data\11.25\ERA\combined\ERA_SUMMER_24_25_HEL.netcdf"
era = xr.open_dataset(path)
era["wind_speed"] = np.sqrt(era["u10"]**2 + era["v10"]**2)


stations_meta = (
    stations_may_sep[
        ["station_id", "station_name", "lat", "lon", "elevation"]
    ]
    .drop_duplicates()
    .reset_index(drop=True)
)

stations_xr = xr.Dataset(
    {
        "station_id": ("station", stations_meta["station_id"].values),
        "lat": ("station", stations_meta["lat"].values),
        "lon": ("station", stations_meta["lon"].values),
    }
)

era5_at_stations = era.sel(
    latitude=stations_xr["lat"],
    longitude=stations_xr["lon"],
    method="nearest"
)
era5_at_stations