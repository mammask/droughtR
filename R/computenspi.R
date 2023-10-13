#' computenspi
#'
#' Computes the stationary and non-stationary version of the Standardized Precipitation Index.
#'  The non-stationary version uses GAMLSS and models the parameters of a Gamma distribution
#'  by incorporating the trend of accumulated precipitation.
#'
#' @param x data.table
#' @param stationaryspi logical used in *array* method (TRUE when stationary and FALSE when otherwise)
#' @param spiScale A positive integer value, typically ranging from 1 to 24
#' @param dist A character that can be either, "normal" when Normal distribution is used, "gamma" for Gamma, "zigamma" for zero adjusted Gamma and "weibull" for Weibull.
#'
#' @import data.table SPEI
#' @importFrom utils sessionInfo
#' @importFrom data.table := .N
#' @rawNamespace import(gamlss, except = CV)
#' @importFrom gamlss.dist GA
#' @importFrom gamlss.dist ZAGA
#' @importFrom gamlss.dist NO
#' @importFrom gamlss.dist WEI
#' @importFrom stats as.formula
#' @include dummyrainfall.R
#' @return data.table
#' @export
#'
#' @examples
#' computenspi(x = dummyrainfall(1950, 2000),
#'             stationaryspi = TRUE,
#'             spiScale = 12,
#'             dist = 'gamma'
#'             )
computenspi = function(x, stationaryspi, spiScale, dist='gamma'){
  setDT(x)
  monthlyRainfall = copy(x)
  monthlyRainfall[, Date := as.yearmon(Date)]
  mIndex = list()

  if (base::inherits(stationaryspi, "logical", which = FALSE) == FALSE){
    stop("stationarity should be of type logical")
  }

  if (base::inherits(spiScale, "numeric", which = FALSE) == FALSE){
    stop("spiScale should be numeric")
  }

  if (base::inherits(monthlyRainfall, "data.table", which = FALSE) == FALSE){
    stop("monthlyRainfall is not a data.table")
  }

  if (base::inherits(dist, "character", which = FALSE) == FALSE){
    stop("dist should be of type character")
  }

  if (!any(names(monthlyRainfall) %in% c("Date","Rainfall"))){
    stop("monthlyRainfall should consist of Date and Rainfall columns")
  }

  if (base::inherits(monthlyRainfall[,Date], "yearmon", which = FALSE) == FALSE){
    stop("Date should be in yearmon format")
  }

  # Define family distribution
  if (dist == 'gamma') {

    familyDist = gamlss.dist::GA
    pfamilyDist = gamlss.dist::pGA

  } else if (dist == 'zigamma'){

    familyDist = gamlss.dist::ZAGA
    pfamilyDist = gamlss.dist::pZAGA

  } else if (dist == 'normal'){

    familyDist = gamlss.dist::NO
    pfamilyDist = gamlss.dist::pNO

  } else if (dist == 'weibull'){

    familyDist = gamlss.dist::WEI
    pfamilyDist = gamlss.dist::pWEI

  }

  # Compute accumulated precipitation
  accumPrecip = base::rowSums(stats::embed(monthlyRainfall[, Rainfall],spiScale),na.rm=FALSE)
  # Add accumulated precipitation to the monthly rainfall data
  monthlyRainfall[, AccumPrecip := c(rep(NA, spiScale-1), accumPrecip)]
  # Compute the trend
  monthlyRainfall[stats::complete.cases(monthlyRainfall), Trend := 1:.N]

  # Define the model formula
  modelFormula = ifelse(stationaryspi,  "AccumPrecip ~ 1", "AccumPrecip ~ Trend")

  # Fit GAMLSS model that varies in shape and scale
  model = gamlss::gamlss(formula = AccumPrecip ~ Trend,
                         sigma.formula = as.formula(modelFormula),
                         data = monthlyRainfall[stats::complete.cases(monthlyRainfall)],
                         family = familyDist
  )

  # Obtain the response of GAMLSS
  pred = predictAll(model,
                    data = monthlyRainfall[stats::complete.cases(monthlyRainfall), c("AccumPrecip", "Trend"), with = F],
                    type = 'response'
  )
  # Obtain the estimated mu
  monthlyRainfall[stats::complete.cases(monthlyRainfall), mu := pred$mu]
  # Obtain the estimated sigma
  monthlyRainfall[stats::complete.cases(monthlyRainfall), sigma := pred$sigma]
  # Obtain ecdf
  monthlyRainfall[stats::complete.cases(monthlyRainfall), ecdfm := pfamilyDist(AccumPrecip, mu = mu, sigma = sigma)]
  # Calculate NSPI
  monthlyRainfall[stats::complete.cases(monthlyRainfall), c(ifelse(stationaryspi, "SPI", "NSPI")) := qnorm(ecdfm)][]

  mIndex[['model']] = model
  mIndex[['drought index']] = monthlyRainfall

  class(mIndex) = c("drought", class(mIndex))

  return(mIndex)
}
