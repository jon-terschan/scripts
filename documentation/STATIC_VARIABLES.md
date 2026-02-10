# OTHER STATIC VARIABLES
We created many scripts generating additional static predictors for the model related to topography, water presence and built-up matter. Some examples include:

* Elevation, slope, slopeaspect (Eastness/Southness), and ruggedness
* Water presence, distance to oceans/inland water bodies
* Building presence, height, and distance from buildings
* Presence of other impervious surfaces (concrete roads and sealed surfaces)
* Rocky outcrop presence 

The topographic features derived from the 2021 [City of Helsinki digital elevation model](https://hri.fi/data/en_GB/dataset/helsingin-korkeusmalli). Water, building, and other rasters are derived from the 2024 [Helsinki region land cover data set](https://www.hsy.fi/en/environmental-information/open-data/avoin-data---sivut/helsinki-region-land-cover-dataset/). These are simple data preparation steps, that do not warrant long documentation. Most involve rasterization to the same 1 m grid template and then upscaling to the 10 m prediction grid.  

Building height is a separate script, because it requires the merged CHM to be masked by a building mask.