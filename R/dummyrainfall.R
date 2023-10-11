#' Generate synthetic monthly rainfall data
#'
#' Create a data.table with synthetic rainfall data generated from a Gamma distribution
#'
#' @param startYear A numeric positive integer indicating the start year (e.g., 1950)
#' @param endYear A numeric numeric positive integer indicating the end year (e.g., 2021)
#'
#' @return data.table
#' @import data.table zoo
#' @importFrom utils sessionInfo
#' @importFrom stats complete.cases qnorm sigma ts
#' @importFrom data.table :=
#' @export
#'
#' @examples
#' dummyrainfall(1950, 2021)
dummyrainfall = function(startYear, endYear){

  if (class(startYear) != "numeric" | class(endYear) != "numeric"){
    stop("input iload_all(s non-numeric argument")
  }

  start <- zoo::as.yearmon(base::as.Date(paste0("01-01-",startYear), "%d-%m-%Y"))
  end <- zoo::as.yearmon(base::as.Date(paste0("01-12-",endYear), "%d-%m-%Y"))

  if (class(start) != "yearmon" | class(end) != "yearmon"){
    stop("Please use objects of class Date")
  }
  if (startYear >= endYear){
    stop("startYear should not be greater or equal to endYear")
  }

  if ((endYear - startYear) < 30){
    warning("Please simulate data for at least 30 years")
  }

  monthlyRainfall <- data.table::data.table(Date = seq(from = start, to = end, by = 0.1))
  monthlyRainfall[, Rainfall := stats::rgamma(n = .N, 40, 5)][]
}
