###########################################################
####### DEPRECATED SINCE BACKEND LOCATION MOVED ###########
###########################################################

# Download laserscanning data from Helsinki Map Service at:
# https://kartta.hel.fi/?setlanguage=en


# Read filenames from file (2021)
# Make list based on the file names in paths below
#fn <- read.csv("C:/Users/terschan/Downloads/helsinki_lidar/tiles_2021.txt")
#fn <- unlist(fn, use.names=FALSE)

# Download files!
# TryCatch is needed as some files do not exist
#path <- "https://kartta.hel.fi/helshares/Laserkeilausaineistot/Pintamalli/2017_LAZ/"
#path <- "https://kartta.hel.fi/helshares/Laserkeilausaineistot/Pintamalli/2015_LAZ/"
#path <- "https://kartta.hel.fi/helshares/Laserkeilausaineistot/Pintamalli/2021_LAZ/"
#path <- "https://kartta.hel.fi/link/aw4R8i"

#for(file in fn) {
#  url    <- paste0(path, file)
  #output <- paste0("/scratch/project_2002648/helsinki_2015/", file) #remember "/" in the end of path!
  #output <- paste0("/scratch/project_2002648/helsinki_2017/west/", file)
#  output <- paste0("C:/Users/terschan/Downloads/helsinki_lidar/tiles/", file)
#  tryCatch(
#    download.file(url, destfile=output, mode="wb"),
#    error = function(e) print(paste(file, 'did not work out')))
#}


# If you had to stop downloading, update 'fn' to continue
#fn.done <- list.files("E:/Helsinki_lidar/2021/")
#fn <- setdiff(fn, fn.done)
# Continue by running the previous for-loop.

###########################################################
########################## NEW BACKEND ####################
###########################################################
fn <- readLines("C:/Users/terschan/Downloads/helsinki_lidar/tiles_2021.txt")
fn <- readLines("tiles_2021.txt")

# city of helsinki sneakily changed the endpoint where the files are without documentation
# but the new endpoint can be reverse engineered from the client-request 
# new thing uses this format:
# https://ptp.hel.fi/DataHandlers/Lidar_kaikki/Default.ashx?q=676495c&y=2021
# q = file id (coordinate + abcd, y = year)
fn <- gsub("^rgb_|\\.laz$", "", fn) # trim strings to correct length

# new download hander base
path <- "https://ptp.hel.fi/DataHandlers/Lidar_kaikki/Default.ashx"

for (tile in fn) {
  url <- paste0(path, "?q=", tile, "&y=2021")
  output <- paste0(
    "C:/Users/terschan/Downloads/helsinki_lidar/tiles/", # change to output folder
    tile,
    ".laz"
  )
  
  tryCatch(
    download.file(
      url,
      destfile = output,
      mode = "wb",
      method = "libcurl"
    ),
    error = function(e) message(tile, " did not work out")
  )
  Sys.sleep(0.1) # artificial lag to prevent ddosing helsinki server hihihi, probably superfluyous :)
}