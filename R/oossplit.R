#' oossplit
#'
#' Out-of-sample split: Splits a data.table of class drought into train validation and test sets by preserving chronological order
#'
#' @param x data.table
#' @param trainratio numeric
#' @param validationratio numeric
#' @param testratio numeric
#' @import data.table
#' @importFrom utils sessionInfo
#' @importFrom data.table := .N set
#' @return data.table
#' @export
#'
#' @examples rainfall = dummyrainfall(1950, 2000)
#' rainfall = oossplit(x = rainfall, trainratio = 0.6, validationratio = 0.2, testratio = 0.2)
oossplit = function(x, trainratio, validationratio, testratio){

  if ((trainratio+validationratio+testratio) != 1){
    stop("The dataset split ratio should add up to 1")
  }

  setDT(x)

  trainsize = round(trainratio * x[complete.cases(x),.N])
  validsize = round(validationratio * x[complete.cases(x),.N])
  testsize  = round(testratio * x[complete.cases(x),.N])

  status = rep(NA, times = x[complete.cases(x),.N])

  status[1:trainsize] = "Train"
  status[(trainsize+1):(trainsize+validsize)] = "Validation"
  status[(trainsize+validsize+1):length(status)] = "Test"

  fillnas = copy(x[!complete.cases(x),.N])
  x[["Split"]] = c(rep(NA, times = fillnas), status)
  return(x[])
}
