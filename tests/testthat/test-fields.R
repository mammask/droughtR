test_that("check fields spi", {

  x = dummyrainfall(startYear = 1990, endYear = 2022)
  spi = computenspi(monthlyRainfall = x, stationaryspi = T, spiScale = 12, dist = 'gamma')

  expect_named(spi, c("Date","Rainfall","AccumPrecip", "Trend", "mu", "sigma", "ecdfm", "SPI"))

  })


test_that("check fields nspi", {

  x = dummyrainfall(startYear = 1990, endYear = 2022)
  nspi = computenspi(monthlyRainfall = x, stationaryspi = F, spiScale = 12, dist = 'gamma')

  expect_named(nspi, c("Date","Rainfall","AccumPrecip", "Trend", "mu", "sigma", "ecdfm", "NSPI"))

})
