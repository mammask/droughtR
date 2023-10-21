test_that("test input object for plot.drought", {

  expect_error(plot.drought(list()),"object class is not 'drought'"
  )

})

test_that("test output object for plot.drought when generating nspi", {

  mIndex = computenspi(x = dummyrainfall(startYear = 1950, 2020), stationaryspi = TRUE, spiScale = 12, dist = 'gamma')
  mplot = plot(mIndex)

  if (any(class(mplot) == 'ggplot')){
    succeed()
  } else {
    fail('plot.drought does not return an object of class ggplot')
  }

})

test_that("test output object for plot.drought", {

  mIndex = computenspi(x = dummyrainfall(startYear = 1950, 2020), stationaryspi = FALSE, spiScale = 12, dist = 'gamma')
  mplot = plot(mIndex)

  if (any(class(mplot) == 'ggplot')){
    succeed()
  } else {
    fail('plot.drought does not return an object of class ggplot when generating spi')
  }

})


test_that("test input object for plot.droughtclass", {

  expect_error(plot.droughtclass(list()),"object class is not 'droughtclass'"
  )

})


test_that("test output object for plot.droughtclass when using nspi", {

  mIndex = computenspi(x = dummyrainfall(startYear = 1950, 2020), stationaryspi = FALSE, spiScale = 12, dist = 'gamma')
  mIndexclass = computeclass(mIndex)
  mplot = plot(mIndexclass)

  if (any(class(mplot) == 'ggplot')){
    succeed()
  } else {
    fail('plot.droughtclass does not return an object of class ggplot when generating nspi')
  }

})


test_that("test output object for plot.droughtclass when using spi", {

  mIndex = computenspi(x = dummyrainfall(startYear = 1950, 2020), stationaryspi = TRUE, spiScale = 12, dist = 'gamma')
  mIndexclass = computeclass(mIndex)
  mplot = plot(mIndexclass)

  if (any(class(mplot) == 'ggplot')){
    succeed()
  } else {
    fail('plot.droughtclass does not return an object of class ggplot when generating spi')
  }

})
