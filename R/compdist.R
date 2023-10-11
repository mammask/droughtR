#' compdist
#'
#' Compares drought indices fitted with different distributions
#'
#' @param x `data.table` with monthly rainfall data (Date | Rainfall)
#' @param mDist An character vector of one or more
#' @param stationaryspi logical used in *array* method (TRUE when stationary and FALSE when otherwise)
#' @param spiScale A positive integer value, typically ranging from 1 to 24
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
#' @return data.table
#' @export
#'
#' @examples compdist(x = dummyrainfall(1950, 2000),
#'          mDist = 'gamma',
#'          stationaryspi = TRUE,
#'          spiScale = 12
#'          )
compdist = function(x, mDist, stationaryspi, spiScale){

  if (!any(mDist %in% c("gamma","weibull","normal", "zigamma"))){
    stop("Incorrect array of distributions")
  }


  spiList = list()
  for (i in mDist){

    spiList[[i]] = copy(computenspi(x, stationaryspi, spiScale, i))
    spiList[[i]][, Distribution := i]
  }

  spiList = rbindlist(spiList)
  spiList = spiList[complete.cases(spiList)]
  spiList = spiList[order(Distribution, ecdfm)]
  spiList[, id := 1:.N, by = Distribution]

  x[, stats::ecdf(Rainfall)]

}
