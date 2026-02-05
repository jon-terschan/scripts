library(lidR)

tiles <- readLines("tiles.txt")

has_ground <- logical(length(tiles))
n_ground   <- integer(length(tiles))

for (i in seq_along(tiles)) {
  f <- tiles[i]
  cat(sprintf("[%d/%d] %s\n", i, length(tiles), basename(f)))

  las <- try(readLAS(f, select = "c"), silent = TRUE)

  if (!inherits(las, "try-error") && !is.empty(las)) {
    n <- sum(las@data$Classification == 2)
    has_ground[i] <- n > 0
    n_ground[i]   <- n
  } else {
    has_ground[i] <- FALSE
    n_ground[i]   <- 0
  }

  rm(las)
}

writeLines(tiles[has_ground], "tiles_with_ground.txt")
write.csv(
  data.frame(
    tile = tiles,
    has_ground = has_ground,
    n_ground = n_ground
  ),
  "tiles_ground_report.csv",
  row.names = FALSE
)
