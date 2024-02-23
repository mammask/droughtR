#' plot.droughtclass
#'
#' Plots spi or nspi index of a data.table input with class drought
#'
#' @param x data.table of class droughtclass
#' @param label logical
#' @param log logical
#' @param ... some arguments
#' @param type character
#' @importFrom graphics plot
#' @import data.table ggplot2
#' @return ggplot2
#' @importFrom ggplot2 geom_bar theme_light geom_hline ylab
#' @examples mIndex = computenspi(x = dummyrainfall(1950, 2000),
#'                 stationary = TRUE,
#'                 spiScale = 12,
#'                 dist = 'gamma')
#'
#'                 indexClass = computeclass(mIndex)
#' plot(indexClass)
#' @export

plot.droughtclass = function(x, label=TRUE, log=TRUE, type = "droughtclass", ...){

  if (base::inherits(x, "droughtclass", which = FALSE) == FALSE){
    stop("object class is not 'droughtclass'")
  }

  if ("SPI" %in% names(x)){
    droughtindex = "SPI"
  } else {
    droughtindex = "NSPI"
  }

  droughtsummary = copy(x[complete.cases(x), .N, by = .(Year = data.table::year(Date), `Drought Class`)])
  droughtsummary[, `Drought Class` := factor(`Drought Class`, levels = c("Extremely Wet",
                                                                         "Very Wet",
                                                                         "Moderately Wet",
                                                                         "Near Normal",
                                                                         "Moderately Dry",
                                                                         "Very Dry",
                                                                         "Extremely Dry"
  ))]

  ggplot(data = droughtsummary, aes(x = Year, y = N, fill = `Drought Class`)) + geom_col(color = "black") +
    scale_fill_brewer(palette = 1, direction = -1) +
    theme_light() + xlab("Year") + ylab("Number of Drought Events") +
    geom_text(aes(x = Year, y = N, label = N), size = 3, position = position_stack(vjust = 0.5))

}
