test_that("check data.table structure in computenspi", {
  expect_error(computenspi(x = list(), stationaryspi = TRUE, spiScale = 12, dist = 'gamma'),
               "x should be in data.table or data.frame format")
})
