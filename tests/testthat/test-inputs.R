test_that("check data.table structure in computenspi", {
  expect_error(computenspi(x = list(), stationaryspi = TRUE, spiScale = 12, dist = 'gamma'),
               "x should be in data.table or data.frame format")
})

test_that("check stationarity variable type", {
  expect_error(computenspi(x = dummyrainfall(startYear = 1950, endYear = 2020),
                           stationaryspi = "A", spiScale = 12, dist = 'gamma'),
               "stationarity should be of type logical")
})

test_that("check spi scale variable type", {
  expect_error(computenspi(x = dummyrainfall(startYear = 1950, endYear = 2020),
                           stationaryspi = T, spiScale = NA, dist = 'gamma'),
               "spiScale should be numeric")
})


test_that("check dist variable type", {
  expect_error(computenspi(x = dummyrainfall(startYear = 1950, endYear = 2020),
                           stationaryspi = T, spiScale = 12, dist = NA),
               "dist should be of type character")
})

test_that("check columns names of the input data", {

  monthlyrain = copy(dummyrainfall(startYear = 1950, endYear = 2020)[, .(x = Date)])
  expect_error(computenspi(x = monthlyrain, stationaryspi = T, spiScale = 12, dist = 'gamma'),
               "x should consist of a Date column")
})

test_that("check date format of the input data", {
  monthlyrain = copy(dummyrainfall(startYear = 1950, endYear = 2020)[, .(x = Date)])
  expect_error(computenspi(x = monthlyrain,
                           stationaryspi = T, spiScale = 12, dist = 'gamma'),
               "x should consist of a Date column")
})

test_that("check columns names of the input data", {

  monthlyrain = copy(dummyrainfall(startYear = 1950, endYear = 2020)[, .(Date, x = Rainfall)])
  expect_error(computenspi(x = monthlyrain, stationaryspi = T, spiScale = 12, dist = 'gamma'),
               "x should consist of a Rainfall column")
})


test_that("check distribution is in the list of supported distributions", {

  expect_error(computenspi(x = dummyrainfall(startYear = 1950, endYear = 2020),
                           stationaryspi = T, spiScale = 12, dist = 'unknown'),
               "Not supported distribution")
})

test_that("check inputs in generating synthetic rainfall data",{
  expect_error(dummyrainfall(startYear = NA, endYear = NA),
               "input is non-numeric argument"
               )
})

test_that("check startYear is earlier compared to endYear in generating synthetic rainfall data",{
  expect_error(dummyrainfall(startYear = 2023, endYear = 1980),
               "startYear should not be greater or equal to endYear"
  )
})


test_that("check the time period is not less than 30 years in generating synthetic rainfall data",{
  expect_error(dummyrainfall(startYear = 2000, endYear = 2010),
               "Please simulate data for at least 30 years"
  )
})

test_that("check object class in computeclass",{
  expect_error(computeclass(list()),
               "object class is not 'drought'"
  )
})

test_that("check data.table structure in measurebias", {
  expect_error(measurebias(x = list(), trainratio = 0.6, validationratio = 0.2, testratio = 0.2, stationaryspi = T, spiscale = 12, dist = 'gamma'),
               "x should be in data.table or data.frame format")
})


test_that("check data split ratio in measurebias",{
  expect_error(measurebias(x = dummyrainfall(1950, 2000),
                           trainratio = 1, validationratio = 0.2, testratio = 0.2, stationaryspi = T, spiscale = 12, dist = 'gamma'),
               "the sum of the data split should be equal to 1")
})


