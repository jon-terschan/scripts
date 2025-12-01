# CLF CONVERSION
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

# QA

Scripts to conduct various pre-processing and quality assessment operations. 

## date_filter
Filters out data from the beginning of measurements. This is necessary because TOMST loggers always record and cannot be turned off. Note that the scripts assumes a period of temperature stability in air conditioning (21 degrees room temperatures). Thus, it won't work correctly if a prior field campaign is still part of the time series. Date filter is where I figured out the logic, the loop script just does the same for many files.

## big_QA 
Performs various preprocessing operations in batch and then spits out a hopefully helpful report that allows you to identify which files need special attention. 

## Sledgehammer 
For manual quality improvements that need to be done after the big_QA, basically the final cleanup. Has some functions to remove and interpolate data and other data curation functions. 

## Duplicate detector
Some vibecoded stuff I used to check for duplicates, but later became deprecated. 

## Outlier detection
My first attempt at writing an outlier detection. Deprecated, because the fine tuning took too much time and in the end I had to do this manually anyways. 