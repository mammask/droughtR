test_that("check missing gamma", {

  # Generate synthetic rainfall
  rainfall = dummyrainfall(1950, 2000)

  # Compute drought index
  droughtindex = computenspi(x = rainfall, stationaryspi = FALSE, spiScale = 12, dist = 'gamma')

  # Compute drought classes
  droughtevents = computeclass(droughtindex)

  # Check whether the input and output data have the same length
  if (nrow(droughtindex$`drought index`) == nrow(droughtevents)){
    succeed()
  } else {
    fail("inconsistent number of drought events with the input data")
  }

})
