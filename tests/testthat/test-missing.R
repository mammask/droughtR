test_that("check missing", {

  # Check whether the number of missing and the length of the records
  lengthRecordsSPI  = c()
  lengthRecordsNSPI  = c()

  for (i in 1: 100){

    print(paste0("Iteration: ",i))

    # Generate synthetic rainfall using the Gamma distribution with random parameters
    randomShape = sample(x = seq(from = 0.01, to = 10, by = 0.01), size = 1, replace = T)
    randomScale = sample(x = seq(from = 0.01, to = 10, by = 0.01), size = 1, replace = T)
    x = stats::rgamma(n = 1000, shape = randomShape, scale = randomScale)

    # Define synthetic date
    numYear = ceiling(length(x)/12)
    endYear = as.numeric(format(base::Sys.Date(), "%Y"))
    endMonth = length(x) %% 12
    endDate = as.Date(paste0(endYear,"-",endMonth,"-01"), format = "%Y-%m-%d")

    startYear = endYear - numYear + 1
    startMonth = 01
    startDate = as.Date(paste0(startYear,"-",startMonth,"-01"), format = "%Y-%m-%d")

    dateSeq = base::seq.Date(from = startDate, to = endDate, by = "month")
    monthlyRainfall = data.table::data.table(Date = dateSeq, Rainfall = x)

    # Compute NSPI
    nspi = copy(computenspi(monthlyRainfall, F, 12, 'gamma'))
    lengthRecordsNSPI = c(lengthRecordsSPI, nspi[!is.na(NSPI), .N] == length(x)-12+1)

    # Compute SPI
    spi  = copy(computenspi(monthlyRainfall, T, 12, 'gamma'))
    lengthRecordsSPI = c(lengthRecordsSPI, spi[!is.na(SPI), .N] == length(x)-12+1)

    rm(monthlyRainfall)
  }
  if (sum(lengthRecordsNSPI) == 100 & sum(lengthRecordsSPI) == 100){
    succeed()
  } else {
    fail("Unexpected length of drought index series")
  }
})
