# HELMIMOD - A predictive machine-learning model of Summer near-ground temperatures in Helsinki parks and urban forests.

A short summary of the model, performance metrics and limitations.

# HPC
High-performance computing (HPC) was used to (pre-)process airborne laser scanning tiles and train/test the model. Airborne Lidar data is commonly distributed in hundreds of tiles, making it suitable for (almost) embarassingly parallel HPC processing. We used CSC's Puhti supercomputer and acknowledge the computational resources contributed by CSC here. Unfortunately, Puhti reached the end of his lifecycle in early to mid 2026 which may affect reproducibility of the related scripts. Since the general SLURM/Lustre logic stays the same, it should be relatively straightforward to adapt the analyses to a different HPC system.

# STATIC VARIABLES
## AIRBORNE LASER SCANNING DERIVED VARIABLES 
### Downloading ALS files
Airborne lidar coverage of Helsinki is provided by the City of Helsinki. Unfortunately, the city's GUI for downloading open data (kartta.hel.fi) does not allow to download the data in bulk, creating the necessity to access the storage location directly. We retrieved the storage location using the developer view when creating a file request and used it to create a bulk downloader hel_lidar_tile_downloader. The downloader uses a file index hel_lidar_tiles.txt to request the data in a (hopefully) non-offensive way in bulk. The full download takes about 4-6 hours. Our file index was created by brute creating a faux index exploiting the coordinate-based naming convention of the tile (brute force) and filling the gaps manually.

### Preparing ALS files
Extensive preparation was necessary to minimize 
We removed all tiles without ground points, because they cannot be used to generate DTM (no points to triangulate from) and will just cause issues and overhead on the supercomputer. We relied on the City's preexisting classification of points for that. filter_tiles.R script creates a new index that only retains tiles with valid ground points and creates a output table for debugging with information. This reduced the amount of valid tiles from 1281 to (coincidentally) 1200.

We then used the new index to homogenize the files and assign the correct CRS (EPSG:3879) to the .laz header using LASTOOLS las2las.
las2las64 \ -i "$FILE" \ -o "$OUT_FILE" \ -set_point_type 6 \ -set_point_size 41 \ -epsg 3879 \ -olaz 
Homogenization prevents CRS mismatches and warning messages due to .las/.laz version conflicts.

Finally, we split the file index into 4 concurrent sub-indices (blocks), because the array size on Puhti's small partition is capped to a maximum of 1000 tasks. The reason for that is purely technical: In embarassingly parallel tasks that use file lists to index such as the one we used here, referential indexing via task number is no longer possible if the task maximum is exceeded. For instance, an array set to fulfill the tasks 900-1200 is not allowed on Puhti, despite the number of tasks being far below the threshold. To circumvent this, we split the index into four sub-indices and always create the same array (1-300%40).

### Stage 1: DTM, DSM, CHM, and normalized point clouds
### Stage 2: Canopy metrics
### Stage 3: SVF
SVF is a separate stage simply it because it relies on GRASS GIS r.skyview, instead of R. Here, a single merged CHM is expected as input.

## OTHER STATIC VARIABLES
Contains script to generate additional static predictors relevant to the model, mainly related to topography, water presence, and build-up matter. 

# DYNAMIC VARIABLES
## CLF CONVERSION
Scripts used to convert different native logger formats into a common logger format (CLF). Scripts available for SurveyTag and TOMST (TMS4, Thermologgers). CLF looks as follows: 

| datetime                  	| t1   	| t2   	| t3   	| SMC 	|
|---------------------------	|------	|------	|------	|-----	|
| 2024-03-01 00:00:00+00:00 	| 19.5 	| 21.1 	| 22.1 	| 500 	|
| 2024-03-01 00:15:00+00:00 	| 19.6 	| 21.2 	| 22.2 	| 505 	|
| 2024-03-01 00:30:00+00:00 	| 19.2 	| 20.8 	| 21.6 	| 508 	|

datetime is the timestamp in datetime format and UTC timezone. Conversion to UTC is necessary because TOMST loggers record in UTC. Note that is extremely important to keep track of your logger's local timezones, in order to (re)convert timezones.

t1 is soil temperature sensor (if present) in degrees Celsius.
t2 is surface temperature sensor reading (if present) in degrees Celsius
t3 is air temperature sensor reading in degrees Celsius.
SMC is soil moisture count if available. 

## QA

Scripts to conduct various pre-processing and quality assessment operations. 

### date_filter
Filters out data prior to the start of measurements. TOMST loggers always record and cannot be turned off, so they will produce heaps of unrelated signals. The date filter assumes a period of relative temperature stability as the loggers are stored in air conditioning (~21 deg room temperature). This means the date filter won't work correctly if the time series contains real signal from an earlier field campaign. 

Date filter is the script in which I figured out the logic. Loop script does the same in batch.

### big_QA 
Performs various preprocessing operations in batch and spits out a report that allows you to identify which files need special attention. QA is quite conservative, because I have not tested function behavior extensively on the available data. 

### Sledgehammer 
A script for manual quality improvements that still remain after the big_QA, basically the final cleanup. Has some functions to remove and interpolate data and other data curation functions, including a function to remove faulty soil temperature readings and flag out-of-soil (OOS) periods in the data.

Note that there is no functions to fill large gaps in time series. 

### Duplicate detector
Deprecated script to detect timestamp duplicates (faulty measurements). Used for diagnostics, but vibecoded and not refactored.  

### Outlier detection
Deprecated first attempt at writing an outlier detection. Works, but the fine tuning takes too much time and in the end I had to do so much manual data curation anyways, it was easier to just manually remove extreme outliers.  


# Acknowledgements
This publication builds on many excellent open-source software, packages and libraries. Many thanks to the authors and maintainers who make this work possible. ❤️
See [CREDITS.md](CREDITS.md) for details.