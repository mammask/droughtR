test_that("check fields spi", {

  spi = computenspi(x = dummyrainfall(startYear = 1990, endYear = 2022), stationaryspi = T, spiScale = 12, dist = 'gamma')[['drought index']]

  expect_named(spi, c("Date","Rainfall","AccumPrecip", "Trend", "mu", "sigma", "ecdfm", "SPI"))

  })


test_that("check fields nspi", {

  nspi = computenspi(x = dummyrainfall(startYear = 1990, endYear = 2022), stationaryspi = F, spiScale = 12, dist = 'gamma')[["drought index"]]

  expect_named(nspi, c("Date","Rainfall","AccumPrecip", "Trend", "mu", "sigma", "ecdfm", "NSPI"))

})
