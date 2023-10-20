#'computeclass
#'
#'Computes the drought class of a meteorological drought index
#'
#'@param object drought class object
#'@import data.table
#'@importFrom data.table := set
#'@return data.table
#'
#'@export
#'@examples rainfall = dummyrainfall(1950, 2000)
#' droughtindex = computenspi(x = dummyrainfall(1950, 2000),
#'                            stationaryspi = TRUE,
#'                            spiScale = 12,
#'                            dist = 'gamma'
#'                           )
#'computeclass(droughtindex)

computeclass = function(object){

  if (base::inherits(object, "drought", which = FALSE) == FALSE){
    stop("object class is not 'drought'")
  }

  indexVar = c(c("SPI", "NSPI"))[c("SPI", "NSPI") %in% names(object[['drought index']])]
  indexdata = data.table(Date = object[['drought index']][,Date])
  data.table::set(x = indexdata, j = indexVar, value = object[['drought index']][[indexVar]])

  # Compute Drought Class
  indexdata[, c("Drought Class") := lapply(.SD, droughtclass), .SDcols = indexVar, by = Date]
  classdata = copy(indexdata[, c("Date", indexVar, "Drought Class"), with = F])

  class(classdata) = c("droughtclass", class(classdata))

  return(classdata)
}
