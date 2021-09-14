#' computenspi
#'
#' Computes the stationary and non-stationary version of the Standardized Precipitation Index.
#'  The non-stationary version uses GAMLSS and models the parameters of a Gamma distribution
#'  by incorporating the trend of accumulated precipitation.
#'
#' @param monthlyRainfall data.table
#' @param stationaryspi logical
#' @param spiScale numeric
#'
#' @import data.table SPEI
#' @importFrom utils sessionInfo
#' @importFrom data.table := .N
#' @rawNamespace import(gamlss, except = CV)
#' @importFrom gamlss.dist GA
#' @return data.table
#' @export
#'
#' @examples computenspi(monthlyRainfall = dummyrainfall(1950, 2000), stationaryspi = TRUE, spiScale = 12)
computenspi = function(monthlyRainfall, stationaryspi, spiScale){

  setDT(monthlyRainfall)
  monthlyRainfall[, Date := as.yearmon(Date)]

  if (class(stationaryspi) != "logical"){
    stop("stationarity should be of logical type")
  }

  if (class(spiScale) != "numeric"){
    stop("spiScale should be numeric")
  }

  if (!"data.table" %in% class(monthlyRainfall)){
    stop("monthlyRainfall is not a data.table")
  }

  if (!any(names(monthlyRainfall) %in% c("Date","Rainfall"))){
    stop("monthlyRainfall should consist of Date and Rainfall columns")
  }

  if (monthlyRainfall[,class(Date)] != "yearmon"){
    stop("Date should be in yearmon format")
  }

  if (stationaryspi == TRUE){

    mts = ts(data = monthlyRainfall[,Rainfall],
              start = monthlyRainfall[,min(Date)],
              frequency = 1)

    dIndex = SPEI::spi(data = mts,
                        scale = spiScale,
                        distribution = "Gamma",
                        fit = "max-lik"
                        )

    monthlyRainfall[, SPI := as.numeric(dIndex[['fitted']])][]

  } else {

    # Compute accumulated precipitation
    accumPrecip = base::rowSums(stats::embed(monthlyRainfall[, Rainfall],spiScale),na.rm=FALSE)
    # Add accumulated precipitation to the monthly rainfall data
    monthlyRainfall[, AccumPrecip := c(rep(NA, spiScale-1), accumPrecip)]
    # Compute the trend
    monthlyRainfall[stats::complete.cases(monthlyRainfall), Trend := 1:.N]
    # Fit GAMLSS model that varies in shape and scale
    model = gamlss::gamlss(formula = AccumPrecip ~ Trend,
                           sigma.formula = AccumPrecip ~ Trend,
                           data = monthlyRainfall[stats::complete.cases(monthlyRainfall)],
                           family = gamlss.dist::GA
    )
    # Obtain the response of GAMLSS
    pred = predictAll(model,
                      data = monthlyRainfall[stats::complete.cases(monthlyRainfall), .(AccumPrecip, Trend)],
                      type = 'response'
    )
    # Obtain the estimated mu
    monthlyRainfall[stats::complete.cases(monthlyRainfall), mu := pred$mu]
    # Obtain the estimated sigma
    monthlyRainfall[stats::complete.cases(monthlyRainfall), sigma := pred$sigma]
    # Obtain ecdf
    monthlyRainfall[stats::complete.cases(monthlyRainfall), ecdfm := gamlss.dist::pGA(AccumPrecip, mu = mu, sigma = sigma)]
    # Calculate NSPI
    monthlyRainfall[stats::complete.cases(monthlyRainfall), NSPI := qnorm(ecdfm)][]
  }

  class(monthlyRainfall) = c("drought", class(monthlyRainfall))

  return(monthlyRainfall)
}
