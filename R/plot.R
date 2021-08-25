#' plot.drought
#'
#' Plots spi or nspi index of a data.table input with class drought
#'
#' @param x data.table of class drought
#' @param label logical
#' @param log logical
#' @param ... some arguments
#' @param type character
#' @importFrom graphics plot
#' @import data.table ggplot2
#' @return ggplot2
#' @importFrom ggplot2 geom_bar theme_light geom_hline ylab
#' @examples x = computenspi(monthlyRainfall = dummyrainfall(1950, 2000), stationary = TRUE, spiScale = 12)
#' plot(x)
#' @export
plot.drought = function(x,label=TRUE, log=TRUE, type = "drought", ...){

  if ("SPI" %in% names(x)){
    droughtindex = "SPI"
  } else {
    droughtindex = "NSPI"
  }

  setDT(x)

  ggplot2::ggplot(data = x[stats::complete.cases(x)]) +
    geom_bar(aes(x = Date, y = eval(parse(text = droughtindex))),
             position = "dodge",
             stat = "identity"
    ) +
    ylab(droughtindex) +
    theme_light() +
    geom_hline(yintercept = 2, color = 'green', linetype = 'dashed') +
    geom_hline(yintercept = -2, color = 'red', linetype = 'dashed')
}
