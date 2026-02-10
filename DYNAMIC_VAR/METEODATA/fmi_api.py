import fmiopendata as fmi
import datetime 
from fmiopendata.wfs import download_stored_query

### i honestly have no clue how this API works so this is just a placeholder for now ###

#end_time = dt.datetime.utcnow()
end_time = "09/30/2024 00:00:00"
end_time = datetime.datetime.strptime(end_time, "%m/%d/%Y %H:%M:%S")

start_time = "01/01/2024 00:00:00"
start_time = datetime.datetime.strptime(start_time, "%m/%d/%Y %H:%M:%S")
# Convert times to properly formatted strings
start_time = start_time.isoformat(timespec="seconds") + "Z"
# -> 2020-07-07T12:00:00Z
end_time = end_time.isoformat(timespec="seconds") + "Z"
# -> 2020-07-07T13:00:00Z

obs = download_stored_query("fmi::observations::weather::timevaluepair",
                            args=["bbox=24.70,60.02,25.30,60.30",
                                  "starttime=" + start_time,
                                  "endtime=" + end_time,
                                  "timestep=60"])