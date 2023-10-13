#' measurebias
#'
#' Measures the amount of bias introduced to the training set due to incorrect computation of (N)SPI prior to out-of-sample validation
#'
#' @param x data.table with rainfall records (Date, Rainfall)
#' @param trainratio numeric; the proportion of the train set
#' @param validationratio numeric; the proportion of the validation set
#' @param testratio  numeric; the proportion of the test set
#' @param stationaryspi logical; When TRUE SPI is calculated; when FALSE NSPI is calculated
#' @param spiscale integer; the scale of accumulated precipitation
#' @param dist A character that can be either, "normal" when Normal distribution is used, "gamma" for Gamma, "zigamma" for zero adjusted Gamma and "weibull" for Weibull.
#' @import data.table ggplot2 gamlss.dist SPEI
#' @importFrom data.table := .N
#' @rawNamespace import(gamlss, except = CV)
#' @rawNamespace import(forecast, except = CV)
#' @return list
#' @export
#'
#' @examples rainfall = dummyrainfall(1950, 2000)
#' measurebias(rainfall, 0.6, 0.2, 0.2, TRUE, 12, "normal")
measurebias = function(x, trainratio, validationratio, testratio, stationaryspi, spiscale, dist = 'gamma'){

  setDT(x)

  # Perform data split
  x = oossplit(x, trainratio, validationratio, testratio)

  # Compute the index in the training set only
  biascorrindex = data.table::copy(computenspi(x[Split == 'Train'], stationaryspi, spiscale, dist)[["drought index"]])
  biascorrindex[, Status := "Bias Corrected"]

  # Compute the index in the trasining, validation and test sets
  biasedindex = data.table::copy(computenspi(x, stationaryspi, spiscale, dist)[["drought index"]])
  biasedindex[, Status := "Bias Induced"]

  if (stationaryspi == TRUE){
    indexVar = "SPI"
  } else {
    indexVar = "NSPI"
  }

  # Gather both drought index estimates
  comparison = data.table::rbindlist(list(biascorrindex, biasedindex))
  comparison = comparison[Split == 'Train']
  comparison = comparison[complete.cases(comparison)]
  comparison = data.table::dcast.data.table(data = comparison,
                                            formula = "Date + Rainfall + Split ~ Status",
                                            value.var = indexVar
  )

  # Compute drought classes
  comparison[, `Bias Corrected Class` := droughtclass(`Bias Corrected`),  by = 1:nrow(comparison)]
  comparison[, `Bias Induced Class` := droughtclass(`Bias Induced`),  by = 1:nrow(comparison)]

  # Compute drought class transitions
  transitions = data.table::copy(comparison[, .N, by = .(`Bias Corrected Class`,
                                                         `Bias Induced Class`)])

  # Compute number of records affected
  recimpact = transitions[`Bias Corrected Class` != `Bias Induced Class`, sum(N)]

  # % of records affected
  recimpactratio = round(100*recimpact/transitions[,sum(N)],2)

  # Generate plot with the two calculation methods
  p = ggplot(data = comparison) + geom_line(aes(x = Date, y = `Bias Corrected`, color = "Bias corrected")) +
    geom_line(aes(x = Date, y = `Bias Induced`, color = 'Bias induced')) +
    scale_color_manual(values=c("#CC6666", "#9999CC")) +
    labs(colour="Calculation method") + theme_light() + ylab("Drought index") +
    theme(legend.position="bottom")

  return(list(Transitions = transitions,
              `Impacted Records` = paste0(recimpactratio,"% of records changed drought class"),
              Plot = p
  ))
}
