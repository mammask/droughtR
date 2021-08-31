test_that("bcautoarimapred()", {

  x = dummyrainfall(startYear = 1940, 2010)
  model = bcautoarimapred(x, NULL, T, 12, 2)

  if (length(model) == 2){
    succeed()
  } else {
    fail("Model returns incorrect number of forecasts")
  }
})
